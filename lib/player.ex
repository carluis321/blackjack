defmodule Player do
  defstruct id: nil,
            name: "",
            hand: [],
            turn: false,
            burned: false,
            total: 0,
            gaveUp: false,
            isLast: false

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          name: String.t(),
          hand: list(),
          turn: boolean(),
          burned: boolean(),
          total: [non_neg_integer() | tuple()],
          gaveUp: boolean()
        }

  def add_hand(player, hand) when is_list(hand) do
    %Player{player | hand: hand}
    |> sum_total()
  end

  def add_hand(player, hand) do
    %Player{player | hand: [hand | player.hand]}
    |> sum_total()
  end

  def sum_total(%Player{} = player) do
    total =
      player
      |> has_ace?()
      |> count_total()

    %Player{player | total: total}
  end

  @spec has_ace?(Player.t()) :: {Player.t(), boolean()}
  def has_ace?(%Player{hand: hand} = player) do
    exists =
      Enum.reduce(hand, false, fn {_, _, value}, have? ->
        case have? do
          true ->
            true

          false when value == :A ->
            true

          false ->
            false
        end
      end)

    {player, exists}
  end

  defp count_total({%Player{hand: hand}, true}) do
    {ace_cards, rest_hand} =
      Enum.split_with(hand, fn
        {_, _, :A} -> true
        {_, _, _} -> false
      end)

    val1 = count_with_aces(1, ace_cards, rest_hand)
    val2 = count_with_aces(11, ace_cards, rest_hand)

    val3 =
      Enum.with_index(ace_cards)
      |> Enum.reduce(0, fn {_, index}, acc ->
        if index == 0 do
          acc + count_normal_cards(rest_hand, 11)
        else
          acc + 1
        end
      end)

    {val1, val2, val3}
  end

  defp count_total({%Player{hand: hand}, false}) do
    count_normal_cards(hand, 0)
  end

  defp count_with_aces(_, [], rest) do
    count_normal_cards(rest, 0)
  end

  defp count_with_aces(ace_value, [_ | aces], rest) do
    ace_value + count_with_aces(ace_value, aces, rest)
  end

  defp count_normal_cards([{_, _, value} | cards], total) when value in [:J, :Q, :K] do
    count_normal_cards(cards, total + 10)
  end

  defp count_normal_cards([{_, _, value} | cards], total) do
    count_normal_cards(cards, total + value)
  end

  defp count_normal_cards([], total) do
    total
  end

  def set_turn(player, turn) do
    %Player{player | turn: turn}
  end

  defp validate_player(%Player{burned: true}) do
    {:error, "player cant play: burned"}
  end

  defp validate_player(player) do
    {:ok, player}
  end

  defp do_action({:ok, player}, :add, deck) do
    {card, deck} = Deck.take(deck)

    player =
      player
      |> add_hand(card)
      |> is_burned?()

    {:ok, player, deck}
  end

  defp do_action({:ok, player}, :stay, deck) do
    player = %Player{player | turn: false}

    {:ok, player, deck}
  end

  defp do_action({:error, reason}, _action, _deck) do
    {:error, reason}
  end

  defp is_burned?(%Player{total: {v1, v2, v3}} = player)
    when v1 > 21 and v2 > 21 and v3 > 21
    do
      %Player{player | burned: true, turn: false}
  end

  defp is_burned?(%Player{total: total} = player)
    when is_integer(total) and total > 21
    do
      %Player{player | burned: true, turn: false}
  end

  defp is_burned?(player), do: player

  @spec action(map, Player.t(), :add | :stay | :gaveUp) :: map
  def action(%{"deck" => deck} = state, player, action) do
    new_state =
      player
      |> validate_player()
      |> do_action(action, deck)
      |> after_action(state, action)

    %{"players" => players} = new_state

    actual_player = Enum.find(players, fn (p) -> p.id == player.id end)

    if action == :stay or action == :gaveUp or actual_player.burned == true do
      set_next_player(new_state, player)
    else
      new_state
    end
  end

  defp after_action({:error, reason}, %{"errors" => errors} = state, _) do
    Map.put(state, "errors", [reason | errors])
  end

  defp after_action({:ok, player, new_deck}, %{"players" => players} = state, action) do
    %Player{id: player_id} = player

    players =
      Enum.map(players, fn
        %Player{id: id} when id == player_id ->
          player

        oldPlayer ->
          oldPlayer
      end)

    state = Map.put(state, "players", players)

    case action do
      :add ->
        Map.put(state, "deck", new_deck)
      _ -> state
    end
  end

  @spec is_there_winners?(map) :: map
  def is_there_winners?(%{"players" => players} = state) do
    winners = Enum.filter(players, &won?/1)

    is_there_winners?(winners, state)
  end

  @spec is_there_winners?(list(Player.t()), any) :: any
  def is_there_winners?([], %{"players" => players} = state) do
    winners =
      players
        |> set_players_final_value()
        |> players_close_to_21()

    Map.put(state, "winners", winners)
  end

  def is_there_winners?(winners, state) do
    state
    |> Map.put("winners", winners)
  end

  @spec won?(Player.t()) :: boolean
  def won?(%Player{total: total}) when is_tuple(total) do
    21 in Tuple.to_list(total)
  end

  def won?(%Player{total: total}) when total == 21, do: true
  def won?(_), do: false

  def last(%Player{} = player) do
    %Player{player | isLast: true}
  end

  def set_next_player(%{"players" => players} = state, player) do
    %Player{id: player_id} = player

    found_index =
      players
      |> Enum.find_index(&(&1.id == player_id))
      |> Kernel.-(1)

    players =
      players
      |> Enum.with_index()
      |> Enum.map(fn
        {found_player, index} when index == found_index ->
          Player.set_turn(found_player, true)

        {player, _} ->
          player
      end)

    Map.put(state, "players", players)
  end

  def set_players_final_value([%Player{burned: true} | players]) do
    [[] | set_players_final_value(players)]
  end

  def set_players_final_value([%Player{total: total, burned: false} = player | players]) when is_tuple(total) do
    total = Tuple.to_list(total)

    total =
      total
      |> Enum.map(fn (total)->  21 - total end)
      |> Enum.reduce(21, fn
        (value, acc) when value <= acc ->
          value
        (_value, acc) ->
          acc
      end)

    [{player, total} | set_players_final_value(players)]
  end

  def set_players_final_value([%Player{total: total} = player | players]) when is_integer(total) do
    [{player, 21 - total} | set_players_final_value(players)]
  end
  def set_players_final_value([]), do: []

  def players_close_to_21(final_values)
    when is_list(final_values) and length(final_values) > 0
    do
      minor_value =
        final_values
          |> List.flatten()
          |> find_minor_value()

      Enum.filter(final_values, fn
          ({_, total}) -> total == minor_value
          ([]) -> nil
        end)
      |> map_winners
  end

  def players_close_to_21(_), do: nil

  defp map_winners([]), do: nil

  defp map_winners(winners) do
    Enum.map(winners, fn ({player, _}) -> player end)
  end

  defp find_minor_value(final_values)
    when length(final_values) > 0
    do
      Enum.reduce(final_values, nil, fn (total, acc) -> filter_minor(total, acc) end)
  end

  defp find_minor_value([]), do: nil

  defp filter_minor([], _), do: nil

  defp filter_minor({_, value}, acc) when is_nil(acc) do
    value
  end

  defp filter_minor({_, value}, acc) when acc <= value do
    acc
  end

  defp filter_minor({_, value}, acc) when acc > value do
    value
  end
end
