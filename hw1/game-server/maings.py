import sys
import getopt
import logging

from gameserver import GameServer


def main(argv):
    help_message = '''
    Usage:
        python3 main.py -p <port> -a <web_server_address> -q <web_server_port>
    '''
    port = 8586
    web_server_address = "localhost"
    web_server_port = 8585
    try:
        opts, _ = getopt.getopt(argv, "hp:a:q:", ["help", "port=", "address=", "qort="])
    except getopt.GetoptError:
        print(help_message)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(help_message)
            sys.exit()
        elif opt in ("-p", "--port"):
            port = int(arg)
        elif opt in ("-a", "--address"):
            web_server_address = arg
        elif opt in ("-q", "--qort"):
            web_server_port = int(arg)
    gs = GameServer(web_server_address, web_server_port, port)
    gs.run()


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    main(sys.argv[1:])
