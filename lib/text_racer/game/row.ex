defmodule TextRacer.Row do
  @moduledoc """
  Representation of one section of the roadway.
  """
  defstruct [:left, :right, :obsticle, :max_width, :min_width, :side_char]

  @type t :: %__MODULE__{
    left: column(),
    right: column(),
    obsticle: obsticle_pos(),
    max_width: width(),
    min_width: width(),
    side_char: String.t()
  }

  @typedoc "The full width of the row including barrels"
  @type width :: non_neg_integer()

  @typedoc "A column on the row"
  @type column :: non_neg_integer()

  @typedoc "The spot where there is an obsticle"
  @type obsticle_pos :: :none | column()

  def new(min_width, max_width) do
    %__MODULE__{
      left: 0,
      right: max_width - 1,
      obsticle: :none,
      max_width: max_width,
      min_width: min_width,
      side_char: "O"
    }
  end

  @doc """
  checks for collisions with obsticles or sides of the roadway at a given position
  """
  def collides_at?(%{left: left, right: right, obsticle: obsticle}, position) do
    position <= left or position >= right or position == obsticle
  end

  def width(%{left: left, right: right}) do
    right - left
  end

  @spec update(
          t(),
          :enlarge | :left | :obsticle | :right | :shrink | :straight
        ) :: %{:obsticle => :none | number, optional(any) => any}
  @doc """
  Returns a new row updated with the widths updates to the new barrel positions
  """
  def update(%__MODULE__{left: left, right: right} = row, :left) do
    cond do
      left == 0 -> update(row, :straight)
      true -> %{row | left: left - 1, obsticle: :none, right: right - 1}
    end
  end

  def update(%__MODULE__{left: left, right: right} = row, :right) do
    cond do
      right == 20 -> update(row, :straight)
      true -> %{row | left: left + 1, obsticle: :none, right: right + 1}
    end
  end

  def update(row, :straight) do
    %{row | obsticle: :none}
  end

  def update(%__MODULE__{left: left, right: right} = row, :enlarge) do
    cond do
      right < 20 and left > 0 ->
        %{row | left: left - 1, right: right + 1, obsticle: :none}

      true ->
        update(row, :straight)
    end
  end

  def update(%__MODULE__{left: left, right: right, min_width: _min_width} = row, :shrink) do
    cond do
      right - left > 0 ->
        %{row | left: left + 1, right: right - 1, obsticle: :none}

      true ->
        update(row, :straight)
    end
  end

  def update(%__MODULE__{left: left, right: right} = row, :obsticle) do
    %{row | obsticle: left + Enum.random(1..(right - left - 1))}
  end

  def set_side(row, char) do
    %{row | side_char: char}
  end

  defimpl List.Chars do
    @empty_track '                     '

    def to_charlist(%{left: left, right: right, obsticle: obsticle, side_char: side_char}) do
      @empty_track
      |> List.replace_at(left, side_char)
      |> List.replace_at(right, side_char)
      |> add_obsticle(obsticle)
    end

    def add_obsticle(list, :none) do
      list
    end

    def add_obsticle(list, obsticle) do
      List.replace_at(list, obsticle, "*")
    end
  end
end
