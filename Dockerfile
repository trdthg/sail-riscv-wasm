# Point at any base image that you find suitable to extend.
FROM emscripten/emsdk:latest

# Install required tools that are useful for your project i.e. ninja-build
RUN apt update && apt install -y ninja-build

COPY . .

ENV PATH="${PATH}:/src/sail/bin:/emsdk/upstream/bin"
RUN git config --global user.email "you@example.com" && git config --global user.name "Your Name"
RUN wget https://www.zlib.net/zlib-1.3.1.tar.gz -O zlib.tar.gz \
    && tar -zxf zlib.tar.gz \
    && mv zlib-1.3.1 zlib \
    && cd zlib \
    && emconfigure ./configure \
    && emmake make -j$(nproc) || true
RUN cp Makefile sail-riscv/Makefile
RUN cd sail-riscv && make c_emulator/riscv_sim_RV64.wasm
