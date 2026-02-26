cmake_minimum_required(VERSION 3.20)
project(sail-riscv-wasm LANGUAGES C CXX)

if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(SAIL_RISCV_DIR "${CMAKE_SOURCE_DIR}/sail-riscv" CACHE PATH "Path to sail-riscv submodule")
set(SAIL_RISCV_BUILD_DIR "${CMAKE_BINARY_DIR}/sail-riscv-build" CACHE PATH "Build directory for sail-riscv")
set(SAIL_DEBUG_SRC "${CMAKE_SOURCE_DIR}/src/riscv_debug.cpp" CACHE FILEPATH "Top-level riscv_debug.cpp source")
option(SAIL_SYNC_WEB_ASSETS "Copy sail_riscv_debug wasm/js into top-level web/public" ON)

if (NOT EXISTS "${SAIL_RISCV_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "Missing sail-riscv submodule at ${SAIL_RISCV_DIR}. Run ./scripts/bootstrap-submodules.sh")
endif()
if (NOT EXISTS "${SAIL_DEBUG_SRC}")
  message(FATAL_ERROR "Missing debug source override at ${SAIL_DEBUG_SRC}")
endif()

set(sail_riscv_cmake_args
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
)

if (DEFINED GMP_WASM_DIST AND NOT "${GMP_WASM_DIST}" STREQUAL "")
  list(APPEND sail_riscv_cmake_args -DGMP_WASM_DIST:PATH=${GMP_WASM_DIST})
endif()
if (DEFINED CMAKE_TOOLCHAIN_FILE AND NOT "${CMAKE_TOOLCHAIN_FILE}" STREQUAL "")
  list(APPEND sail_riscv_cmake_args -DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE})
endif()
if (DEFINED CMAKE_CROSSCOMPILING_EMULATOR AND NOT "${CMAKE_CROSSCOMPILING_EMULATOR}" STREQUAL "")
  list(APPEND sail_riscv_cmake_args -DCMAKE_CROSSCOMPILING_EMULATOR:STRING=${CMAKE_CROSSCOMPILING_EMULATOR})
endif()
if (DEFINED CMAKE_EXE_LINKER_FLAGS AND NOT "${CMAKE_EXE_LINKER_FLAGS}" STREQUAL "")
  list(APPEND sail_riscv_cmake_args -DCMAKE_EXE_LINKER_FLAGS:STRING=${CMAKE_EXE_LINKER_FLAGS})
endif()
if (DEFINED SAIL_BIN AND NOT "${SAIL_BIN}" STREQUAL "")
  list(APPEND sail_riscv_cmake_args -DSAIL_BIN:FILEPATH=${SAIL_BIN})
endif()

add_custom_target(sync_sail_debug_source
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${SAIL_DEBUG_SRC}"
          "${SAIL_RISCV_DIR}/c_emulator/riscv_debug.cpp"
  COMMENT "Sync top-level riscv_debug.cpp into sail-riscv submodule"
)

add_custom_target(sail_riscv_wasm_debug
  COMMAND ${CMAKE_COMMAND} -S "${SAIL_RISCV_DIR}" -B "${SAIL_RISCV_BUILD_DIR}" ${sail_riscv_cmake_args}
  COMMAND ${CMAKE_COMMAND} --build "${SAIL_RISCV_BUILD_DIR}" --target sail_riscv_debug -j
  DEPENDS sync_sail_debug_source
  COMMENT "Configure + build sail_riscv_debug using sail-riscv"
)

if (EMSCRIPTEN AND SAIL_SYNC_WEB_ASSETS)
  set(SAIL_RISCV_DEBUG_JS "${SAIL_RISCV_BUILD_DIR}/c_emulator/sail_riscv_debug.js")
  set(SAIL_RISCV_DEBUG_WASM "${SAIL_RISCV_BUILD_DIR}/c_emulator/sail_riscv_debug.wasm")
  set(WEB_PUBLIC_DIR "${CMAKE_SOURCE_DIR}/web/public")

  add_custom_target(sync_web_wasm_assets
    COMMAND ${CMAKE_COMMAND} -E make_directory "${WEB_PUBLIC_DIR}/wasm"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SAIL_RISCV_DEBUG_JS}" "${WEB_PUBLIC_DIR}/sail_riscv_debug.js"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SAIL_RISCV_DEBUG_WASM}" "${WEB_PUBLIC_DIR}/sail_riscv_debug.wasm"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SAIL_RISCV_DEBUG_JS}" "${WEB_PUBLIC_DIR}/wasm/sail_riscv_debug.js"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SAIL_RISCV_DEBUG_WASM}" "${WEB_PUBLIC_DIR}/wasm/sail_riscv_debug.wasm"
    DEPENDS sail_riscv_wasm_debug
    COMMENT "Sync sail_riscv_debug wasm assets to web/public"
  )
endif()
