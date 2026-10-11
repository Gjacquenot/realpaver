FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        coinor-libclp-dev \
        meson \
        ninja-build \
        pkg-config \
        flex \
        bison \
        zlib1g-dev \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://frederic.goualard.net/software/mathlib-2.1.1.tar.gz -O /tmp/mathlib.tar.gz \
    && tar -xzf /tmp/mathlib.tar.gz -C /tmp \
    && cd /tmp/mathlib-2.1.1 \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/mathlib-2.1.1 /tmp/mathlib.tar.gz

ARG TARGETARCH
RUN git clone --depth 1 https://github.com/raphaelchenouard/GAOL.git /tmp/GAOL \
    && meson setup /tmp/GAOL/build /tmp/GAOL --prefix=/usr/local -Dwith-mathlib=apmathlib \
    && sed -i '/extern "C" int getrusage(int, struct rusage\*);/d' /tmp/GAOL/gaol/gaol_profile.cpp \
    && if [ "$TARGETARCH" = "amd64" ]; then \
        sed -i 's/IX86_LINUX (IX86 \& OS_LINUX)/IX86_LINUX OS_LINUX/' /tmp/GAOL/build/gaol/gaol_configuration.h; \
    fi \
    && meson compile -C /tmp/GAOL/build \
    && meson install -C /tmp/GAOL/build \
    && cp /tmp/GAOL/gaol/*.h /usr/local/include/gaol/

WORKDIR /src
COPY . .

ENV LD_LIBRARY_PATH=/usr/local/lib
RUN meson setup build --prefix=/usr/local \
        -DLP_LIB=Clp \
        -DINTERVAL_LIB=Gaol \
        -Dbuildtype=release \
        -DASSERT=false \
        -DGENERATE_DOC=false \
    && meson compile -C build \
    && meson install -C build

FROM debian:bookworm-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        coinor-libclp1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/ /usr/local/

RUN ldconfig

WORKDIR /workspace
ENTRYPOINT ["rp_solver"]
