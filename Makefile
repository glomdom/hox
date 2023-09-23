TARGET = hox
SRC = $(wildcard src/*.lua)

all: build

install: build
	cp -vr $(TARGET) /usr/local/bin

build: $(SRC)
	luastatic hox.lua $^ /usr/lib/liblua.so.5.4.6