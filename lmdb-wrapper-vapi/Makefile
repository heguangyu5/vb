lmdb-wrapper.a: lmdb-wrapper.c lmdb-wrapper.h lmdb-zzz.a
	gcc -Wall -c -O -o lmdb-wrapper.o lmdb-wrapper.c
	ar rs lmdb-wrapper.a lmdb-wrapper.o
	rm lmdb-wrapper.o
lmdb-zzz.a:
	tar zxf lmdb-LMDB_0.9.22.tar.gz
	make -C lmdb-LMDB_0.9.22/libraries/liblmdb liblmdb.a
	mv lmdb-LMDB_0.9.22/libraries/liblmdb/liblmdb.a lmdb-zzz.a
	mv lmdb-LMDB_0.9.22/libraries/liblmdb/lmdb.h .
	rm -rf lmdb-LMDB_0.9.22
install:
	cp lmdb-wrapper.h /usr/local/include/
