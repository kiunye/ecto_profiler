# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# Run "mix help config" for more information.
import Config

config :ecto_profiler,
  # List of Ecto Repo modules to attach to (e.g. [MyApp.Repo]). Empty = no attach.
  repos: [],
  # Threshold in milliseconds above which a query is considered slow (default: 100).
  slow_query_ms: 100,
  # Whether to run EXPLAIN on slow queries and store results (default: true in dev).
  enable_explain: true

import_config "#{config_env()}.exs"
