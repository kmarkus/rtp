LUA_VERSION=lua5.2
INCLUDE=-I/usr/include/${LUA_VERSION}
LDFLAGS=-l${LUA_VERSION}
CFLAGS=-Wall -Werror

# XENOMAI BUILD
ifneq ($(XENO),)

### Default Xenomai installation path
XENO ?= /usr/xenomai
XENOCONFIG=$(shell PATH=$(XENO):$(XENO)/bin:$(PATH) which xeno-config)

### Sanity check
ifeq ($(XENOCONFIG),)
all:
	@echo ">>> Invoke make like this: \"make XENO=/path/to/xeno-config\" <<<"
	@echo
endif

CC=$(CROSS_COMPILE)$(shell $(XENOCONFIG) --cc)
CFLAGS+=$(shell $(XENOCONFIG) --skin=posix --cflags)
LDFLAGS+=-Xlinker -rpath -Xlinker $(shell $(XENOCONFIG) --skin=posix --libdir)
LDFLAGS+=$(shell $(XENOCONFIG) --skin=posix --ldflags)

else
# GNU/Linux build
CC=$(CROSS_COMPILE)gcc
CFLAGS+=-pthread -lrt
LDFLAGS+=-lrt -lpthread
endif

all: rtp.so

rtp.o: rtp.c
	${CC} ${CFLAGS} ${INCLUDE} -fpic -c rtp.c -o $@

rtp.so: rtp.o
	${CC} -shared ${LDFLAGS} rtp.o -o rtp.so

docs:
	luadoc --nofiles -d htmldoc/ .

clean:
	rm -rf *.o *.so *~ *~ core htmldoc
