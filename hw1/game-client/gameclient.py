import socket


class GameClient:
    def __init__(self, web_server_address, web_server_port):
        self.web_server_address = web_server_address
        self.web_server_port = web_server_port

    def run(self):
        