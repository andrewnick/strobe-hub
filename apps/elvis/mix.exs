defmodule Elvis.Mixfile do
  use Mix.Project

  def project do
    [app: :elvis,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.8.0",
     elixirc_paths: elixirc_paths(Mix.env()),
     compilers: [:phoenix] ++ Mix.compilers(),
     build_embedded: Mix.env() == :prod,
     start_permanent: Mix.env() == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    # `socket` is a dependency from another app that doesn't have it in its
    # applications list so I need to include it here
    [extra_applications: [:logger, :socket],
     mod: {Elvis, []},
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.4"},
     {:phoenix_html, "~> 2.11"},
     {:phoenix_live_reload, "~> 1.2", only: :dev},
     {:plug_cowboy, "~> 1.0"},
     {:otis, in_umbrella: true},
     {:peel, in_umbrella: true},
     {:otis_library_bbc, in_umbrella: true},
     {:otis_library_upnp, in_umbrella: true},
     {:otis_library_airplay, in_umbrella: true},
     # Needs to be compatible with that specified by nerves
     {:distillery, "~> 2.0", runtime: false},
     {:logger_papertrail_backend, "~> 1.1"},
     {:gen_stage, "~> 0.14"},
     {:strobe_events, in_umbrella: true},
   ]
  end
end
