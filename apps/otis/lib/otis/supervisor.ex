defmodule Otis.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    children = [
      worker(Otis.State, []),
      supervisor(Otis.Zones.Supervisor, []),
      worker(Otis.Zones, []),
      supervisor(Otis.Receivers.Supervisor, []),
      worker(Otis.Receivers, []),
      worker(Otis.Resources, []),
      worker(Otis.Startup, [Otis.State, Otis.Zones, Otis.Receivers], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end

