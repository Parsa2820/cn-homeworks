from enum import Enum


class PlayerXO(Enum):
    X = 'X'
    O = 'O'

    def turn(self):
        if self.value == 'X':
            return PlayerXO.O
        else:
            return PlayerXO.X


class Player:
    def __init__(self, name, xo):
        self.name = name
        self.xo = xo
