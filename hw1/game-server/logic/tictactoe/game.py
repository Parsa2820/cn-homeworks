from .palyer.player import Player, PlayerXO
from .board import Board, BoardCoordinates


class TicTacToe:
    def __init__(self, player_x: Player, player_o: Player) -> None:
        self.board: Board = Board()
        self.turn = PlayerXO.X
        self.winner = None
        self.game_over = False
        self.player_x: Player = player_x
        self.player_o: Player = player_o

    def play(self, coord: BoardCoordinates):
        self.board.move(coord, self.turn)
        self.__check_is_game_over()
        if self.game_over:
            raise GameOverException(self.winner)
        self.turn = self.turn.turn()

    def __check_is_game_over(self):
        if self.board.has_winner():
            self.winner = self.turn
            self.game_over = True
        elif self.board.is_full():
            self.game_over = True


class GameOverException(Exception):
    def __init__(self, winner) -> None:
        if winner is None:
            self.message = "Game is over! It's a draw!"
        else:
            self.message = "Game over! Winner is " + winner.value
        
