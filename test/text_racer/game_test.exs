defmodule TextRacer.RowTest do
  use ExUnit.Case, async: true

  alias TextRacer.Row

  use PropCheck
  use PropCheck.StateM.ModelDSL

  property "track can not go outside game boundries", [] do
    forall cmds <- commands(__MODULE__) do
      {_history, _state, result} = run_commands(__MODULE__, cmds)

      result == :ok
    end
  end

  def initial_state do
    Row.new(0, 21)
  end

  def command_gen(state) do
    frequency([
      {1, {:update, [state, direction()]}}
    ])
  end

  defcommand :update do
    def impl(state, direction), do: Row.update(state, direction)
    def pre(_state, _args), do: true
    def next(_old_state, [_, _direction], result), do: result
    def post(_initial, [_, _direction], final) do
      final.left >= 0
      && final.right <= 21
    end
  end

  def direction do
    oneof(~w[left right straight shrink enlarge]a)
  end

  describe "when on the left side" do
    setup do
      row = %{Row.new(5, 21) | left: 0, right: 10}

      {:ok, [row: row]}
    end

    test "left", %{row: row} do
      assert row == Row.update(row, :left)
    end

    test "right", %{row: row} do
      right_row = Row.update(row, :right)

      assert right_row.left == row.left + 1
      assert right_row.right == row.right + 1
    end
  end

  describe "when on the right side" do
    setup do
      row = %{Row.new(5, 21) | left: 5, right: 20}

      {:ok, [row: row]}
    end

    test "right", %{row: row} do
      assert row == Row.update(row, :right)
    end

    test "left", %{row: row} do
      left_row = Row.update(row, :left)

      assert left_row.left == row.left - 1
      assert left_row.right == row.right - 1
    end
  end
end

defmodule TextRacer.GameTest do
  use ExUnit.Case, async: true

  alias TextRacer.Game

  test "speed" do
    game = Game.new()

    assert Game.speed(game) == 0
  end

  test "accelerate" do
    game =
      Game.new()
      |> Game.steer(:accelerate)

    assert Game.speed(game) == 10

    max_speed_game = %{game | speed: 190}

    assert max_speed_game == Game.steer(max_speed_game, :accelerate)
  end

  test "decelerate when not accelerated" do
    game =
      Game.new()
      |> Game.steer(:decelerate)

    assert Game.speed(game) == 0
  end

  test "a game is 21 characters wide and eight tall" do
    lines =
      Game.new()
      |> to_string()
      |> String.split(~r/\n/)

    assert length(lines) == 8

    for line <- lines do
      assert String.length(line) == 21
      graphemes = String.graphemes(line)
      assert ["O" | rest] = graphemes
      assert "O" == List.last(rest)
    end
  end

  test "the car starts in the middle of the track" do
    game = Game.new()

    assert game.position == 11
  end

  test "steering to the left moves the car left" do
    game = Game.new() |> Game.steer(:accelerate)
    initial_position = game.position

    next_game = Game.steer(game, :left)

    assert next_game.position == initial_position - 1
    assert next_game.status == :running
  end

  test "steering to the left moves the car right" do
    game = Game.new() |> Game.steer(:accelerate)
    initial_position = game.position

    next_game = Game.steer(game, :right)

    assert next_game.position == initial_position + 1
    assert next_game.status == :running
  end

  test "tick straight" do
    game = Game.new() |> Game.steer(:accelerate)
    top_track = game.track |> hd()
    next_game = Game.tick(game, :straight)

    assert top_track == next_game.track |> hd()
  end

  test "tick increase the length of the track by one" do
    game = Game.new() |> Game.steer(:accelerate)
    next_game = Game.tick(game, :straight)

    assert length(next_game.track) == length(game.track) + 1
  end

  describe "a game that is over" do
    setup do
      game = Game.new()
      game = %{game | status: :game_over}

      {:ok, [game: game]}
    end

    test "steering left does nothing", %{game: game} do
      assert game == Game.steer(game, :left)
    end

    test "steering right does nothing", %{game: game} do
      assert game == Game.steer(game, :right)
    end

    test "tick does nothing", %{game: game} do
      assert game == Game.tick(game, :straight)
      assert game == Game.tick(game, :right)
      assert game == Game.tick(game, :left)
      assert game == Game.tick(game, :squeeze)
      assert game == Game.tick(game, :enlarge)
    end
  end
end
