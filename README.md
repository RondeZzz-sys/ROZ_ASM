# ROZ_ASM Core (x64)

High-performance system primitives for 64-bit Windows environments. This library provides optimized assembly implementations for memory management, string operations, and atomic instructions.

## Performance
- **Memset/ZeroFill:** Up to 8.80 GB/s
- **Memcpy:** Up to 8.24 GB/s
- **String Length:** Ultra-fast SIMD-accelerated scanning

## How to Build
1. **Prerequisites:**
   - [NASM](https://www.nasm.us/) (v2.15 or later recommended).
   - **MSVC Linker** (included with Visual Studio or Build Tools).
   - **Windows SDK** (for kernel32.lib).

2. **Configuration:**
   Open `roz_bat.bat` and update the following paths to match your local installation:
   - `NASM_PATH`: Path to your `nasm.exe`.
   - `VS_BIN`: Path to your MSVC `link.exe`.
   - `WIN_KITS`: Path to your Windows SDK library folder.

3. **Compilation:**
   Run `roz_bat.bat`. On success, it will generate `roz_asm.dll`.

## Usage
The library exports 18 low-level functions including:
- Memory: `Alloc`, `Free`, `Realloc`, `ZeroFill`, `Memcpy`, `MemMove`.
- Atomics: `AtomicAdd64`, `AtomicXchg64`.
- Logic: `BitScanForward`, `MemIsZero`.
- CPU: `GetTicks`, `Prefetch`, `CacheFlush`.

Refer to `test_asm.py` for Python integration examples via `ctypes`.

## Validation
All core functions are verified with a Python stress-test suite.