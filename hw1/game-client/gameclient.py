import socket


class GameClient:
    def __init__(self, web_server_address, web_server_port):
        self.address = web_server_address
        self.port = web_server_port

    def run(self):
        game_menu_message = """
        (In any menu you can type 'exit' to leave the game)
        Select an option:
        1. Play with bot
        2. Play with another player
        """
        mode = input(game_menu_message)
        if mode == '1':
            self.__play("bot")
        elif mode == '2':
            self.__play("multiplayer")
        elif mode == "exit":
            print('Bye!')
            exit(0)
        else:
            print('Invalid option!')
            self.run()

    def __play(self, mode):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((self.address, self.port))
        try:
            s.send(f"find_game_server {mode}".encode("utf-8"))
            print(s.recv(1024).decode("utf-8"))
            print(s.recv(1024).decode("utf-8"))
            while True:
                data = s.recv(1024)
                print(data.decode())
                if not data:
                    break
                msg = input('> ')
                s.send(msg.encode())
                if msg == 'exit':
                    break
        except Exception as e:
            print(f"Error: {e}")
        finally:
            s.close()
