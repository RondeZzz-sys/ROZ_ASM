bits 64
default rel
section .text
extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern HeapReAlloc

global roz_WinMemset
global roz_WinMemcpy
global roz_MemMove
global roz_MemSwap64
global roz_ZeroFill
global roz_GetTicks
global roz_AtomicAdd64
global roz_AtomicXchg64
global roz_Prefetch
global roz_CacheFlush
global roz_MemIsZero
global roz_BitScanForward
global roz_StrLen
global roz_StrChr
global roz_Alloc
global roz_Calloc
global roz_Free
global roz_Realloc

roz_WinMemset:
    movzx edx, dl
    mov rax, 0x0101010101010101
    imul rax, rdx
    cmp r8, 128
    jb .small
    mov r9, rcx
    and r9, 15
    jz .aligned
    mov r10, 16
    sub r10, r9
    sub r8, r10
.align_loop:
    mov [rcx], al
    inc rcx
    dec r10
    jnz .align_loop
.aligned:
    movd xmm0, eax
    pshufd xmm0, xmm0, 0
    movlhps xmm0, xmm0
    mov r10, r8
    shr r10, 7
.big_loop:
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm0
    movdqu [rcx+32], xmm0
    movdqu [rcx+48], xmm0
    movdqu [rcx+64], xmm0
    movdqu [rcx+80], xmm0
    movdqu [rcx+96], xmm0
    movdqu [rcx+112], xmm0
    add rcx, 128
    dec r10
    jnz .big_loop
    and r8, 127
.small:
    mov r10, r8
    shr r10, 3
    jz .tail_bytes
.qword_loop:
    mov [rcx], rax
    add rcx, 8
    dec r10
    jnz .qword_loop
.tail_bytes:
    and r8, 7
    jz .done
.byte_loop:
    mov [rcx], al
    inc rcx
    dec r8
    jnz .byte_loop
.done:
    ret

roz_WinMemcpy:
    push rdi
    push rsi
    mov rdi, rcx
    mov rsi, rdx
    mov rcx, r8
    mov rax, rdi
    sub rax, rsi
    cmp rax, rcx
    jb .use_memmove
    rep movsb
    jmp .exit
.use_memmove:
    pop rsi
    pop rdi
    jmp roz_MemMove
.exit:
    mov rax, rdi
    pop rsi
    pop rdi
    ret

roz_ZeroFill:
    test rdx, rdx
    jz .done
    push r8
    mov r8, rdx
    xor rdx, rdx
    call roz_WinMemset
    pop r8
.done:
    ret

roz_MemMove:
    mov rax, rcx 
    cmp rcx, rdx
    jbe .forward
    add rcx, r8
    add rdx, r8
    mov r9, r8
    shr r9, 3
    jz .back_remainder
.back_qword:
    sub rdx, 8
    sub rcx, 8
    mov r10, [rdx]
    mov [rcx], r10
    dec r9
    jnz .back_qword
.back_remainder:
    and r8, 7
    jz .done
.back_byte:
    dec rdx
    dec rcx
    mov r9b, [rdx]
    mov [rcx], r9b
    dec r8
    jnz .back_byte
    ret
.forward:
    mov r9, r8
    shr r9, 4
    jz .forward_tail
.forward_simd:
    movdqu xmm0, [rdx]
    movdqu [rcx], xmm0
    add rdx, 16
    add rcx, 16
    dec r9
    jnz .forward_simd
.forward_tail:
    and r8, 15
    mov r9, r8
    shr r9, 3
    jz .forward_byte
.forward_qword:
    mov r10, [rdx]
    mov [rcx], r10
    add rdx, 8
    add rcx, 8
    dec r9
    jnz .forward_qword
.forward_byte:
    and r8, 7
    jz .done
.forward_byte_loop:
    mov r9b, [rdx]
    mov [rcx], r9b
    inc rdx
    inc rcx
    dec r8
    jnz .forward_byte_loop
.done:
    ret

roz_MemSwap64:
.sw:
    mov rax, [rcx]
    mov r9, [rdx]
    mov [rdx], rax
    mov [rcx], r9
    add rcx, 8
    add rdx, 8
    sub r8, 1
    jnz .sw
    ret

roz_GetTicks:
    rdtsc
    shl rdx, 32
    or rax, rdx
    shr rax, 16
    ret
    
roz_AtomicXchg64:
    mov rax, rdx
    xchg [rcx], rax
    ret

roz_AtomicAdd64:
    lock add [rcx], rdx
    ret

roz_Prefetch:
    prefetcht0 [rcx]
    ret

roz_CacheFlush:
    clflush [rcx]
    ret

roz_MemIsZero:
    test rdx, rdx
    jz .is_zero
    mov r8, rdx
    shr r8, 4
    jz .tail
.simd_loop:
    movdqu xmm1, [rcx]
    ptest xmm1, xmm1
    jnz .not_zero
    add rcx, 16
    dec r8
    jnz .simd_loop
.tail:
    and rdx, 15
    jz .is_zero
    test rdx, 8
    jz .byte_check
    cmp qword [rcx], 0
    jne .not_zero
    add rcx, 8
.byte_check:
    and rdx, 7
    jz .is_zero
.byte_loop:
    cmp byte [rcx], 0
    jne .not_zero
    inc rcx
    dec rdx
    jnz .byte_loop
.is_zero:
    mov eax, 1
    ret
.not_zero:
    xor eax, eax
    ret

roz_BitScanForward:
    bsf rax, rcx
    jz .empty
    ret
.empty:
    mov rax, -1
    ret

roz_StrLen:
    xor rax, rax
.loop:
    cmp byte [rcx + rax], 0
    je .done
    inc rax
    cmp rax, 1024
    jae .done
    jmp .loop
.done:
    ret

roz_StrChr:
    mov rax, rcx
    movzx edx, dl
.search:
    mov cl, [rax]
    test cl, cl
    jz .not_found
    cmp cl, dl
    je .found
    inc rax
    jmp .search
.found:
    ret
.not_found:
    xor rax, rax
    ret

roz_Alloc:
    sub rsp, 48
    mov r8, rcx
    call GetProcessHeap
    mov rcx, rax
    xor rdx, rdx
    call HeapAlloc
    add rsp, 48
    ret

roz_Calloc:
    sub rsp, 48
    mov r8, rcx
    call GetProcessHeap
    mov rcx, rax
    mov rdx, 8
    call HeapAlloc
    add rsp, 48
    ret

roz_Free:
    test rcx, rcx
    jz .done
    sub rsp, 48
    mov r8, rcx
    call GetProcessHeap
    mov rcx, rax
    xor rdx, rdx
    call HeapFree
    add rsp, 48
.done:
    ret

roz_Realloc:
    sub rsp, 48
    mov r9, rdx
    mov r8, rcx
    call GetProcessHeap
    mov rcx, rax
    xor rdx, rdx
    call HeapReAlloc
    add rsp, 48
    ret