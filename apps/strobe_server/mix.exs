defmodule Strobe.Server.Mixfile do
  use Mix.Project

  # Default to "host" target to prevent this app doing anything in most
  # circumstances, use `MIX_TARGET=rpi3` for nerves-related activity
  @target System.get_env("MIX_TARGET") || "host"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :bbb, :x86_64]

  Mix.shell.info([:green, """
  Env
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])
  def project do
    [app: :strobe_server,
     version: "0.1.0",
     elixir: "~> 1.8.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 1.5"],
     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: [loadconfig: [&bootstrap/1]],
     deps: deps()]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.shell.info([:green, "Bootstrap", :reset])
    Mix.Task.run("loadconfig", args)
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application, do: application(@target)

  # Specify target specific application configurations
  # It is common that the application start function will start and supervise
  # applications which could cause the host to fail. Because of this, we only
  # invoke StrobeServer.start/2 when running on a target.
  def application("host") do
    [extra_applications: [:logger]]
  end
  def application(_target) do
    [mod: {Strobe.Server.Application, []},
     applications: [
       :gen_stage,
       :nerves_network,
       :nerves_network_interface,
     ],
     extra_applications: [:logger],
     included_applications: [
       :esqlite,
       :elvis,
       :otis,
       :peel,
       :otis_library_bbc,
       :otis_library_upnp,
       :otis_library_airplay,
     ],
    ]
  end

  def deps do
    deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: []
  def deps(target) do
    [
      {:nerves, "~> 1.4.4", runtime: false},
      # {:shoehorn, "~> 0.4"},
      {:toolshed, "~> 0.2"},

      {:nerves_runtime, "~> 0.9"},
      {:"nerves_system_#{target}", "~> 1.7", runtime: false},
      
      {:gen_stage, "~> 0.14"},
      {:nerves_network, "~> 0.5"},
      {:nerves_network_interface, "~> 0.4"},
      {:elvis, in_umbrella: true},
    ]
  end

  # We do not invoke the Nerves Env when running on the Host
  # def aliases("host"), do: []
  # def aliases(_target) do
  #   ["deps.precompile": ["nerves.precompile", "deps.precompile"],
  #    "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  # end
end
