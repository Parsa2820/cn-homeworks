from .player import Player
from ..board import Board, BoardCoordinates, InvalidMoveException


class OnlinePlayer(Player):
    def __init__(self, name, xo, conn, addr):
        super().__init__(name, xo)
        self.conn = conn
        self.addr = addr

    def ask_for_move(self, board: Board) -> BoardCoordinates:
        self.__send_board(board)
        return self.__get_move()

    def send_message(self, message: str):
        self.conn.send(f"{message}\n".encode())

    def __send_board(self, board: Board):
        self.send_message(f"{board}\nPlay {self.xo.value} (e.g. 1,1)")

    def __get_move(self):
        try:
            move = self.conn.recv(1024).decode()
            return BoardCoordinates.from_str(move)
        except:
            raise InvalidMoveException("Connection lost")
