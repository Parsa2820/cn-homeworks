import random

from .player import Player
from ..board import Board, BoardCoordinates


class BotPlayer(Player):
    def __init__(self, xo):
        super().__init__("Bot", xo)

    def ask_for_move(self, board: Board, all_chats: list):
        return self.__get_random_empty_cell(board)

    def send_message(self, message):
        return

    def __get_random_empty_cell(self, board: Board) -> BoardCoordinates:
        empty_cells = []
        for row in range(Board.SIZE):
            for col in range(Board.SIZE):
                if board.board[row][col] == Board.EMPTY:
                    empty_cells.append((row, col))
        random_cell = empty_cells[random.randint(0, len(empty_cells) - 1)]
        return BoardCoordinates.from_tuple(random_cell)
