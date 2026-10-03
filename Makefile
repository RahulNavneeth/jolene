UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
ALSA_LIBS := $(shell pkg-config --libs alsa) -lpthread -lm
endif

ifeq ($(UNAME_S),Darwin)
ALSA_LIBS := -framework AudioToolbox -framework CoreAudio -framework CoreFoundation
# Inside a nix shell, SDKROOT points at the nix apple-sdk; tell zig to look there.
ifdef SDKROOT
ALSA_LIBS += --sysroot $(SDKROOT) -F$(SDKROOT)/System/Library/Frameworks
endif
endif

echoes:
	@ cd echoes-driver && bash ./build.sh

deps: echoes

build: deps
	@ zig build-exe main.zig -Iechoes-driver/include -Lechoes-driver/build -lechoes -lc $(ALSA_LIBS)

run: build
	@ ./main
