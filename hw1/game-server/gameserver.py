import logging
import socket
import re

from .logic.tictactoe.game import Game, GameOverException
from .logic.tictactoe.player import Player, PlayerXO
from .logic.tictactoe.board import Board, BoardCoordinates, InvalidMoveException

class GameServer:
    BUFFER_SIZE = 1024
    START_GAME_PATTERN = re.compile(r"^start_game\s+(?P<mode>bot|multiplayer)$")
    def __init__(self, web_server_address, web_server_port, game_server_port):
        self.web_server_address: str = web_server_address
        self.web_server_port: int = web_server_port
        self.game_server_port: int = game_server_port
        self.logger = logging.getLogger("GameServer")

    def run(self):
        # self.__register_game_server()
        self.__listen_for_connections()

    def __register_game_server(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((self.web_server_address, self.web_server_port))

    def __listen_for_connection(self):
        s = s.socket(s.AF_INET, s.SOCK_STREAM)
        s.bind(('localhost', self.game_server_port))
        s.listen(5)
        while True:
            conn, addr = s.accept()
            self.logger.info("Connection from %s", addr)
            data = conn.recv(GameServer.BUFFER_SIZE)
            if not data:
                break
            command = data.decode("utf-8").strip()
            self.logger.debug("Received data: %s", command)
            if GameServer.START_GAME_PATTERN.match(command):
                self.__start_game(conn, addr, command)
            else:
                conn.sendall(b"Unknown command\n")
        conn.close()

    def __start_game(self, conn, addr, command):
        m = GameServer.START_GAME_PATTERN.match(command)
        mode = m.group("mode")
        if mode == "bot":
            self.__start_with_bot(conn, addr)
        elif mode == "multiplayer":
            self.__start_with_multiplayer(conn, addr)
        else:
            conn.sendall(b"Unknown mode\n")

    def __start_with_bot(self, conn, addr):
        player = Player(addr, PlayerXO.X)
        game = Game(player, Player("Bot", PlayerXO.O))
        while True:
            try:
                try:                    
                    game.play(self.__ask_for_move(player, conn, addr))
                except InvalidMoveException as e:
                    conn.sendall((e.message + "").encode("utf-8"))

            except GameOverException:
                break