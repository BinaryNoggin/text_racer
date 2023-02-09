defmodule TextRacerWeb.GameLive do
  @moduledoc """
  This is the live view for someone playing TextRacer
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
    Score: <%= Game.score(@game) %>
    Speed: <%= Game.speed(@game) %>
    Obsticles: <%= @game.obsticles %>
    Warp: <%= @game.warp %>

    <pre phx-window-keydown="steer">
    <%= to_string(@game) %>
    </pre>
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
