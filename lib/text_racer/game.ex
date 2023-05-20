defmodule TextRacer.Game do
  @moduledoc """
  The data of a single game.

  This module handles ticks and the user's input. There are a few
  convience funcitons for getting information out of the game.
  """

  @height 8
  @display_height 8
  @max_width 21
  @min_width 5
  alias TextRacer.Row

  @typedoc "the column where the car is located"
  @type position :: non_neg_integer()

  @typedoc "The track without the car"
  @type track :: [TextRacer.Row.t()]

  @type t :: %__MODULE__{
   position: position(),
   track: track(),
  }

  defstruct position: 11,
            track:
              Stream.duplicate(Row.new(@min_width, @max_width), @display_height) |> Enum.to_list(),
            height: @height,
            status: :running,
            speed: 0,
            wait: 0,
            debug: false,
            score: 0,
            obsticles: false,
            warp: false

  def new do
    %__MODULE__{}
  end

  def speed(%{speed: speed}) do
    speed
  end

  @spec score(%{:score => any, optional(any) => any}) :: any
  def score(%{score: score}) do
    score
  end

  def toggle_option(game, option) do
    value = Map.get(game, option, false)
    %{game | option => not value}
  end

  def next_tick_options(%{warp: true}) do
    [:obsticle]
  end

  def next_tick_options(%{obsticles: false}) do
    [:straight, :right, :left, :shrink]
  end

  def next_tick_options(_game) do
    [:straight, :right, :left, :shrink, :obsticle]
  end

  @spec tick(TextRacer.Game.t(), any) :: map
  def tick(%__MODULE__{status: :game_over} = game, _direction) do
    game
  end

  def tick(%__MODULE__{wait: wait, speed: speed} = game, _) when wait > 0 or speed <= 0 do
    %{game | wait: wait - speed}
  end

  def tick(%__MODULE__{} = game, direction) do
    side =
      if game.warp do
        "|"
      else
        "O"
      end

    next_top =
      Row.update(hd(game.track), direction)
      |> Row.set_side(side)

    game
    |> add_top(next_top)
    |> check_collision()
    |> reset_wait()
  end

  def steer(%{status: :game_over} = game, _direction) do
    game
  end

  def steer(%{speed: current_speed} = game, :accelerate) when current_speed < 190 do
    %{game | speed: current_speed + 10}
  end

  def steer(game, :accelerate) do
    game
  end

  def steer(%{speed: current_speed} = game, :decelerate) when current_speed > 0 do
    %{game | speed: current_speed - 10}
  end

  def steer(game, :decelerate) do
    game
  end

  def steer(game, :left) do
    game
    |> update_position(-1)
    |> check_collision()
  end

  def steer(game, :right) do
    game
    |> update_position(1)
    |> check_collision()
  end

  defimpl String.Chars do
    @display_height 8

    def to_string(%{position: position, track: track, height: height, debug: debug}) do
      height_index = height - 1

      track
      |> Enum.take(@display_height)
      |> Enum.with_index(fn
        row, ^height_index ->
          row
          |> to_charlist()
          |> add_car(position)
          |> Kernel.to_string()
          |> add_debug(row, debug)

        row, _ ->
          row
          |> to_charlist()
          |> Kernel.to_string()
          |> add_debug(row, debug)
      end)
      |> Enum.join("\n")
    end

    defp add_debug(string, row, true) do
      string <> inspect(row)
    end

    defp add_debug(string, _, false) do
      string
    end

    defp add_car(row, position) do
      List.replace_at(row, position, "∆")
    end
  end

  defp add_top(%{speed: 0} = game, _) do
    game
  end

  defp add_top(game, top) do
    %{game | track: [top | game.track]}
  end

  defp update_position(%{speed: 0} = game, _) do
    game
  end

  defp update_position(game, amount) do
    %{game | position: game.position + amount}
  end

  defp check_collision(%{position: position, track: track, height: height} = game) do
    row = Enum.at(track, height - 1)

    cond do
      Row.collides_at?(row, position) ->
        %{game | status: :game_over}

      true ->
        %{game | score: game.score + div(game.speed, 10) + warp_bonus(game)}
    end
  end

  defp warp_bonus(%{warp: false}) do
    0
  end

  defp warp_bonus(%{speed: 0}) do
    0
  end

  defp warp_bonus(%{warp: true, track: track}) do
    22 - Row.width(hd(track))
  end

  defp reset_wait(game) do
    %{game | wait: 191}
  end
end
