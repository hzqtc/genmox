CC=clang
CFLAGS=-fobjc-arc
LDFLAGS=-framework Cocoa

SRC = $(wildcard *.m)
OBJ = $(SRC:.m=.o)
TARGET = genmox

all: $(TARGET)

debug: CFLAGS += -g
debug: $(TARGET)

release: CFLAGS += -O2
release: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $^ -o $(TARGET)

%.o: %.m
	$(CC) $(CFLAGS) -c $^

.PHONY:
clean:
	-rm -f *.o
