CC=gcc
CFLAGS=-lrt -Wall
#INCLUDES=$(shell lua-config --include) 
#LIBS=$(shell lua-config --libs)
INCLUDE=-I/usr/include/lua5.1/
# LIBS=-llua

all: rtposix.so

rtposix.o: rtposix.c
	${CC} ${CFLAGS} ${INCLUDE} -fpic -c rtposix.c -o $@

rtposix.so: rtposix.o
	${CC} ${CFLAGS} -shared ${INCLUDES} ${LIBS} rtposix.o -o rtposix.so

clean:
	rm -f *.o rtposix.o *.so *~

# gcc -I/usr/include/lua -c min.c -o min.o
# gcc -I/usr/include/lua -c example_wrap.c -o example_wrap.o
# gcc -c example.c -o example.o
# gcc -I/usr/include/lua -L/usr/lib/lua min.o example_wrap.o example.o -o my_lua
