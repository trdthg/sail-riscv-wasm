import { init, WASI } from '@wasmer/wasi';

function App() {
  return (
    <>
      <h1>sail-riscv on web</h1>
      <div className="card">
        <button onClick={async () => {
          // This is needed to load the WASI library first (since is a Wasm module)
          await init();

          let args = []
          let wasi = new WASI({
            args: args
          });

          const moduleBytes = fetch("http://localhost:5173/riscv_sim_RV64.wasm");
          const module = await WebAssembly.compileStreaming(moduleBytes);
          // Instantiate the WASI module
          await wasi.instantiate(module, {});

          // Run the start function
          let exitCode = wasi.start();
          let stderr = wasi.getStderrString();
          let stdout = wasi.getStdoutString();

          console.log(`(exit code: ${exitCode})`)
          console.log(`${stdout}`);
        }}>
          Run
        </button>
      </div>
    </>
  )
}

export default App
