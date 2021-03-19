################################################################################
## builder image
################################################################################

FROM debian:buster AS builder

SHELL ["/bin/bash", "-c"]

WORKDIR /

################################################################################
## install dependencies
################################################################################

ENV DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        autoconf \
        binutils-arm-linux-gnueabihf \
        build-essential \
        ca-certificates \
        cabal-install \
        coreutils \
        cpp-arm-linux-gnueabihf \
        curl \
        gcc-arm-linux-gnueabihf \
        ghc \
        git \
        libc-dev:armhf \
        libc6-armhf-cross \
        libffi-dev \
        libffi6 \
        libgmp-dev \
        libgmp10 \
        libncurses-dev \
        libncurses-dev:armhf \
        libncurses6 \
        libncurses6:armhf \
        libtinfo-dev:armhf \
        libtinfo6 \
        linux-libc-dev-armhf-cross \
        llvm-7 \
        python3 \
        sed \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

 
################################################################################
## install ghc and cabal from ghcup
################################################################################
 
# RUN update-ca-certificates
# ENV PATH="/root/.ghcup/bin:${PATH}"
# ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
# ENV BOOTSTRAP_HASKELL_GHC_VERSION=8.8.4
# RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

################################################################################
## install cabal dependencies
################################################################################

RUN cabal update && \
    cabal install alex happy

################################################################################
## download files
################################################################################

RUN curl -o ghc-8.8.4.tar.xz https://downloads.haskell.org/ghc/8.8.4/ghc-8.8.4-src.tar.xz && \
    tar xf ghc-8.8.4.tar.xz && \
    echo $'Stage1Only = YES\n\
HADDOCK_DOCS = NO\n\
INTEGER_LIBRARY = integer-simple\n\
WITH_TERMINFO = NO\n\
BuildFlavour = perf-cross' > /ghc-8.8.4/mk/build.mk

################################################################################
## build ghc cross compiler and install in /usr/local
################################################################################

WORKDIR /ghc-8.8.4

RUN ./configure --target=arm-linux-gnueabihf
RUN make
RUN make install

################################################################################
## main image
################################################################################

FROM debian:buster

SHELL ["/bin/bash", "-c"]

COPY --from=builder /usr/local /usr/local
