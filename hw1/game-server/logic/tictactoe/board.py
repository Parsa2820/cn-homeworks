from dataclasses import dataclass


@dataclass
class BoardCoordinates:
    row: int
    col: int

    def from_tuple(input: tuple):
        return BoardCoordinates(input[0], input[1])

    def from_str(input: str):
        splitted = input.split(',')
        return BoardCoordinates(int(splitted[0].strip()), int(splitted[1].strip()))

    def __str__(self):
        return f"{self.row},{self.col}"


class Board:
    SIZE = 3
    EMPTY = ' '

    def __init__(self) -> None:
        self.board = [[Board.EMPTY for _ in range(Board.SIZE)]
                      for _ in range(Board.SIZE)]

    def move(self, coord: BoardCoordinates, player_xo) -> None:
        if self.__validate_move(coord):
            self.board[coord.row][coord.col] = player_xo.value
        else:
            raise InvalidMoveException(coord)

    def is_full(self) -> bool:
        for row in self.board:
            for cell in row:
                if cell == Board.EMPTY:
                    return False
        return True

    def has_winner(self) -> bool:
        return self.__has_winner_row() \
            or self.__has_winner_col() \
            or self.__has_winner_diagonal()

    def __has_winner_row(self) -> bool:
        return self.__has_winner_row_aux(self.board)

    def __has_winner_col(self) -> bool:
        return self.__has_winner_row_aux(zip(*self.board))

    def __has_winner_row_aux(self, board):
        for row in board:
            if row[0] == Board.EMPTY:
                continue
            if all(map(lambda x: x == row[0], row)):
                return True
        return False

    def __has_winner_diagonal(self) -> bool:
        main_diagonal_value = self.board[0][0]
        main_diagonal = True
        secondary_diagonal_value = self.board[0][Board.SIZE - 1]
        secondary_diagonal = True
        if main_diagonal_value == Board.EMPTY:
            main_diagonal = False
        if secondary_diagonal_value == Board.EMPTY:
            secondary_diagonal = False
        for row in range(Board.SIZE):
            if self.board[row][row] != main_diagonal_value:
                main_diagonal = False
            if self.board[row][Board.SIZE - row - 1] != secondary_diagonal_value:
                secondary_diagonal = False
        return main_diagonal or secondary_diagonal

    def __validate_move(self, coord: BoardCoordinates) -> bool:
        if self.board[coord.row][coord.col] != Board.EMPTY:
            return False
        return 0 <= coord.row < Board.SIZE and 0 <= coord.col < Board.SIZE

    def __str__(self) -> str:
        sep = '\n' + '- ' * (Board.SIZE) + '\n'
        return sep.join(['|'.join(row) for row in self.board])


class InvalidMoveException(Exception):
    def __init__(self, coord: BoardCoordinates) -> None:
        self.message = f"Invalid move: {coord}"
