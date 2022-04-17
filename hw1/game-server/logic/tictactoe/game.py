from .player import Player, PlayerXO
from .board import Board, BoardCoordinates


class TicTacToe:
    def __init__(self, player_x: Player, player_o: Player) -> None:
        self.board: Board = Board()
        self.turn = PlayerXO.X
        self.winner = None
        self.game_over = False
        self.player_x = player_x
        self.player_o = player_o

    def play(self, row, col):
        self.board.move(BoardCoordinates(row, col), self.turn)
        self.__check_is_game_over()
        if self.game_over:
            raise GameOverException()
        self.turn = self.turn.turn()

    def __check_is_game_over(self):
        if self.board.has_winner():
            self.winner = self.turn
            self.game_over = True
        elif self.board.is_full():
            self.game_over = True


class GameOverException(Exception):
    def __init__(self) -> None:
        super().__init__('Game is over!')
