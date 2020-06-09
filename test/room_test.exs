defmodule RoomTest do
  use ExUnit.Case, async: true

  test "Room test" do
    {:ok, room} = Room.create_room()

    player1 = %Player{id: 1, name: "P1"}
    player2 = %Player{id: 2, name: "P2"}
    player3 = %Player{id: 3, name: "P3"}
    player4 = %Player{id: 4, name: "P4"}

    response1 = Room.join(room, player1)

    response2 = Room.join(room, player2)

    response3 = Room.join(room, player3)

    response4 = Room.join(room, player4)

    assert {:ok, "joined"} = response1
    assert {:ok, "joined"} = response2
    assert {:ok, "joined"} = response3
    assert {:err, "room full"} = response4

    status = Room.get_game_status(room)

    assert :wait = status

    Room.start_game(room)

    status = Room.get_game_status(room)

    # [player1, player2, player3] = Room.get_players(room)

    # IO.inspect(Room.get_players(room))

    # IO.inspect(Room.get_game_status(room))

    # player1 = Room.action(room, player1, :add)

    # IO.inspect(player1)

    assert :started = status
  end

  # test "user has more than 2 aces" do
  #   player = %Player{
  #     id: 1,
  #     name: "P1",
  #     hand: [
  #       {:red, :pica, :A},
  #       {:red, :pica, 2},
  #       {:red, :pica, 2},
  #       {:red, :pica, :A},
  #     ],
  #     turn: true
  #   }

  #   IO.inspect(Player.sumTotal(player))

  #   assert 1 = 1
  # end

  test "finish game without users that have 21" do
    player1 = %Player{id: 1, name: "P1", burned: true}
    player2 = %Player{id: 2, name: "P2", total: 18}
    player3 = %Player{id: 3, name: "P3", burned: true}

    # deck = Deck.shuffle()

    # {_card, deck} = Deck.take(deck)
    # # player1 = Player.add_hand(player1, card)

    # {card, deck} = Deck.take(deck)
    # player2 = Player.add_hand(player2, card)

    # {card, _deck} = Deck.take(deck)
    # player3 = Player.add_hand(player3, card)

    players_values = Player.set_players_final_value([player1, player2, player3])

    IO.inspect(players_values)

    IO.inspect(Player.players_close_to_21(players_values))
  end
end
