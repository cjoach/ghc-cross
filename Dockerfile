FROM debian:buster

SHELL ["/bin/bash", "-c"]

WORKDIR /

################################################################################
## install dependencies
################################################################################

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        coreutils \
        curl \
        gcc-arm-linux-gnueabihf \
        git \
        libc6-dev-armhf-cross \
        libffi-dev \
        libffi6 \
        libgmp-dev \
        libgmp10 \
        libncurses-dev \
        libncurses-dev \
        libncurses5 \
        libtinfo5 \
        llvm-7 \
        python3 \
        sed \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

################################################################################
## install ghc and cabal from ghcup
################################################################################

ENV PATH="/root/.ghcup/bin:${PATH}"
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=8.8.4
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

################################################################################
## install cabal dependencies
################################################################################

RUN cabal new-update && \
    cabal new-install alex happy

################################################################################
## download files
################################################################################

RUN curl \
        --output ghc-8.8.4.tar.xz \
        https://downloads.haskell.org/ghc/8.8.4/ghc-8.8.4-src.tar.xz \
        && \
    tar xf ghc-8.8.4.tar.xz
COPY build.mk /ghc-8.8.4/mk

################################################################################
## build ghc cross compiler and install in /usr/local
################################################################################

WORKDIR /ghc-8.8.4

RUN ./configure \
        --target=arm-linux-gnueabihf \
        --enable-unregisterised \
        CC=arm-linux-gnueabihf-gcc \
        && \
        make && \
        make install
