UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
ALSA_LIBS := $(shell pkg-config --libs alsa) -lpthread -lm
endif

echoes:
	@ cd echoes-driver && bash ./build.sh

deps: echoes

build: deps
	@ zig build-exe main.zig -Iechoes-driver/include -Lechoes-driver/build -lechoes -lc $(ALSA_LIBS)

run: build
	@ ./main
