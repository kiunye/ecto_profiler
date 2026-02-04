defmodule EctoProfiler.Plug do
  @moduledoc """
  Plug for EctoProfiler. No-op when Phoenix is not present or when only used
  outside a Phoenix pipeline (e.g. in tests without HTTP).

  In a Phoenix app, add this Plug to your endpoint or pipeline; in a later
  release it will set request_id and inject the dev toolbar. When Phoenix
  is not loaded, `call/2` simply returns the connection unchanged.
  """

  @behaviour Plug

  @doc false
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @doc """
  Passes the connection through. No-op for Phase 0; request lifecycle and
  toolbar will be added in later tasks when Phoenix is present.
  """
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn
  end
end
