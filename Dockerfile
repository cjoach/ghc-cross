################################################################################
## base image
################################################################################

FROM debian:buster AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        autoconf \
        binutils-arm-linux-gnueabihf \
        build-essential \
        ca-certificates \
        coreutils \
        cpp-arm-linux-gnueabihf \
        curl \
        gcc-arm-linux-gnueabihf \
        git \
        libc-dev:armhf \
        libc6-armhf-cross \
        libffi-dev \
        libffi6 \
        libgmp-dev \
        libgmp-dev:armhf \
        libgmp10 \
        libncurses-dev \
        libncurses-dev:armhf \
        libncurses5 \
        libncurses5:armhf \
        libtinfo-dev:armhf \
        libtinfo5 \
        linux-libc-dev-armhf-cross \
        llvm-7 \
        python3 \
        sed \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates

################################################################################
## builder image
################################################################################

FROM base AS builder

SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.ghcup/bin:${PATH}"

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=8.8.4
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

RUN cabal new-install alex happy

RUN curl -o ghc-8.8.4.tar.xz https://downloads.haskell.org/ghc/8.8.4/ghc-8.8.4-src.tar.xz
RUN tar xf ghc-8.8.4.tar.xz
RUN echo $'Stage1Only = YES\n\
HADDOCK_DOCS = NO\n\
WITH_TERMINFO = NO\n\
BuildFlavour = perf-cross' > /ghc-8.8.4/mk/build.mk

WORKDIR /ghc-8.8.4

RUN ./configure --target=arm-linux-gnueabihf
RUN make
RUN make install

################################################################################
## main image
################################################################################

FROM base

SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.ghcup/bin:${PATH}"

COPY --from=builder /usr/local /usr/local
COPY --from=builder /root/.ghcup /root/.ghcup

RUN echo $'cabal new-build \
--with-ghc="/usr/local/bin/arm-linux-gnueabihf-ghc" \
--with-ghc-pkg="/usr/local/bin/arm-linux-gnueabihf-ghc-pkg" \
--with-runghc="/usr/local/bin/arm-linux-gnueabihf-runghc" \
--with-hsc2hs="/usr/local/bin/arm-linux-gnueabihf-hsc2hs" \
"${@}"' > /usr/local/bin/cabal-arm-build && \
    chmod +x /usr/local/bin/cabal-arm-build
