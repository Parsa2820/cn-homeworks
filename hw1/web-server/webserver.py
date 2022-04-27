from dataclasses import dataclass
import logging
from socket import socket
import sys
from threading import Thread
import re
from queue import Queue

class WebServer:
    REGISTER_GAME_SERVER_PATTERN = re.compile(r"^register_game_server\s+(?P<listen_port>\d+)$")
    FIND_GAME_SERVER_PATTERN = re.compile(r"^find_game_server\s+(?P<mode>bot|multiplayer)$")

    def __init__(self, port) -> None:
        self.logger = logging.getLogger("WebServer")
        self.port = port
        self.free_game_servers = Queue()
        self.number_of_players = 0

    def run(self) -> None:
        self.logger.info("Starting web server on port %d", self.port)
        listener_thread = Thread(target=self.__listen_for_connection, daemon=True)
        listener_thread.start()
        self.__shell()

    def __shell(self):
        command = input(">> ")
        while command != "exit":
            if command == "users":
                print(self.number_of_players)
            else:
                print("Unknown command")
            command = input(">> ")
        sys.exit(0)

    def __listen_for_connection(self):
        sock = socket()
        sock.bind(("", self.port))
        sock.listen(5)
        while True:
            conn, addr = sock.accept()
            self.logger.info("Connection from %s", addr)
            thread = Thread(target=self.__handle_connection, args=(conn, addr), daemon=True)
            thread.start()

    def __handle_connection(self, conn: socket, addr):
        try:
            data = conn.recv(1024)
            if not data:
                return
            self.logger.debug("Received data '%s' from %s", data.decode("utf-8"), addr)
            command = data.decode("utf-8").strip()
            if WebServer.REGISTER_GAME_SERVER_PATTERN.match(command):
                self.__register_game_server(conn, addr, command)
            elif WebServer.FIND_GAME_SERVER_PATTERN.match(command):
                self.__find_game_server(conn, addr, command)
            else:
                conn.sendall("Unknown command".encode("utf-8"))
        except Exception as e:
            self.logger.error("Error handling connection from %s: %s", addr, e)
        finally:
            conn.close()
            self.logger.info("Connection from %s closed", addr)

    def __register_game_server(self, conn, addr, command):
        match = WebServer.REGISTER_GAME_SERVER_PATTERN.match(command)
        listen_port = int(match.group("listen_port"))
        self.free_game_servers.put(GameServerInfo(addr[0], listen_port))
        conn.sendall("OK".encode("utf-8"))
        self.logger.info("Game server registered: %s", addr)

    def __find_game_server(self, conn, addr, command):
        match = WebServer.FIND_GAME_SERVER_PATTERN.match(command)
        mode = match.group("mode")
        if mode == "bot":
            self.__find_bot_game_server(conn, addr)
        elif mode == "multiplayer":
            self.__find_multiplayer_game_server(conn, addr)
        else:
            conn.sendall("Unknown mode".encode("utf-8"))

    def __find_bot_game_server(self, client_conn, addr):
        self.number_of_players += 1
        client_conn.sendall("Waitinng for free game server".encode("utf-8"))
        gs = self.free_game_servers.get(block=True)
        client_conn.sendall("Game server found!".encode("utf-8"))
        server_conn = socket()
        server_conn.connect((gs.addr, gs.listen_port))
        server_conn.sendall("start_game bot".encode("utf-8"))
        self.logger.info("Game started between %s and %s", addr, gs)
        try:
            while True:
                data = server_conn.recv(1024)
                if not data:
                    break
                client_conn.sendall(data)
                client_response = client_conn.recv(1024)
                if not client_response:
                    break
                server_conn.sendall(client_response)
        except Exception as e:
            self.logger.error("Error handling connection from %s: %s", addr, e)
        finally:
            server_conn.close()
            self.logger.info("Game between %s and %s finished", addr, gs)
            self.number_of_players -= 1
            self.free_game_servers.put(gs)

    def __find_multiplayer_game_server(self, client_conn, addr):
        pass
        
@dataclass
class GameServerInfo:
    host_addr: str
    listen_port: int

    __str__ = lambda self: f"{self.host_addr}:{self.listen_port}"
