import sys
import getopt

from gameserver import GameServer


def main(argv):
    help_message = '''
    Usage:
        python3 main.py -p <port>
    '''
    port = 8585
    try:
        opts, _ = getopt.getopt(argv, "hp:", ["help", "port="])
    except getopt.GetoptError:
        print(help_message)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(help_message)
            sys.exit()
        elif opt in ("-p", "--port"):
            port = int(arg)
    gs = GameServer(port)
    gs.run()


if __name__ == "__main__":
    main(sys.argv[1:])
