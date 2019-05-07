all: libccanjson.so libccanjson.a

clean:
	rm -f libccanjson.so libccanjson.a

install:
	mkdir -p /usr/local/include/ccan/json
	cp json.h /usr/local/include/ccan/json
	cp libccanjson.so /usr/local/lib/
	ldconfig

libccanjson.so: json.h json.c
	gcc -Wall -shared -fPIC -O -o libccanjson.so json.c
libccanjson.a: json.h json.c
	gcc -Wall -c -O -o libccanjson.o json.c
	ar rs libccanjson.a libccanjson.o
	rm libccanjson.o
