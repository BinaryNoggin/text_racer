defmodule TextRacerWeb.GameLive do
  @moduledoc """
  This is the LiveView for playing TextRacer
  """
  use TextRacerWeb, :live_view

  alias TextRacerWeb.Endpoint
  alias TextRacer.Game

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    Endpoint.subscribe("clock")

    {:ok,
     socket
     |> new_game()}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="bg-gray-200 p-4 rounded-lg">
      <div class="text-lg font-bold mb-2">Game Status</div>
      <div class="flex justify-between items-center mb-2">
        <div>Speed: <%= Game.speed(@game) %></div>
        <div>Score: <%= Game.score(@game) %></div>
      </div>
      <div class="bg-gray-50 p-4 rounded-lg shadow-inner text-3xl max-w-m">
        <pre class="font-mono max-w-s text-3xl" phx-window-keydown="steer"><%= to_string(@game) %></pre>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("steer", %{"key" => "ArrowLeft"}, socket) do
    {:noreply,
     socket
     |> steer(:left)}
  end

  def handle_event("steer", %{"key" => "ArrowRight"}, socket) do
    {:noreply,
     socket
     |> steer(:right)}
  end

  def handle_event("steer", %{"key" => "ArrowUp"}, socket) do
    {:noreply,
     socket
     |> steer(:accelerate)}
  end

  def handle_event("steer", %{"key" => "ArrowDown"}, socket) do
    {:noreply,
     socket
     |> steer(:decelerate)}
  end

  def handle_event("steer", %{"key" => "d"}, socket) do
    {:noreply,
     socket
     |> toggle_option(:debug)}
  end

  def handle_event("steer", %{"key" => "r"}, socket) do
    {:noreply,
     socket
     |> new_game()}
  end

  def handle_event("steer", %{"key" => "o"}, socket) do
    {:noreply,
     socket
     |> toggle_option(:obsticles)}
  end

  def handle_event("steer", %{"key" => "w"}, socket) do
    {:noreply,
     socket
     |> toggle_option(:warp)}
  end

  def handle_event("steer", _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: "clock", event: "tick"}, socket) do
    {:noreply,
     socket
     |> tick()}
  end

  defp new_game(socket) do
    socket
    |> assign(game: Game.new())
    |> clear_flash()
  end

  def steer(%{assigns: %{game: game}} = socket, direction) do
    case Game.steer(game, direction) do
      %{status: :running} = game ->
        socket
        |> assign(game: game)

      %{status: :game_over} = game ->
        socket
        |> put_flash(:error, "Game Over")
        |> assign(game: game)
    end
  end

  def toggle_option(%{assigns: %{game: game}} = socket, option) do
    socket
    |> assign(:game, Game.toggle_option(game, option))
  end

  def tick(%{assigns: %{game: game}} = socket) do
    direction =
      game
      |> Game.next_tick_options()
      |> Enum.random()

    case Game.tick(game, direction) do
      %{status: :running} = game ->
        socket
        |> assign(game: game)

      %{status: :game_over} = game ->
        socket
        |> put_flash(:error, "Game Over")
        |> assign(game: game)
    end
  end
end
