class GameServer:
    def __init__(self, web_server_port):
        self.web_server_port = web_server_port

    def run(self):
        print(self.web_server_port)

    def start(self):
        print("Starting game server")