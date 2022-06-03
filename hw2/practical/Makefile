CC=gcc
CFLAGS=-Wextra -Werror
SRC=$(wildcard *.c)
EXECUTABLE=$(SRC:.c=)

all: $(EXECUTABLE)

debug: CFLAGS += -DDEBUG
debug: all

$(EXECUTABLE): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(EXECUTABLE)
