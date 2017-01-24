
defmodule HLS.Client do
  alias   Experimental.{GenStage}
  require Logger

  use     GenStage

  def open!(stream, id, opts \\ [bandwidth: :highest])
  def open!(%HLS.Stream{} = stream, id, opts) do
    stream(stream, id, opts)
  end

  defp stream(stream, id, opts) do
    {:ok, pid} =  HLS.Client.start_link(stream, id, opts)
    {:ok, GenStage.stream([pid])}
  end

  def start_link(stream, id, opts) do
    GenStage.start_link(__MODULE__, [stream, id, opts])
  end

  # Callbacks

  defmodule S do
    defstruct [:reader, :producer]
  end

  def init([stream, _id, opts]) do
    {:ok, producer} = GenStage.start_link(HLS.Client.Playlist, [stream, stream.reader, opts])
    state = %S{reader: stream.reader, producer: producer}
    {:producer_consumer, state, subscribe_to: [{producer, [max_demand: 1]}]}
  end

  def handle_events(events, {producer, _ref} = _from, %S{reader: reader} = state) do
    data =
      events
      |> Enum.map(&read_with_timing(&1, reader))
      |> Enum.unzip
      |> monitor_bandwidth(producer)
    {:noreply, data, state}
  end

  def handle_call(:stop, _from, state) do
    GenStage.stop(state.producer)
    {:stop, :normal, :ok, state}
  end

  defp read_with_timing(media, reader) do
    {t, data} = :timer.tc(fn -> HLS.Reader.read!(reader, media.url) end)
    {t / (media.duration * 1_000_000), data}
  end

  # TODO: upgrade/downgrade stream based on load times
  # GenStage.cast(producer, :downgrade)
  # GenStage.cast(producer, :upgrade)
  defp monitor_bandwidth({times, data}, _producer) do
    average = Enum.reduce(times, 0, fn(p, sum) -> p + sum end) / length(times)
    if average > 0.5 do
      Logger.warn "=== Media load time #{ inspect 100 * Float.round(average, 2) }%"
    end
    data
  end
end