# Compile sail to WASM

You need to have docker installed

## How to Use

1. Run setup.sh
2. Run build.sh

## Steps

1. Create setup.sh, prepare sail compiler, prepare zlib gmp and softfloat source code

	> The gmp repo I am using already contains a `build.sh` script, which will build gmp inside Docker and copy the output to local.

	```bash
	wget https://github.com/rems-project/sail/releases/download/0.18-linux-binary/sail.tar.gz
	tar -zxf sail.tar.gz
	git clone --depth 1 https://github.com/OffchainLabs/SoftFloat.git
	git clone --depth 1 https://github.com/Daninet/gmp-wasm.git
	git clone --depth 1 https://github.com/riscv/sail-riscv.git
	./gmp-wasm/binding/build-gmp.sh
	```

2. Modify Makefile

	```diff
	diff --git a/Makefile b/Makefile
	index 2313d14..d03387e 100644
	--- a/Makefile
	+++ b/Makefile
	@@ -150,9 +150,9 @@ C_WARNINGS ?=
	 C_INCS = $(addprefix c_emulator/,riscv_prelude.h riscv_platform_impl.h riscv_platform.h riscv_softfloat.h)
	 C_SRCS = $(addprefix c_emulator/,riscv_prelude.c riscv_platform_impl.c riscv_platform.c riscv_softfloat.c riscv_sim.c)
	 
	-SOFTFLOAT_DIR    = c_emulator/SoftFloat-3e
	+SOFTFLOAT_DIR    = ../SoftFloat
	 SOFTFLOAT_INCDIR = $(SOFTFLOAT_DIR)/source/include
	-SOFTFLOAT_LIBDIR = $(SOFTFLOAT_DIR)/build/Linux-RISCV-GCC
	+SOFTFLOAT_LIBDIR = $(SOFTFLOAT_DIR)/build/Wasm-Clang
	 SOFTFLOAT_FLAGS  = -I $(SOFTFLOAT_INCDIR)
	 SOFTFLOAT_LIBS   = $(SOFTFLOAT_LIBDIR)/softfloat.a
	 SOFTFLOAT_SPECIALIZE_TYPE = RISCV
	@@ -165,8 +165,8 @@ GMP_LIBS = $(shell pkg-config --libs gmp || echo -lgmp)
	 ZLIB_FLAGS = $(shell pkg-config --cflags zlib)
	 ZLIB_LIBS = $(shell pkg-config --libs zlib)
	 
	-C_FLAGS = -I $(SAIL_LIB_DIR) -I c_emulator $(GMP_FLAGS) $(ZLIB_FLAGS) $(SOFTFLOAT_FLAGS)
	-C_LIBS  = $(GMP_LIBS) $(ZLIB_LIBS) $(SOFTFLOAT_LIBS)
	+C_FLAGS = -I $(SAIL_LIB_DIR) -I /src/gmp-wasm/binding/gmp/dist/include -I c_emulator -I /src/zlib $(SOFTFLOAT_FLAGS)
	+C_LIBS  = /src/gmp-wasm/binding/gmp/dist/lib/libgmp.a /src/zlib/libz.a $(SOFTFLOAT_LIBS)
	 
	 # The C simulator can be built to be linked against Spike for tandem-verification.
	 # This needs the C bindings to Spike from https://github.com/SRI-CSL/l3riscv
	@@ -256,6 +256,9 @@ rvfi: c_emulator/riscv_rvfi_$(ARCH)
	 c_emulator/riscv_sim_$(ARCH): generated_definitions/c/riscv_model_$(ARCH).c $(C_INCS) $(C_SRCS) $(SOFTFLOAT_LIBS) Makefile
	 	$(CC) -g $(C_WARNINGS) $(C_FLAGS) $< $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS_WRAPPED) -o $@
	 
	+c_emulator/riscv_sim_$(ARCH).wasm:  generated_definitions/c/riscv_model_$(ARCH).c $(C_INCS) $(C_SRCS) $(SOFTFLOAT_LIBS) Makefile
	+	emcc -g $(C_WARNINGS) $(C_FLAGS) $< $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS) -o $@
	+
	 # Note: We have to add -c_preserve since the functions might be optimized out otherwise
	 rvfi_preserve_fns=-c_preserve rvfi_set_instr_packet \
	   -c_preserve rvfi_get_cmd \
	
	```

3. Create Dockerfile, based on the `emscripten/emsdk` image, which provides emsdk and clang-20. 	

	```Dockerfile
	FROM emscripten/emsdk:latest
	COPY . .
	ENV PATH="${PATH}:/src/sail/bin:/emsdk/upstream/bin"
	RUN git config --global user.email "you@example.com" && git config --global user.name "Your Name"
	RUN wget https://www.zlib.net/zlib-1.3.1.tar.gz -O zlib.tar.gz \
	    && tar -zxf zlib.tar.gz \
	    && mv zlib-1.3.1 zlib \
	    && cd zlib \
	    && emconfigure ./configure \
	    && emmake make -j$(nproc) || true
	RUN cd sail-riscv && make c_emulator/wasm_riscv_sim_RV64
	```

4. Run `docker build`, and copy the result to local

	```build.sh
	docker build -f Dockerfile . --tag=sail-riscv-wasm-builder:latest
	
	container_id=$(docker create sail-riscv-wasm-builder)
	docker cp "$container_id:/src/sail-riscv/c_emulator/riscv_sim_RV64.wasm" "."
	docker rm "$container_id"
	```