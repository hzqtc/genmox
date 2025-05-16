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
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	-rm -f *.o $(TARGET)
