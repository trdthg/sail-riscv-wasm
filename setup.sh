wget https://github.com/rems-project/sail/releases/download/0.18-linux-binary/sail.tar.gz
tar -zxf sail.tar.gz
git clone --depth 1 https://github.com/OffchainLabs/SoftFloat.git
git clone --depth 1 https://github.com/Daninet/gmp-wasm.git
git clone --depth 1 https://github.com/riscv/sail-riscv.git
./gmp-wasm/binding/build-gmp.sh