defmodule Deck do
  @cards (for value <- [:A, 2, 3, 4, 5, 6, 7, 8, 9, 10, :J, :Q, :K],
              {color, type} <- [
                {:red, :heart},
                {:black, :pica},
                {:black, :trebol},
                {:red, :spade}
              ] do
            {color, type, value}
          end)

  @spec shuffle() :: [tuple()]
  def shuffle() do
    Enum.shuffle(@cards)
  end

  @spec take(list(), integer()) :: {[tuple()], [tuple()]}
  def take(deck, total) do
    Enum.split(deck, total)
  end

  @spec take(nonempty_maybe_improper_list) :: {tuple(), [tuple()]}
  def take([card | deck]) do
    {card, deck}
  end
end
