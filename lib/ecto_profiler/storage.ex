defmodule EctoProfiler.Storage do
  @moduledoc """
  ETS-backed storage for request and query data.

  Stores request entries keyed by request_id. Each entry holds a list of
  queries plus started_at/ended_at timestamps. Also provides normalized SQL
  for grouping query shapes (e.g. for N+1 detection).
  """

  @table_name :ecto_profiler_requests

  @doc """
  Ensures the ETS table exists. Idempotent. Call from the process that should
  own the table (e.g. Application.start or a supervisor child).

  The table is `:set`, `:public`, keyed by request_id.
  """
  @spec ensure_table() :: :ok | {:error, term()}
  def ensure_table do
    case :ets.whereis(@table_name) do
      :undefined ->
        try do
          _ = :ets.new(@table_name, [:set, :public, :named_table])
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

  If the entry does not exist, creates it with `started_at` set to now and
  `queries` empty. If it exists, updates `ended_at` when `ended_at` is passed.
  """
  @spec put_request(String.t() | term(), map()) :: :ok
  def put_request(request_id, %{started_at: _} = data) do
    entry = Map.put_new(data, :queries, []) |> Map.put_new(:ended_at, nil)
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

  The query map should include at least `:query`, `:params`, `:duration_us`,
  `:repo`, and optionally `:normalized_sql`, `:source`, `:stacktrace`.
  """
  @spec append_query(String.t() | term(), map()) :: :ok
  def append_query(request_id, query_map) do
    case :ets.lookup(@table_name, request_id) do
      [{^request_id, entry}] ->
        queries = [query_map | Map.get(entry, :queries, [])]
        :ets.insert(@table_name, {request_id, Map.put(entry, :queries, queries)})
        :ok

      [] ->
        :ok
    end
  end

  @doc """
  Returns the request entry for `request_id`, or `nil` if not found.
  """
  @spec get_request(String.t() | term()) :: map() | nil
  def get_request(request_id) do
    case :ets.lookup(@table_name, request_id) do
      [{^request_id, entry}] -> entry
      [] -> nil
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
