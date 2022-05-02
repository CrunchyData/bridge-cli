FROM alpine:latest

RUN \
  apk add --update --no-cache --force-overwrite \
    # Crystal dependencies
    build-base git gc-dev libevent-dev pcre-dev zlib-dev \
    libxml2-dev yaml-dev openssl-dev gmp-dev zlib-dev \
    # depedencies (used by Crystal stdlib)
    openssl-libs-static \
    zlib-static \
    crystal shards \
    libssh2 libssh2-dev libssh2-static

# RUN apk add --update --no-cache --force-overwrite --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main llvm12-libs

# Install latest crystal from edge
# RUN apk add --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community crystal shards
# go back to crystal 1.0.0 while alpine has a broken build
# RUN apk add --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/latest-stable/community crystal shards

CMD [ "/bin/sh" ]
