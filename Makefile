CC=gcc
CFLAGS=-lrt -Wall
INCLUDE=-I/usr/include/lua5.1/

all: rtposix.so

rtposix.o: rtposix.c
	${CC} ${CFLAGS} ${INCLUDE} -fpic -c rtposix.c -o $@

rtposix.so: rtposix.o
	${CC} ${CFLAGS} -shared ${INCLUDES} ${LIBS} rtposix.o -o rtposix.so

clean:
	rm -f *.o *.so *~
