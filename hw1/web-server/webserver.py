import logging
from socket import socket
from threading import Thread

class WebServer:
    def __init__(self, port) -> None:
        self.port = port
        self.logger = logging.getLogger("WebServer")

    def run(self) -> None:
        self.logger.info("Starting web server on port %d", self.port)
