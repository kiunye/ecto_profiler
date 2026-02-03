defmodule EctoProfiler.Telemetry do
  @moduledoc """
  Attaches to Ecto query Telemetry events and forwards them to Storage.

  Call `attach/0` (e.g. from Application.start) to attach handlers for each
  repo in config. The handler extracts query, params, duration, repo, and
  source from the event and appends to the current request in EctoProfiler.Storage.
  """

  alias EctoProfiler.Storage

  @handler_id "ecto_profiler-query-handler"

  @doc """
  Attaches query handlers for each repo in config `:ecto_profiler :repos`.

  No-op if the repos list is empty. Idempotent: safe to call once at application start.
  """
  @spec attach() :: :ok | {:error, term()}
  def attach do
    repos = Application.get_env(:ecto_profiler, :repos, [])

    case Storage.ensure_table() do
      :ok ->
        Enum.each(repos, &attach_repo/1)
        :ok

      {:error, _} = err ->
        err
    end
  end

  @doc false
  @spec handle_event(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          :telemetry.handler_config()
        ) :: :ok
  def handle_event(_event, measurements, metadata, _config) do
    request_id = Process.get(:ecto_profiler_request_id, "default")
    query_map = build_query_map(measurements, metadata)
    Storage.append_query(request_id, query_map)
    :ok
  end

  defp build_query_map(measurements, metadata) do
    duration_native = Map.get(measurements, :total_time) || Map.get(measurements, :query_time, 0)
    duration_us = System.convert_time_unit(duration_native, :native, :microsecond)
    query = Map.get(metadata, :query, "")
    params = Map.get(metadata, :params, [])
    repo = metadata |> Map.get(:repo) |> repo_name()
    source = Map.get(metadata, :source)
    {normalized_sql, _param_count} = Storage.normalize_sql(query, params)

    %{
      query: query,
      params: params,
      duration_us: duration_us,
      repo: repo,
      source: source,
      normalized_sql: normalized_sql
    }
  end

  defp attach_repo(repo_module) when is_atom(repo_module) do
    prefix = telemetry_prefix(repo_module)
    event = prefix ++ [:query]
    id = "#{@handler_id}-#{inspect(repo_module)}"

    :telemetry.attach(id, event, &__MODULE__.handle_event/4, %{})
  end

  defp telemetry_prefix(repo_module) do
    repo_module
    |> Module.split()
    |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
  end

  defp repo_name(nil), do: nil
  defp repo_name(repo) when is_atom(repo), do: repo
  defp repo_name(other), do: inspect(other)
end
