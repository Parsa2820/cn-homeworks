from abc import ABC, abstractmethod
from enum import Enum

from ..board import Board, BoardCoordinates


class PlayerXO(Enum):
    X = 'X'
    O = 'O'

    def turn(self):
        if self.value == 'X':
            return PlayerXO.O
        else:
            return PlayerXO.X


class Player(ABC):
    def __init__(self, name, xo):
        self.name = name
        self.xo = xo

    @abstractmethod
    def ask_for_move(self, board: Board) -> BoardCoordinates:
        pass

    @abstractmethod
    def send_message(self, message):
        pass
