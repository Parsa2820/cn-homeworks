CC=gcc
CFLAGS=-Wextra -Werror

all: a b c

debug: CFLAGS += -DDEBUG -g
debug: all

a:
	$(CC) $(CFLAGS) -o a a.c

b:
	$(CC) $(CFLAGS) -o b b.c

c:
	$(CC) $(CFLAGS) -o c c.c

clean:
	rm -f a b c
