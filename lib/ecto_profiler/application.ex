defmodule EctoProfiler.Application do
  @moduledoc """
  OTP Application callback for EctoProfiler.

  Starts the supervision tree. Does not start any Phoenix-dependent children;
  Phoenix and LiveView are optional dependencies and are only used when
  present in the host application (e.g. toolbar and dashboard in Task 2/3).
  """

  use Application

  @impl true
  def start(_type, _args) do
    # No Phoenix-dependent children here; ETS and Telemetry attach added in Phase 0.3
    children = []

    opts = [strategy: :one_for_one, name: EctoProfiler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
