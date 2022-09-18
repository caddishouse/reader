import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/caddishouse start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
#
if System.get_env("PHX_SERVER") do
  config :caddishouse, CaddishouseWeb.Endpoint, server: true
end

aws_scheme = if config_env() == :prod, do: "https://", else: "http://"

if config_env() != :test do
  config :ex_aws,
    scheme: aws_scheme,
    region: "local",
    access_key_id: System.fetch_env!("MINIO_ACCESS_KEY"),
    secret_access_key: System.fetch_env!("MINIO_SECRET_KEY")
else
  config :ex_aws,
    scheme: aws_scheme,
    region: "local",
    access_key_id: "some-test",
    secret_access_key: "some-test"
end

config :ex_aws, :s3,
  scheme: aws_scheme,
  region: "local",
  port: System.get_env("MINIO_PORT", "9000"),
  host: System.get_env("MINIO_HOST", "localhost"),
  bucket: "uploads"

if config_env() == :test do
  # TODO At the moment it's not possible to use Mox with S3 Waffle.
  config :waffle,
    storage: Waffle.Storage.Local,
    storage_dir_prefix: "/tmp/caddishouse_tests",
    asset_host: System.get_env("ASSET_URL", "http://localhost:9001")
else
  config :waffle,
    storage: Waffle.Storage.S3,
    bucket: "uploads",
    asset_host: System.get_env("ASSET_URL", "http://localhost:9001")
end

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_OAUTH_CLIENT"),
  client_secret: System.get_env("GOOGLE_OAUTH_SECRET"),
  redirect_uri:
    System.get_env(
      "GOOGLE_OAUTH_REDIRECT_URL",
      "http://localhost:3333/auth/google/callback"
    )

config :ueberauth, Ueberauth.Strategy.Microsoft.OAuth,
  client_id: System.get_env("MICROSOFT_OAUTH_CLIENT"),
  client_secret: System.get_env("MICROSOFT_OAUTH_SECRET"),
  redirect_uri:
    System.get_env(
      "MICROSOFT_OAUTH_REDIRECT_URL",
      "http://localhost:3333/auth/microsoft/callback"
    )

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :caddishouse, Caddishouse.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "caddishouse.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :caddishouse, CaddishouseWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :honeybadger,
    api_key: System.fetch_env!("HONEYBADGER_SECRET"),
    environment_name: :prod,
    ecto_repos: [Caddishouse.Repo],
    filter_args: false
end
