FROM ubuntu:16.04
MAINTAINER Laurent Gaches <laurent@binimo.com>

# Install related packages and set LLVM 3.6 as the compiler
RUN apt-get -q update && \
    apt-get -q install -y \
    g++ \
    make \
    binutils \
    autoconf \
    automake \
    autotools-dev \
    libtool \
    zlib1g-dev \
    libc6-dev \
    libcunit1-dev \
    libev-dev \
    libevent-dev \
    libjansson-dev \
    libjemalloc-dev \
    libc-ares-dev \
    libsystemd-dev \
    libspdylay-dev \
    clang-3.8 \
    curl \
    libedit-dev \
    python2.7 \
    python2.7-dev \
    cython \
    python3-dev \
    python-setuptools \
    libicu-dev \
    libssl-dev \
    libxml2 \
    libxml2-dev \
    git \
    libcurl4-openssl-dev \
    pkg-config \

    && update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.8 100 \
    && update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100 \
    && rm -r /var/lib/apt/lists/*

# Download and Install nghttp2 & curl
RUN curl -LOk https://github.com/nghttp2/nghttp2/releases/download/v1.22.0/nghttp2-1.22.0.tar.bz2 \
    && tar xf nghttp2-1.22.0.tar.bz2 && rm nghttp2-1.22.0.tar.bz2 && cd nghttp2-1.22.0  \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf nghttp2-1.22.0 
RUN curl -LOk https://github.com/curl/curl/releases/download/curl-7_54_0/curl-7.54.0.tar.bz2 \
    && tar xf curl-7.54.0.tar.bz2 && rm curl-7.54.0.tar.bz2 && cd curl-7.54.0  \
    && ./configure --with-nghttp2=/usr/local --with-ssl \
    && make \
    && make install \    
    && ldconfig \
    && cd .. \
    && rm -rf curl-7.54.0

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little
ARG SWIFT_PLATFORM=ubuntu16.04
ARG SWIFT_BRANCH=swift-3.1.1-release
ARG SWIFT_VERSION=swift-3.1.1-RELEASE

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION

# Download GPG keys, signature and Swift package, then unpack and cleanup
RUN SWIFT_URL=https://swift.org/builds/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz \
    && curl -fSsL $SWIFT_URL -o swift.tar.gz \
    && curl -fSsL $SWIFT_URL.sig -o swift.tar.gz.sig \
    && export GNUPGHOME="$(mktemp -d)" \
    && set -e; \
        for key in \
      # pub   4096R/412B37AD 2015-11-19 [expires: 2017-11-18]
      #       Key fingerprint = 7463 A81A 4B2E EA1B 551F  FBCF D441 C977 412B 37AD
      # uid                  Swift Automatic Signing Key #1 <swift-infrastructure@swift.org>
          7463A81A4B2EEA1B551FFBCFD441C977412B37AD \
      # pub   4096R/21A56D5F 2015-11-28 [expires: 2017-11-27]
      #       Key fingerprint = 1BE1 E29A 084C B305 F397  D62A 9F59 7F4D 21A5 6D5F
      # uid                  Swift 2.2 Release Signing Key <swift-infrastructure@swift.org>
          1BE1E29A084CB305F397D62A9F597F4D21A56D5F \
      # pub   4096R/91D306C6 2016-05-31 [expires: 2018-05-31]
      #       Key fingerprint = A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6
      # uid                  Swift 3.x Release Signing Key <swift-infrastructure@swift.org>
          A3BAFD3556A59079C06894BD63BC1CFE91D306C6 \
        ; do \
          gpg --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done \
    && gpg --batch --verify --quiet swift.tar.gz.sig swift.tar.gz \
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && rm -r "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz

# Post cleanup for binaries orthogonal to swift runtime, but was used to download and install. 
RUN apt-get -y remove --purge \ 
    python2.7 \
    curl \                
    cython \
    python3-dev \
    python-setuptools \
    && ldconfig   
     

# Print Installed Swift Version
RUN swift --version
