import logging
import socket
import re
import threading

from logic.tictactoe.game import TicTacToe, GameOverException
from logic.tictactoe.palyer.player import PlayerXO
from logic.tictactoe.palyer.online import OnlinePlayer
from logic.tictactoe.palyer.bot import BotPlayer
from logic.tictactoe.board import InvalidMoveException


class GameServer:
    START_GAME_PATTERN = re.compile(r"^start_game\s+(?P<mode>bot|multiplayer)$")

    def __init__(self, web_server_address, web_server_port, game_server_port):
        self.logger = logging.getLogger("GameServer")
        self.game_server_port = game_server_port
        self.web_server_address = web_server_address
        self.web_server_port = web_server_port

    def run(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(("", self.game_server_port))
        s.listen(5)
        self.logger.info("Game server started on port %d", self.game_server_port)
        threading.Thread(target=self.__listen_for_connection, args=(s,), daemon=True).start()
        self.__register_game_server(self.web_server_address, self.web_server_port)
        while True:
            try:
                _ = input()
            except KeyboardInterrupt:
                self.logger.info("Game server stopped")
                s.close()
                exit(0)

    def __register_game_server(self, web_server_address, web_server_port):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.connect((web_server_address, web_server_port))
            message = f"register_game_server {self.game_server_port}"
            s.sendall(message.encode("utf-8"))
            acknowledge = s.recv(1024)
            if acknowledge.decode("utf-8").strip().lower() != "ok":
                self.logger.error("Failed to register")
                exit(1)
            else:
                self.logger.info("Game server registered with the web server")
        except Exception as e:
            self.logger.error("Failed to register: %s", e)
            exit(1)
        finally:
            s.close()

    def __listen_for_connection(self, s):
        while True:
            conn, addr = s.accept()
            self.logger.info("Connection from %s", addr)
            try:
                data = conn.recv(1024)
                if not data:
                    continue
                command = data.decode("utf-8").strip()
                self.logger.debug("Received data '%s' from %s", command, addr)
                if GameServer.START_GAME_PATTERN.match(command):
                    self.__start_game(conn, addr, command)
                else:
                    conn.sendall("Unknown command".encode("utf-8"))
            except Exception as e:
                self.logger.error("Failed to process request: %s", e)
            finally:
                conn.close()

    def __start_game(self, conn, addr, command):
        m = GameServer.START_GAME_PATTERN.match(command)
        mode = m.group("mode")
        if mode == "bot":
            self.__start_with_bot(conn, addr)
        elif mode == "multiplayer":
            self.__start_with_multiplayer(conn, addr)
        else:
            conn.sendall("Unknown mode".encode("utf-8"))

    def __start_with_bot(self, conn, addr):
        onlinePlayer = OnlinePlayer(addr, PlayerXO.X, conn, addr)
        bot = BotPlayer(PlayerXO.O)
        game = TicTacToe(onlinePlayer, bot)
        game.start()

    def __start_with_multiplayer(self, conn, addr):
        pass
