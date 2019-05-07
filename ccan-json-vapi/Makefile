all: libccanjson.so libccanjson.a libccanjson-glib.so libccanjson-glib.a

clean:
	rm -f libccanjson.so libccanjson.a libccanjson-glib.so libccanjson-glib.a

install:
	mkdir -p /usr/local/include/ccan/json
	cp json.h /usr/local/include/ccan/json
	cp libccanjson.so libccanjson-glib.so /usr/local/lib/
	ldconfig

libccanjson.so: json.h json.c
	gcc -Wall -shared -fPIC -O -o libccanjson.so json.c
libccanjson.a: json.h json.c
	gcc -Wall -c -O -o libccanjson.o json.c
	ar rs libccanjson.a libccanjson.o
	rm libccanjson.o
libccanjson-glib.so: json.h json.c
	gcc -Wall -shared -fPIC -O -DUSE_GLIB `pkg-config --cflags glib-2.0` -o libccanjson-glib.so json.c `pkg-config --libs glib-2.0`
libccanjson-glib.a: json.h json.c
	gcc -Wall -c -O -DUSE_GLIB `pkg-config --cflags glib-2.0` -o libccanjson-glib.o json.c
	ar rs libccanjson-glib.a libccanjson-glib.o
	rm libccanjson-glib.o
