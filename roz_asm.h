#ifndef ROZ_ASM_H
#define ROZ_ASM_H
#include <stdint.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
// --- roz_SysMem.asm ---
extern void  roz_WinMemset(void* dest, uint64_t val, uint64_t count_bytes);
extern void  roz_WinMemcpy(void* dest, const void* src, uint64_t count_bytes);
extern void  roz_MemMove(void* dest, const void* src, uint64_t count_bytes);
extern void  roz_MemSwap64(void* a, void* b, uint64_t count_qwords);
extern void  roz_ZeroFill(void* dest, uint64_t count_bytes);
extern uint64_t   roz_GetTicks(void);
extern uint64_t   roz_AtomicXchg64(volatile uint64_t* target, uint64_t value);
extern void  roz_AtomicAdd64(volatile uint64_t* target, uint64_t value);
extern void  roz_Prefetch(const void* addr);
extern void  roz_CacheFlush(const void* addr);
extern uint64_t   roz_MemIsZero(const void* buf, uint64_t count_qwords);
extern int64_t   roz_BitScanForward(uint64_t value);
extern uint64_t   roz_StrLen(const char* str);
extern char* roz_StrChr(const char* str, char c);
extern void* roz_Alloc(size_t size);
extern void* roz_Calloc(size_t size);
extern void  roz_Free(void* ptr);
extern void* roz_Realloc(void* ptr, size_t new_size);
#ifdef __cplusplus
}
#endif
#endif // ROZ_ASM_H