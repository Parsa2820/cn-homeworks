CC=gcc
CFLAGS=-Wextra -Werror
SRC=$(wildcard *.c)
EXECUTABLE=$(SRC:.c=)

all: $(EXECUTABLE)

debug: CFLAGS += -DDEBUG -g
debug: all

$(EXECUTABLE): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(EXECUTABLE)
