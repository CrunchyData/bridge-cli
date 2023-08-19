MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

CRYSTAL_BIN       ?= $(shell which crystal)
SHARDS_BIN        ?= $(shell which shards)
CB_BIN            ?= $(shell which cb)
PREFIX            ?= /usr/local
LDFLAGS           ?=
RELEASE           ?=
STATIC            ?=
STATIC_LIBS       ?=
STATIC_LIBS_DIR   := $(CURDIR)/vendor
STRIP_RPATH       ?=
SOURCES           := src/*.cr src/**/*.cr
TARGET_ARCH       := $(shell uname -m)
TARGET_OS         := $(shell uname -s | tr '[:upper:]' '[:lower:]')

ifeq ($(shell [[ "$(TARGET_OS)" == "darwin" && "$(STATIC_LIBS)" != "" ]] && echo true),true)
  override LDFLAGS += -L$(STATIC_LIBS_DIR)
  BDWGC_LIB_PATH    ?= $(shell pkg-config --libs-only-L bdw-gc | cut -c 3-)
  LIBEVENT_LIB_PATH ?= $(shell pkg-config --libs-only-L libevent | cut -c 3-)
  LIBPCRE_LIB_PATH  ?= $(shell brew --prefix pcre2)/lib
  OPENSSL_LIB_PATH  ?= $(shell brew --prefix openssl@3)/lib
  LIBSSH2_LIB_PATH  ?= $(shell brew --prefix libssh2)/lib
  export PKG_CONFIG_PATH=$(OPENSSL_LIB_PATH)/pkgconfig

  vendor/libcrypto.a: $(OPENSSL_LIB_PATH)/libcrypto.a
	  mkdir -p $(STATIC_LIBS_DIR)
		cp -f $(OPENSSL_LIB_PATH)/libcrypto.a $(STATIC_LIBS_DIR)

  vendor/libevent.a: $(LIBEVENT_LIB_PATH)/libevent.a
		mkdir -p $(STATIC_LIBS_DIR)
		cp -f $(LIBEVENT_LIB_PATH)/libevent.a $(STATIC_LIBS_DIR)

  vendor/libgc.a: $(BDWGC_LIB_PATH)/libgc.a
		mkdir -p $(STATIC_LIBS_DIR)
		cp -f $(BDWGC_LIB_PATH)/libgc.a $(STATIC_LIBS_DIR)

  vendor/libpcre.a: $(LIBPCRE_LIB_PATH)/libpcre2-8.a
		mkdir -p $(STATIC_LIBS_DIR)
		cp -f $(LIBPCRE_LIB_PATH)/libpcre2-8.a $(STATIC_LIBS_DIR)

  vendor/libssl.a: $(OPENSSL_LIB_PATH)/libssl.a
		mkdir -p $(OPENSSL_LIB_PATH)
		cp -f $(OPENSSL_LIB_PATH)/libssl.a $(STATIC_LIBS_DIR)

  vendor/libssh2.a: $(LIBSSH2_LIB_PATH)/libssh2.a
		mkdir -p $(LIBSSH2_LIB_PATH)
		cp -f $(LIBSSH2_LIB_PATH)/libssh2.a $(STATIC_LIBS_DIR)

  .PHONY: libs
  libs: vendor/libcrypto.a vendor/libgc.a vendor/libssl.a vendor/libevent.a vendor/libpcre.a vendor/libssh2.a
else
  .PHONY: libs
  libs:
endif

override CRFLAGS += --progress $(if $(RELEASE),--release ,--debug --error-trace )$(if $(STATIC),--static )$(if $(LDFLAGS),--link-flags="$(LDFLAGS)" )

.PHONY: all
all: build

bin/cb: deps libs $(SOURCES)
	mkdir -p bin
	@if [ ! -z "$(STATIC)" ] && [ $(STATIC) -eq 1 ] && [ "$(TARGET_OS)" == "linux" ]; then \
		if [ "$(TARGET_ARCH)" == "x86_64" ]; then \
			PLATFORM_ARCH=amd64; \
		elif [ "$(TARGET_ARCH)" == "aarch64" ]; then\
			PLATFORM_ARCH=arm64; \
		else \
			PLATFORM_ARCH=$(TARGET_ARCH); \
		fi; \
		docker buildx build --load --platform linux/$$PLATFORM_ARCH -t cb-static-builder-$$PLATFORM_ARCH .; \
		docker run --rm -v $(CURDIR):/workspace -w /workspace cb-static-builder-$$PLATFORM_ARCH:latest \
			crystal build -o bin/cb src/cli.cr $(CRFLAGS); \
	else \
		$(CRYSTAL_BIN) build -o bin/cb src/cli.cr $(CRFLAGS); \
		if [ ! -z "$(STRIP_RPATH)" ] && [ "$(TARGET_OS)" == "linux" ] && readelf -p1 bin/cb | grep -q 'linuxbrew'; then \
			patchelf --remove-rpath bin/cb; \
			patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 bin/cb; \
		fi; \
	fi

.PHONY: build
build: bin/cb

.PHONY: deps
deps: shard.yml shard.lock
	$(SHARDS_BIN) check || $(SHARDS_BIN) install

docs: $(SOURCES)
	$(CRYSTAL_BIN) docs

format:
	$(CRYSTAL_BIN) tool format

.PHONY: clean
clean:
	rm -f ./bin/cb*
	rm -rf ./dist
	rm -rf ./docs
	@[ "$(TARGET_OS)" == "darwin" ] && rm -rf ./vendor/*.a || true

.PHONY: spec
spec: libs deps $(SOURCES)
	$(CRYSTAL_BIN) tool format --check
	@if [ "$(TARGET_OS)" == "darwin" ]; then \
		LIBRARY_PATH=$(STATIC_LIBS_DIR) $(CRYSTAL_BIN) spec -Dmt_no_expectations --error-trace; \
	else \
		$(CRYSTAL_BIN) spec -Dmt_no_expectations --error-trace; \
	fi

.PHONY: check-libraries
check-libraries: bin/cb
	@if [ ! -z "$(STATIC_LIBS)" ] && [ "$(TARGET_OS)" == "darwin" ] && [ "$$(otool -LX bin/cb | awk '{print $$1}')" != "$$(cat expected.libs.darwin)" ]; then \
		echo "FAIL: bin/cb has non-allowed dynamic libraries"; \
		exit 1; \
	else \
		echo "OK: bin/cb has only allowed dynamic libraries"; \
		exit 0; \
	fi

.PHONY: check-provisioning
check-provisioning:
	cd $(CURDIR)/spec/provisioning && \
	(bundle check || bundle install) && \
	bundle exec rspec

.PHONY: test
test: spec check-libraries

release: bin/cb
	mkdir -p ./dist
	zip --junk-paths dist/cb.zip bin/cb

.PHONY: install
install: bin/cb
	mkdir -p $(PREFIX)/bin
	cp ./bin/cb* $(PREFIX)/bin

.PHONY: reinstall
reinstall: bin/cb
	cp ./bin/cb* $(CB_BIN) -rf

# modified from https://github.com/maxfierke/mstrap/blob/f75a796fa704db8c33b8edc4f007097eeda6845a/Makefile
# that project's license for this file:
# The MIT License (MIT)
#
# Copyright (c) 2019 Max Fierke
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
