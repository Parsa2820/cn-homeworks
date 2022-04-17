from dataclasses import dataclass
from http import server
import logging
from socket import socket
import sys
from threading import Thread
import re
from queue import Queue

class WebServer:
    BUFFER_SIZE = 1024
    REGISTER_GAME_SERVER_PATTERN = re.compile(r"^register_game_server\s+(?P<listen_port>\d+)$")
    FIND_GAME_SERVER_PATTERN = re.compile(r"^find_game_server\s+(?P<mode>bot|multiplayer)$")

    def __init__(self, port) -> None:
        self.port = port
        self.logger = logging.getLogger("WebServer")
        self.free_game_servers = Queue()
        self.games = []

    def run(self) -> None:
        self.logger.info("Starting web server on port %d", self.port)
        shell_thread = Thread(target=self.__shell)
        shell_thread.start()
        while True:
            sock = socket()
            sock.bind(("", self.port))
            sock.listen(5)
            conn, addr = sock.accept()
            self.logger.info("Connection from %s", addr)
            thread = Thread(target=self.__handle_connection, args=(conn, addr))
            thread.start()

    def __shell(self):
        command = input(">> ")
        while command != "exit":
            if command == "users":
                print(self.__count_users())
            else:
                print("Unknown command")
            command = input(">> ")
        sys.exit(0)

    def __count_users(self):
        return 0

    def __handle_connection(self, conn, addr):
        try:
            data = conn.recv(self.BUFFER_SIZE)
            if not data:
                return
            self.logger.debug("Received data: %s", data.decode("utf-8"))
            command = data.decode("utf-8").strip()
            if WebServer.REGISTER_GAME_SERVER_PATTERN.match(command):
                self.__register_game_server(conn, addr, command)
            elif WebServer.FIND_GAME_SERVER_PATTERN.match(command):
                self.__find_game_server(conn, addr, command)
            else:
                conn.sendall(b"Unknown command\n")
        except Exception as e:
            self.logger.error("Error: %s", e)
        finally:
            conn.close()

    def __register_game_server(self, conn, addr, command):
        match = WebServer.REGISTER_GAME_SERVER_PATTERN.match(command)
        listen_port = int(match.group("listen_port"))
        self.free_game_servers.put(GameServerInfo(addr, listen_port))
        conn.sendall(b"OK\n")
        self.logger.info("Game server registered: %s", addr)

    def __find_game_server(self, conn, addr, command):
        match = WebServer.FIND_GAME_SERVER_PATTERN.match(command)
        mode = match.group("mode")
        if mode == "bot":
            self.__find_bot_game_server(conn, addr)
        elif mode == "multiplayer":
            self.__find_multiplayer_game_server(conn, addr)
        else:
            conn.sendall(b"Unknown mode\n")

    def __find_bot_game_server(self, client_conn, addr):
        client_conn.sendall(b"Waitinng for free game server\n")
        gs = self.free_game_servers.get(block=True)
        client_conn.sendall(b"Game server found!\n")
        server_conn = socket()
        server_conn.connect((gs.addr, gs.listen_port))
        server_conn.sendall(b"start_game bot\n")
        self.games.append(Game(client_conn, server_conn))
        server_response = server_conn.recv(self.BUFFER_SIZE).decode("utf-8").strip()
        while server_response and not server_response.startswith("game over"):
            client_conn.sendall(server_response)
            client_response = client_conn.recv(self.BUFFER_SIZE).decode("utf-8").strip()
            server_conn.sendall(client_response)
            server_response = server_conn.recv(self.BUFFER_SIZE).decode("utf-8").strip()
        client_conn.sendall(server_response)
        server_conn.close()
        self.games.remove(Game(client_conn, server_conn))
        self.free_game_servers.put(gs)

    def __find_multiplayer_game_server(self, client_conn, addr):
        pass
        
@dataclass
class GameServerInfo:
    addr: tuple
    listen_port: int

@dataclass
class Game:
    client_conn: socket
    server_conn: socket