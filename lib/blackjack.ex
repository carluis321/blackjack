defmodule Blackjack do
  @moduledoc """
  Documentation for `Blackjack`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Blackjack.hello()
      :world

  """
  def hello do
    :world
  end

  @spec is_game_finished?(map) :: map
  def is_game_finished?(%{"players" => players} = state) do
    state = case Enum.find(players, & &1.turn) do
      %Player{} ->
        state

      nil ->
        Map.put(state, "game", :finished)
    end

    Player.is_there_winners?(state)
  end
end
