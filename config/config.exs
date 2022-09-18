# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :caddishouse,
  ecto_repos: [Caddishouse.Repo],
  generators: [binary_id: true]

config :ueberauth, Ueberauth,
  providers: [
    microsoft:
      {Ueberauth.Strategy.Microsoft,
       [
         prompt: "select_account",
         extra_scopes: "https://graph.microsoft.com/me/drive/root/children"
       ]},
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email https://www.googleapis.com/auth/drive.readonly",
         access_type: "offline"
       ]}
  ]

config :tesla, :adapter, {Tesla.Adapter.Finch, name: CaddishouseFinch, receive_timeout: 30_000}

config :caddishouse, Oban,
  repo: Caddishouse.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    import_media: [
      limit: 20
      # unique: [period: 60 * 60 * 5]
      # max_attempts: 3
    ]
  ]

# Configures the endpoint
# https://08ff-70-19-71-156.ngrok.io/auth/google/callback
config :caddishouse, CaddishouseWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaddishouseWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Caddishouse.PubSub,
  live_view: [signing_salt: "8ai/zu2g"],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
      ~r{lib/caddishouse_web/views/.*(ex)$},
      ~r{lib/caddishouse_web/templates/.*(eex)$}
    ]
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args: [
      "js/app.js",
      "--bundle",
      "--target=es2017",
      "--outdir=../priv/static/assets",
      "--external:/fonts/*",
      "--external:/images/*",
      "--external:fs",
      "--external:http",
      "--external:https",
      "--external:url",
      "--external:canvas",
      "--loader:.png=dataurl",
      "--loader:.gif=dataurl"
    ],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  pdf_worker: [
    args: [
      "vendor/pdfjs-dist/2.15.306/build/pdf.worker.js",
      "--bundle",
      "--target=es2017",
      "--outdir=../priv/static/assets",
      "--external:fs",
      "--external:http",
      "--external:https",
      "--external:url",
      "--external:canvas",
      "--loader:.png=dataurl",
      "--loader:.gif=dataurl"
    ],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.1.6",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
