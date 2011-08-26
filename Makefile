INCLUDE=-I/usr/include/lua5.1/
LDFLAGS=-llua5.1
CFLAGS=-Wall -Werror

# XENOMAI BUILD
ifneq ($(XENO),)

### Default Xenomai installation path
XENO ?= /usr/xenomai
# XENOCONFIG=$(shell PATH=$(XENO):$(XENO)/bin:$(PATH) which xeno-config 2>/dev/null)
XENOCONFIG=$(shell PATH=$(XENO):$(XENO)/bin:$(PATH) which xeno-config)

### Sanity check
ifeq ($(XENOCONFIG),)
all:
	@echo ">>> Invoke make like this: \"make XENO=/path/to/xeno-config\" <<<"
	@echo
endif

CC=$(shell $(XENOCONFIG) --cc)
CFLAGS+=$(shell $(XENOCONFIG) --skin=posix --cflags)
LDFLAGS+=-Xlinker -rpath -Xlinker $(shell $(XENOCONFIG) --skin=posix --libdir)
LDFLAGS+=$(shell $(XENOCONFIG) --skin=posix --ldflags)

else
CC=$(CROSS_COMPILE)gcc
CFLAGS+=-pthread -lrt
LDFLAGS+=-lrt -lpthread
endif

all: rtposix.so

rtposix.o: rtposix.c
	${CC} ${CFLAGS} ${INCLUDE} -fpic -c rtposix.c -o $@

rtposix.so: rtposix.o
	${CC} -shared ${LDFLAGS} -llua5.1 rtposix.o -o rtposix.so
###	${CC} ${CFLAGS} -shared ${INCLUDE} ${LDFLAGS} ${LIBS} rtposix.o -o rtposix.so

clean:
	rm -f *.o *.so *~
