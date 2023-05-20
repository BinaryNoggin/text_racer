defmodule TextRacer.Clock do
  @moduledoc """
  The clock for all games in the system.any()

  The clock takes is a broadcaster that it calls every tick.
  The ticks are every 33ms so roughly 30 times per second.
  """
  use GenServer

  @tick_time :timer.seconds(1) |> div(30)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    {:ok,
     %{broadcaster: args[:broadcaster], timer: nil}
     |> schedule_tick()}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    {:noreply,
     state
     |> broadcast()
     |> schedule_tick()}
  end

  defp schedule_tick(state) do
    %{state | timer: Process.send_after(self(), :tick, @tick_time)}
  end

  defp broadcast(%{broadcaster: broadcaster} = state) do
    broadcaster.()
    state
  end
end
