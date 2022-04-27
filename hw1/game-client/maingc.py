import sys
import getopt

from gameclient import GameClient


def main(argv):
    help_message = '''
    Usage:
        python3 main.py -a <address> -p <port>
    '''
    address = 'localhost'
    port = 8585
    try:
        opts, _ = getopt.getopt(argv, "ha:p:", ["help", "address=", "port="])
    except getopt.GetoptError:
        print(help_message)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(help_message)
            sys.exit()
        elif opt in ("-a", "--address"):
            adderss = arg
        elif opt in ("-p", "--port"):
            port = int(arg)

    gc = GameClient(address, port)
    gc.run()


if __name__ == "__main__":
    main(sys.argv[1:])
