import ctypes
import time

# --- INIT ---
try:
    luna = ctypes.CDLL("./roz_asm.dll")
except Exception as e:
    print(f"FATAL: DLL LOAD ERROR: {e}"); exit(1)

PTR, U64, I64, U32 = ctypes.c_void_p, ctypes.c_uint64, ctypes.c_int64, ctypes.c_uint32

def set_t(f, r, a): f.restype = r; f.argtypes = a

# Mapping functions
set_t(luna.Luna_WinMemset, None, [PTR, U32, U64])
set_t(luna.Luna_WinMemcpy, PTR,  [PTR, PTR, U64])
set_t(luna.Luna_StrLen,    U64,  [ctypes.c_char_p])
set_t(luna.Luna_Alloc,     PTR,  [U64])
set_t(luna.Luna_Free,      None, [PTR])
set_t(luna.Luna_GetTicks,  U64,  [])

def run_benchmarks():
    print("\n" + "═"*75)
    print(f"║ {'SYSTEM CORE PERFORMANCE BENCHMARK (x64)' : ^71} ║")
    print("═"*75)

    # Тестовые данные: 100 МБ
    DATA_SIZE = 100 * 1024 * 1024 
    ITERATIONS = 10
    
    print(f"[*] Payload: {DATA_SIZE // (1024*1024)} MB | Iterations: {ITERATIONS}")
    
    p1 = luna.Luna_Alloc(DATA_SIZE)
    p2 = luna.Luna_Alloc(DATA_SIZE)
    
    # --- TEST 1: MEMSET SPEED ---
    print(f"\n[TEST 1] SIMD MEMSET (0xAA)")
    t1 = time.perf_counter()
    for _ in range(ITERATIONS):
        luna.Luna_WinMemset(p1, 0xAA, DATA_SIZE)
    t2 = time.perf_counter()
    print(f" > WinMemset Speed: {((DATA_SIZE * ITERATIONS) / (t2 - t1)) / (1024**3):.2f} GB/s")

    # --- TEST 2: MEMCPY SPEED ---
    print(f"\n[TEST 2] SIMD MEMCPY")
    t1 = time.perf_counter()
    for _ in range(ITERATIONS):
        luna.Luna_WinWinMemcpy = luna.Luna_WinMemcpy(p2, p1, DATA_SIZE)
    t2 = time.perf_counter()
    print(f" > WinMemcpy Speed: {((DATA_SIZE * ITERATIONS) / (t2 - t1)) / (1024**3):.2f} GB/s")

    # --- TEST 3: STRLEN VS NATIVE ---
    print(f"\n[TEST 3] STRING ENGINE (STRLEN)")
    long_str = b"A" * 1_000_000 + b"\0"
    t1 = time.perf_counter()
    for _ in range(1000):
        _ = luna.Luna_StrLen(long_str)
    t2 = time.perf_counter()
    print(f" > ASM StrLen:  {(t2 - t1)*1000:.3f} ms (total for 1k iterations)")

    # --- TEST 4: HEAP STRESS (STABILITY) ---
    print(f"\n[TEST 4] HEAP ALLOC/FREE STRESS")
    success = 0
    t1 = time.perf_counter()
    for i in range(5000):
        tmp = luna.Luna_Alloc(i + 1)
        if tmp:
            luna.Luna_Free(tmp)
            success += 1
    t2 = time.perf_counter()
    print(f" > Stress: {success}/5000 cycles OK | Time: {t2-t1:.3f}s")

    # CLEANUP
    luna.Luna_Free(p1)
    luna.Luna_Free(p2)

    print("\n" + "═"*75)
    print(f"║ {'BENCHMARK COMPLETE - HARDWARE SATURATED' : ^71} ║")
    print("═"*75 + "\n")

if __name__ == "__main__":
    run_benchmarks()
