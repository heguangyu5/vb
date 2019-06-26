libccanjson.a: json.h json.c
	gcc -Wall -c -O -o libccanjson.o json.c
	ar rs libccanjson.a libccanjson.o
	rm libccanjson.o

install:
	mkdir -p /usr/local/include/ccan/json
	cp json.h /usr/local/include/ccan/json
	ldconfig
