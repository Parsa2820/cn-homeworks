from .player import Player
from ..board import Board, BoardCoordinates, InvalidMoveException
from datetime import datetime
import logging

class OnlinePlayer(Player):
    def __init__(self, name, xo, conn, addr):
        super().__init__(name, xo)
        self.conn = conn
        self.addr = addr
        self.logger = logging.getLogger(f"OnlinePlayer({name})")

    def ask_for_move(self, board: Board, all_chats: list) -> BoardCoordinates:
        self.logger.debug("All chats: " + str(len(all_chats)))
        self.__send_board(board, all_chats)
        return self.__get_move()

    def send_message(self, message: str):
        self.conn.send(f"{message}\n".encode())

    def __send_board(self, board: Board, all_chats: list):
        chats = "chat:\n"
        chats += "\n".join(all_chats)
        chats += "\n"
        self.send_message(f"{chats}\n{board}\nPlay {self.xo.value} (e.g. 1,1)")

    def __get_move(self):
        try:
            move = self.conn.recv(1024).decode("utf-8")
            self.logger.debug(f"Got move: {move}")
            while move.startswith("chat"):
                self.chat.append(f"{self.name}({datetime.now().strftime('%H:%M:%S')}): {move[5:]}")
                move = self.conn.recv(1024).decode("utf-8")
                self.logger.debug(f"Got chat: {move}")
            self.logger.debug(f"Got move: {move}")
            return BoardCoordinates.from_str(move)
        except Exception as e:
            self.logger.error(move)
            self.logger.exception(e)
            raise InvalidMoveException("Connection lost or invalid move. Exiting...")
