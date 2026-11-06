# syntax=docker/dockerfile:1
#
# Build environment for native-musl Lightpanda (x86_64 + i686).
#
# Reconstructed from `docker image history` of the image the binaries were built
# in, so this is what the i686 asset was actually built with. Recorded versions
# are in toolchain.lock.
#
#   docker build -t lp-musl .
#   docker run --rm -it -v "$PWD/../src:/build/src" lp-musl
#
# For reproducible builds the base image is pinned by digest and the Rust
# toolchain by version; both are recorded in toolchain.lock.

FROM debian:trixie@sha256:9c6e381421d0f48d1b8133e573f33c185ee16cbf505eda9c4a8a4791b25ea8a6

ARG ZIG_VER=0.17.0
ARG RUST_VERSION=1.99.1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl git make cmake clang ninja-build pkg-config xz-utils unzip rsync \
      ca-certificates python3 libglib2.0-dev gcc-multilib \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain, pinned by version (an unpinned `stable` moves and changes the
# output bytes). The i686 build additionally needs
# `rustup target add i686-unknown-linux-musl` — see ../README.md.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && /root/.cargo/bin/rustc --version \
    && /root/.cargo/bin/cargo --version

RUN cd /opt \
    && curl -fsSL "https://ziglang.org/download/${ZIG_VER}/zig-x86_64-linux-${ZIG_VER}.tar.xz" -o zig.tar.xz \
    && tar -xf zig.tar.xz \
    && mv "zig-x86_64-linux-${ZIG_VER}" zig \
    && rm zig.tar.xz \
    && ln -sf /opt/zig/zig /usr/local/bin/zig \
    && zig version

ENV PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /build
CMD ["/bin/bash"]
