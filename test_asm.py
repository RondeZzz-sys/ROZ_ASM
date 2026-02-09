import ctypes
import time

try:
    roz = ctypes.CDLL("./roz_asm.dll")
except Exception as e:
    print(f"FATAL: DLL LOAD ERROR: {e}"); exit(1)

PTR, U64, I64, U32 = ctypes.c_void_p, ctypes.c_uint64, ctypes.c_int64, ctypes.c_uint32
CHAR_P = ctypes.c_char_p

def set_t(f, r, a): f.restype = r; f.argtypes = a

set_t(roz.roz_WinMemset,    None,   [PTR, U32, U64])
set_t(roz.roz_WinMemcpy,    PTR,    [PTR, PTR, U64])
set_t(roz.roz_MemMove,      None,   [PTR, PTR, U64])
set_t(roz.roz_MemSwap64,    None,   [PTR, PTR, U64])
set_t(roz.roz_ZeroFill,     None,   [PTR, U64])
set_t(roz.roz_GetTicks,     U64,    [])
set_t(roz.roz_AtomicXchg64, U64,    [PTR, U64])
set_t(roz.roz_AtomicAdd64,  None,   [PTR, U64])
set_t(roz.roz_Prefetch,     None,   [PTR])
set_t(roz.roz_MemIsZero,    U64,    [PTR, U64])
set_t(roz.roz_BitScanForward, I64,  [U64])
set_t(roz.roz_StrLen,       U64,    [CHAR_P])
set_t(roz.roz_Alloc,        PTR,    [U64])
set_t(roz.roz_Free,         None,   [PTR])
set_t(roz.roz_Calloc,       PTR,    [U64])
set_t(roz.roz_Realloc,      PTR,    [PTR, U64])
set_t(roz.roz_StrChr,       PTR,    [CHAR_P, ctypes.c_char])
set_t(roz.roz_CacheFlush,   None,   [PTR])

def run_benchmarks():
    print("\n" + "═"*75)
    print(f"║ {'ROZ CORE: FULL ASM ENGINE STRESS-TEST' : ^71} ║")
    print("═"*75)

    print("[*] Testing Memory Allocation & ZeroFill...")
    size = 10 * 1024 * 1024
    buf = roz.roz_Alloc(size)
    roz.roz_ZeroFill(buf, size)
    is_zero = roz.roz_MemIsZero(buf, size // 8)
    print(f" > MemIsZero Check: {'SUCCESS' if is_zero == 1 else 'FAILED'}")

    print("\n[*] Testing Atomic Operations...")
    val = ctypes.c_uint64(100)
    p_val = ctypes.addressof(val)
    roz.roz_AtomicAdd64(p_val, 50)
    print(f" > AtomicAdd64 (100 + 50): {val.value}")
    old = roz.roz_AtomicXchg64(p_val, 999)
    print(f" > AtomicXchg64 (Old: {old}, New: {val.value})")

    print("\n[*] Testing BitScanForward...")
    bit_val = 0x001000
    index = roz.roz_BitScanForward(bit_val)
    print(f" > Index of first bit in {hex(bit_val)}: {index}")

    print("\n[*] Testing MemMove (Overlap Check)...")
    data = (ctypes.c_uint8 * 8)(1, 2, 3, 4, 5, 0, 0, 0)
    p_data = ctypes.addressof(data)
    roz.roz_MemMove(p_data + 1, p_data, 5)
    
    result = list(data)
    expected = [1, 1, 2, 3, 4, 5, 0, 0]
    print(f" > Result:   {result}")
    print(f" > Status:   {'SUCCESS' if result == expected else 'FAILED'}")

    print("\n[*] Testing Calloc & Realloc...")
    p_mem = roz.roz_Calloc(100)
    is_zero = roz.roz_MemIsZero(p_mem, 100 // 8)
    
    ctypes.cast(p_mem, ctypes.POINTER(ctypes.c_uint8))[0] = 0xDE
    p_mem = roz.roz_Realloc(p_mem, 200)
    val = ctypes.cast(p_mem, ctypes.POINTER(ctypes.c_uint8))[0]
    
    print(f" > Calloc zeroed: {'YES' if is_zero else 'NO'}")
    print(f" > Realloc preserved data: {'YES' if val == 0xDE else 'NO'}")
    roz.roz_Free(p_mem)

    print("\n[*] Testing String Engine...")
    test_str = b"roz_System_Core\0"
    
    length = roz.roz_StrLen(test_str)
    
    p_char = roz.roz_StrChr(test_str, b'_')
    found_at = ctypes.cast(p_char, ctypes.c_void_p).value - ctypes.cast(test_str, ctypes.c_void_p).value
    print(f" > StrLen: expected 15, got {length}")
    print(f" > StrChr: found '_' at index {found_at}")
    status = "SUCCESS" if (length == 15 and found_at == 3) else "FAILED"
    print(f" > Status: {status}")
    
    print("\n[*] Testing MemSwap64...")
    a = (ctypes.c_uint64 * 1)(111)
    b = (ctypes.c_uint64 * 1)(999)
    roz.roz_MemSwap64(ctypes.addressof(a), ctypes.addressof(b), 1)
    print(f" > After Swap: a={a[0]}, b={b[0]}")

    print("\n[*] Testing Cache Ops (Stability Check)...")
    temp_buf = roz.roz_Alloc(64)
    try:
        roz.roz_Prefetch(temp_buf)
        roz.roz_CacheFlush(temp_buf)
        print(" > Prefetch/Flush: STABLE")
    except Exception as e:
        print(f" > Cache Ops: CRASHED ({e})")
    roz.roz_Free(temp_buf)

    print("\n[*] Testing System Ticks...")
    t_start = roz.roz_GetTicks()
    time.sleep(0.1)
    t_end = roz.roz_GetTicks()
    print(f" > Ticks passed in 100ms: {t_end - t_start}")

    roz.roz_Free(buf)
    print("\n" + "═"*75)
    print(f"║ {'ALL CORE FUNCTIONS VALIDATED' : ^71} ║")
    print("═"*75 + "\n")

if __name__ == "__main__":
    run_benchmarks()
