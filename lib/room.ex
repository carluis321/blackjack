defmodule Room do
  use GenServer

  def create_room() do
    deck = Deck.shuffle()

    state = %{"game" => :wait, "players" => [], "deck" => deck, "winners" => nil, "errors" => []}

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def start_game(room) do
    GenServer.cast(room, {:start})
  end

  def get_game_status(room) do
    GenServer.call(room, {:getStatusGame})
  end

  def join(room, player) do
    GenServer.call(room, {:join, player})
  end

  @spec action(atom | pid | {atom, any} | {:via, atom, any}, Player.t(), atom()) :: any
  def action(room, %Player{turn: true} = player, action) do
    GenServer.call(room, {:play, player, action})
  end

  def get_players(room) do
    GenServer.call(room, {:getPlayers})
    |> Enum.reverse()
  end

  def get_winners(room) do
    GenServer.call(room, {:getWinners})
  end

  def handle_call({:join, player}, _from, %{"players" => players} = state) do
    case length(players) do
      # TODO: value from enviroment
      3 ->
        {:reply, {:err, "room full"}, state}

      _ ->
        new_players = [player | players]
        new_state = Map.put(state, "players", new_players)
        {:reply, {:ok, "joined"}, new_state}
    end
  end

  def handle_call({:getStatusGame}, _, %{"game" => game} = state) do
    {:reply, game, state}
  end

  def handle_call({:getPlayers}, _, %{"players" => players} = state) do
    {:reply, players, state}
  end

  def handle_call({:play, %Player{isLast: true}= player, action}, _, %{"game" => :started} = state) do
    new_state =
      state
      |> Player.action(player, action)
      |> Blackjack.is_game_finished?()

    %{"players" => players} = new_state

    player = Enum.find(players, &(player.id == &1.id))

    {:reply, player, new_state}
  end

  def handle_call({:play, player, action}, _, %{"game" => :started} = state) do
    new_state = Player.action(state, player, action)

    %{"players" => players} = new_state

    player = Enum.find(players, &(player.id == &1.id))

    {:reply, player, new_state}
  end

  def handle_call({:getWinners}, _, %{"winners" => winners} = state) do
    {:reply, winners, state}
  end

  def handle_cast({:start}, %{"players" => players, "deck" => deck} = state) do
    {players, new_deck} =
      players
      |> Enum.reverse()
      |> Enum.reduce({}, fn player, acc ->
        case acc do
          {} ->
            {cards, deck} = Deck.take(deck, 2)

            modified_player =
              player
              |> Player.set_turn(true)
              |> Player.add_hand(cards)

            {[modified_player], deck}

          {players, deck} ->
            {cards, deck} = Deck.take(deck, 2)

            modified_player = Player.add_hand(player, cards)

            {[modified_player | players], deck}
        end
      end)

    new_state =
      state
      |> Map.put("game", :started)
      |> Map.put("players", last_player(players))
      |> Map.put("deck", new_deck)

    {:noreply, new_state}
  end

  defp last_player([last_player | players]) do
    [%Player{last_player | isLast: true} | players]
  end
end
