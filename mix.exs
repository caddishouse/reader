defmodule Caddishouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :caddishouse,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Caddishouse.Application, []},
      extra_applications: [
        :logger,
        :honeybadger,
        :runtime_tools,
        :ueberauth_google,
        :ueberauth_microsoft
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 0.18"},
      {:phoenix_live_reload, "~> 1.4.0"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:ex_heroicons, "~> 2.0.0"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:ueberauth, "~> 0.7", override: true},
      {:ueberauth_google, "~> 0.10"},
      {:ueberauth_microsoft, "~> 0.15"},
      {:google_api_drive, "~> 0.25.1"},
      {:finch, "~> 0.16.0"},
      {:castore, "~> 0.1"},
      {:timex, "~> 3.7.8"},
      {:oban, "~> 2.13"},

      # Error logging
      {:honeybadger, "~> 0.1"},

      # Upload
      {:uuid, "~> 1.1"},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0"},

      # Minio
      {:ex_aws, "~> 2.5.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:sobelow, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:git_hooks, "~> 0.7.2", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:mox, "~> 1.0.2", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "esbuild pdf_worker --minify",
        "phx.digest"
      ]
    ]
  end
end
