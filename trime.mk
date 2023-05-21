RIME_ROOT = $(CURDIR)

dist_dir = $(RIME_ROOT)/dist

ifdef BOOST_ROOT
CMAKE_BOOST_OPTIONS = -DBoost_DEBUG=ON \
	-DBoost_NO_BOOST_CMAKE=TRUE \
	-DBOOST_ROOT=${BOOST_ROOT} \
	-Dboost_version=${boost_version} \
	-DBoost_USE_DEBUG_LIBS=OFF \
	-DBoost_NO_SYSTEM_PATHS=ON \
	-DBoost_COMPILER=-clang \
	-DBoost_USE_STATIC_LIBS=ON \
	-DBoost_INCLUDE_DIR=$(BOOST_ROOT) \
	-DBoost_LIBRARY_DIR=$(BOOST_ROOT)/$(ARCH)/lib \
	-DCMAKE_FIND_LIBRARY_PREFIXES=lib
endif

ifdef ANDROID_ABI
ifeq ($(ARCH),x86_64)
CMAKE_BOOST_OPTIONS += -DBoost_ARCHITECTURE=-x64
endif
ifeq ($(ARCH),arm64-v8a)
CMAKE_BOOST_OPTIONS += -DBoost_ARCHITECTURE=-a64
endif
ifeq ($(ARCH),x86)
CMAKE_BOOST_OPTIONS += -DBoost_ARCHITECTURE=-x32
endif
ifeq ($(ARCH),armeabi-v7a)
CMAKE_BOOST_OPTIONS += -DBoost_ARCHITECTURE=-a32
endif
else
ifeq ($(shell uname), Darwin)
# boost::locale library from homebrew links to homebrewed icu4c libraries
icu_prefix = $(shell brew --prefix)/opt/icu4c
endif
endif

RIME_OPTIONS = -DCMAKE_BUILD_TYPE=Release -DBUILD_TEST=OFF
ifndef ENABLE_LOGGING
RIME_OPTIONS += -DENABLE_LOGGING=OFF
endif

ifdef ANDROID_ABI
RIME_OPTIONS += -DANDROID_ABI=$(ARCH) -DANDROID_PLATFORM=android-21
endif

ifdef GITHUB_WORKSPACE
RIME_OPTIONS += -DCMAKE_FIND_ROOT_PATH=$(GITHUB_WORKSPACE)
endif

ifdef icu_prefix
RIME_OPTIONS += -DBUILD_WITH_ICU=ON -DCMAKE_PREFIX_PATH="$(icu_prefix)"
endif

debug: build ?= debug
build ?= build

.PHONY: all release debug clean dist distclean deps thirdparty

all: release

release:
	cmake . -B$(build)  \
	-DBUILD_STATIC=ON \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_INSTALL_PREFIX="$(dist_dir)" \
	$(CMAKE_BOOST_OPTIONS) \
	$(RIME_OPTIONS)
	cmake --build $(build) --config Release

debug:
	cmake . -B$(build)  \
	-DBUILD_STATIC=ON \
	-DBUILD_SHARED_LIBS=OFF \
	-DBUILD_SEPARATE_LIBS=ON \
	$(CMAKE_BOOST_OPTIONS) \
	$(RIME_OPTIONS)
	cmake --build $(build) --config Debug

clean:
	rm -rf build > /dev/null 2>&1 || true
	rm -rf debug > /dev/null 2>&1 || true
	rm build.log > /dev/null 2>&1 || true
	rm -f lib/* > /dev/null 2>&1 || true
	$(MAKE) -f deps.mk clean-src

dist: release
	cmake --build $(build) --config Release --target install

distclean: clean
	rm -rf "$(dist_dir)" > /dev/null 2>&1 || true

ifdef ANDROID_ABI
# `thirdparty` is deprecated in favor of `deps`
deps thirdparty:
	$(MAKE) -f deps.mk

deps/boost thirdparty/boost:
	./install-boost.sh

deps/%:
	$(MAKE) -f deps.mk $(@:deps/%=%)

thirdparty/%:
	$(MAKE) -f deps.mk $(@:thirdparty/%=%)
endif
