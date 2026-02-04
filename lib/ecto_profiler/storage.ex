defmodule EctoProfiler.Storage do
  @moduledoc """
  ETS-backed storage for request and query data.

  Request metadata (started_at, ended_at) is stored in a `:set` table keyed by
  request_id. Queries are stored in a separate `:bag` table keyed by request_id,
  so concurrent appends from multiple processes are safe (no read-modify-write).
  Also provides normalized SQL for grouping query shapes (e.g. for N+1 detection).
  """

  @table_name :ecto_profiler_requests
  @queries_table_name :ecto_profiler_queries

  @doc """
  Ensures the ETS tables exist. Idempotent. Call from the process that should
  own the tables (e.g. Application.start or a supervisor child).

  - `:ecto_profiler_requests` is `:set`, `:public`, keyed by request_id.
  - `:ecto_profiler_queries` is `:bag`, `:public`, keyed by request_id (one row per query).
  """
  @spec ensure_table() :: :ok | {:error, term()}
  def ensure_table do
    with :ok <- ensure_table(@table_name, [:set, :public, :named_table]),
         :ok <- ensure_table(@queries_table_name, [:bag, :public, :named_table]) do
      :ok
    end
  end

  defp ensure_table(name, opts) do
    case :ets.whereis(name) do
      :undefined ->
        try do
          _ = :ets.new(name, opts)
          :ok
        rescue
          e -> {:error, e}
        end

      _ ->
        :ok
    end
  end

  @doc """
  Puts or updates a request entry for `request_id`.

  If the entry does not exist, creates it with `started_at` and `ended_at` (nil).
  If it exists, updates `ended_at` when `ended_at` is passed. Queries are stored
  in a separate bag table and merged in `get_request/1`.
  """
  @spec put_request(String.t() | term(), map()) :: :ok
  def put_request(request_id, %{started_at: _} = data) do
    entry = Map.put_new(data, :ended_at, nil) |> Map.take([:started_at, :ended_at])
    :ets.insert(@table_name, {request_id, entry})
    :ok
  end

  def put_request(request_id, %{ended_at: _} = data) do
    case :ets.lookup(@table_name, request_id) do
      [{^request_id, existing}] ->
        updated = Map.merge(existing, data)
        :ets.insert(@table_name, {request_id, updated})
        :ok

      [] ->
        :ok
    end
  end

  @doc """
  Appends a query map to the request's query list.

  Uses a single ETS insert into a :bag table, so concurrent appends from multiple
  processes are safe. If no request entry exists (e.g. Plug not in use or no-op),
  a request is created with `started_at` set to the current monotonic time so
  query data is not dropped.
  """
  @spec append_query(String.t() | term(), map()) :: :ok
  def append_query(request_id, query_map) do
    case :ets.lookup(@table_name, request_id) do
      [] ->
        entry = %{started_at: System.monotonic_time(), ended_at: nil}
        :ets.insert_new(@table_name, {request_id, entry})
      [_] ->
        :ok
    end

    :ets.insert(@queries_table_name, {request_id, query_map})
    :ok
  end

  @doc """
  Returns the request entry for `request_id`, or `nil` if not found.

  Merges in the query list from the queries bag (order is bag iteration order).
  """
  @spec get_request(String.t() | term()) :: map() | nil
  def get_request(request_id) do
    case :ets.lookup(@table_name, request_id) do
      [{^request_id, entry}] ->
        queries =
          :ets.lookup(@queries_table_name, request_id)
          |> Enum.map(&elem(&1, 1))
          |> Enum.reverse()

        Map.put(entry, :queries, queries)

      [] ->
        nil
    end
  end

  @doc """
  Normalizes a raw SQL string for grouping query shapes.

  Replaces parameter placeholders (`$1`, `$2`, ... or `?`) with a single
  placeholder and returns `{normalized_sql, param_count}`. Used to group
  identical query shapes (e.g. same query with different param values).
  """
  @spec normalize_sql(String.t(), list()) :: {String.t(), non_neg_integer()}
  def normalize_sql(sql, params) when is_binary(sql) and is_list(params) do
    param_count = length(params)
    # PostgreSQL-style $1, $2, ...
    normalized =
      Regex.replace(~r/\$\d+/, sql, "?", global: true)

    {normalized, param_count}
  end
end
