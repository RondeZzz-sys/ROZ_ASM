#ifndef ROZ_ASM_H
#define ROZ_ASM_H
#include <stdint.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
// --- Luna_SysMem.asm ---
extern void  Luna_WinMemset(void* dest, uint64_t val, uint64_t count_bytes);
extern void  Luna_WinMemcpy(void* dest, const void* src, uint64_t count_bytes);
extern void  Luna_MemMove(void* dest, const void* src, uint64_t count_bytes);
extern void  Luna_MemSwap64(void* a, void* b, uint64_t count_qwords);
extern void  Luna_ZeroFill(void* dest, uint64_t count_bytes);
extern uint64_t   Luna_GetTicks(void);
extern uint64_t   Luna_AtomicXchg64(volatile uint64_t* target, uint64_t value);
extern void  Luna_AtomicAdd64(volatile uint64_t* target, uint64_t value);
extern void  Luna_Prefetch(const void* addr);
extern void  Luna_CacheFlush(const void* addr);
extern uint64_t   Luna_MemIsZero(const void* buf, uint64_t count_qwords);
extern int64_t   Luna_BitScanForward(uint64_t value);
extern uint64_t   Luna_StrLen(const char* str);
extern char* Luna_StrChr(const char* str, char c);
extern void* Luna_Alloc(size_t size);
extern void* Luna_Calloc(size_t size);
extern void  Luna_Free(void* ptr);
extern void* Luna_Realloc(void* ptr, size_t new_size);
#ifdef __cplusplus
}
#endif
#endif // LUNA_ASM_H