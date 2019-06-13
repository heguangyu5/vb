lmdb-wrapper.a: lmdb-wrapper.c lmdb-wrapper.h
	gcc -Wall -c -O -o lmdb-wrapper.o lmdb-wrapper.c
	ar rs lmdb-wrapper.a lmdb-wrapper.o
	rm lmdb-wrapper.o
install:
	cp lmdb-wrapper.h /usr/local/include/
