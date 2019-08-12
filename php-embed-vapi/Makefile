lib-0-phpembed.a: php-embed.h php-embed.c
	gcc -I$(PHP_INCLUDE_PATH) \
	    -I$(PHP_INCLUDE_PATH)/main \
	    -I$(PHP_INCLUDE_PATH)/Zend \
	    -I$(PHP_INCLUDE_PATH)/TSRM \
	    -Wall -O -c php-embed.c
	ar rs lib-0-phpembed.a *.o
	rm *.o

install:
	cp php-embed.h /usr/local/include/
