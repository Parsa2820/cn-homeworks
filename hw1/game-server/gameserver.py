import logging
import socket
import re

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
        self.__register_game_server(web_server_address, web_server_port)

    def run(self):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.bind(("", self.game_server_port))
        self.s.listen(5)
        self.logger.info("Game server started on port %d", self.game_server_port)
        self.__listen_for_connection()

    def __register_game_server(self, web_server_address, web_server_port):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.connect((web_server_address, web_server_port))
            message = f"register_game_server {self.game_server_port}"
            s.sendall(message.encode())
            acknowledge = s.recv(self.BUFFER_SIZE)
            if acknowledge.decode().strip().lower() != "ok":
                self.logger.error("Failed to register")
                exit(1)
            else:
                self.logger.info("Game server registered with the web server")
        except ConnectionRefusedError:
            self.logger.error("Failed to connect to the web server")
            exit(1)
        finally:
            s.close()

    def __listen_for_connection(self):
        while True:
            conn, addr = self.s.accept()
            self.logger.info("Connection from %s", addr)
            data = conn.recv(GameServer.BUFFER_SIZE)
            if not data:
                continue
            command = data.decode("utf-8").strip()
            self.logger.debug("Received data: %s", command)
            if GameServer.START_GAME_PATTERN.match(command):
                self.__start_game(conn, addr, command)
            else:
                conn.sendall(b"Unknown command\nBye\n")
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
        bot = BotPlayer(PlayerXO.X)
        onlinePlayer = OnlinePlayer(addr, PlayerXO.O, conn, addr)
        game = TicTacToe(bot, onlinePlayer)
        self.__play_game(game)

    def __start_with_multiplayer(self, conn, addr):
        # # wait for other player to connect
        # conn.sendall(b"Waiting for other player to connect ...\n")
        # conn2, addr2 = self.s.accept()
        # conn.sendall(b"Other player connected\n")
        # player1 = Player(addr, PlayerXO.X)
        # player2 = Player(addr2, PlayerXO.O)
        # game = Game(player1, player2)
        # self.__play_game(game)
        pass

    def __play_game(self, game: TicTacToe):
        while True:
            try:
                try:
                    game.play(game.player_x.ask_for_move(game.board))
                except InvalidMoveException as e:
                    game.player_x.send_message(e.message)
                    return
                try:
                    game.play(game.player_o.ask_for_move(game.board))
                except InvalidMoveException as e:
                    game.player_o.send_message(e.message)
                    return
            except GameOverException as e:
                game.player_x.send_message(game.board)
                game.player_x.send_message(e.message)
                game.player_o.send_message(game.board)
                game.player_o.send_message(e.message)
                return
