# EctoProfiler

Query profiling, N+1 detection, and slow-query tooling for Ecto applications.

## Installation

Add `ecto_profiler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_profiler, "~> 0.1.0"}
  ]
end
```

## Setup

1. **Add to mix.exs** — add the dependency (see above).
2. **Add the Plug** — in your Phoenix endpoint (or pipeline), add the EctoProfiler Plug so request data is collected. (Implementation in a later release; visit `/_profiler` for the dashboard when available.)
3. **Visit /_profiler** — when running a Phoenix app with the Plug, open `/_profiler` in the browser to see the dashboard.

## Configuration

Configure the application in your `config/*.exs` files (e.g. `config/config.exs` or `config/dev.exs`):

| Option             | Type    | Default | Description |
|--------------------|---------|---------|-------------|
| `slow_query_ms`    | integer | `100`   | Threshold in milliseconds above which a query is considered slow. |
| `enable_explain`   | boolean | `true`  | Whether to run EXPLAIN on slow queries and store results (e.g. for the dashboard). |

### Example

```elixir
config :ecto_profiler,
  slow_query_ms: 100,
  enable_explain: true
```

## Code quality and security

For contributors: the project uses Credo, Dialyxir, and Sobelow (dev dependencies). Run:

- **Credo** (style and consistency): `mix credo`
- **Dialyxir** (type checking): `mix dialyzer`
- **Sobelow** (security): `mix sobelow`

## Documentation

Documentation is published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at <https://hexdocs.pm/ecto_profiler>.
