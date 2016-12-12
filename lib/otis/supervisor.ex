defmodule Otis.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  def init([packet_interval: packet_interval, packet_size: packet_size]) do
    children = [
      worker(Otis.DNSSD, []),
      worker(Otis.SSDP, []),
      worker(Otis.SNTP, [config(Otis.SNTP)[:port]]),
      worker(Otis.Source.File.Cache, []),
      worker(Otis.State.Repo, []),
      worker(Otis.State.Events, []),
      worker(Otis.State.Persistence, []),

      supervisor(Registry, [:unique, Otis.Pipeline.Streams.namespace()], id: Otis.Pipeline.Streams.namespace()),
      supervisor(Otis.Pipeline.Streams, []),

      supervisor(Registry, [:duplicate, Otis.Receivers.Sets.set_namespace()], id: Otis.Receivers.Sets.set_namespace()),
      supervisor(Registry, [:duplicate, Otis.Receivers.Sets.subscriber_namespace()], id: Otis.Receivers.Sets.subscriber_namespace()),
      supervisor(Otis.Receivers.Sets, []),

      worker(Otis.Receivers.Database, []),
      worker(Otis.Receivers, []),

      supervisor(Otis.Channels, []),
      # This needs to be called by the app hosting the application
      # worker(Otis.Startup, [Otis.State, Otis.Channels], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end

  def config(mod) do
    Application.get_env :otis, mod
  end
end
