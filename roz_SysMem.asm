bits 64
default rel
section .text
extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern HeapReAlloc

global Luna_WinMemset
global Luna_WinMemcpy
global Luna_MemMove
global Luna_MemSwap64
global Luna_ZeroFill
global Luna_GetTicks
global Luna_AtomicAdd64
global Luna_AtomicXchg64
global Luna_Prefetch
global Luna_CacheFlush
global Luna_MemIsZero
global Luna_BitScanForward
global Luna_StrLen
global Luna_StrChr
global Luna_Alloc
global Luna_Calloc
global Luna_Free
global Luna_Realloc

Luna_WinMemset:
    movzx edx, dl          ; расширяем байт до 64 бит
    mov rax, 0x0101010101010101
    imul rax, rdx          ; заполняем 8 байт одинаковым значением
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
    shr r10, 7            ; 128 байт за итерацию
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

Luna_WinMemcpy:
    push rdi
    push rsi
    mov rdi, rcx            ; Куда (Destination)
    mov rsi, rdx            ; Откуда (Source)
    mov rcx, r8             ; Сколько байт
    mov rax, rdi
    sub rax, rsi
    cmp rax, rcx
    jb .use_memmove         ; Если области перекрываются — идем в MemMove
    rep movsb               ; Самый надежный и быстрый способ на современных CPU
    jmp .exit
.use_memmove:
    pop rsi                 ; Восстанавливаем для вызова MemMove
    pop rdi
    jmp Luna_MemMove
.exit:
    mov rax, rdi            ; Возвращаем указатель
    pop rsi
    pop rdi
    ret

Luna_ZeroFill:
    test rdx, rdx
    jz .done
    push r8                ; Сохраняем R8
    mov r8, rdx            ; count для WinMemset (из RDX в R8)
    xor rdx, rdx           ; value = 0
    call Luna_WinMemset
    pop r8
.done:
    ret

Luna_MemMove:
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

Luna_MemSwap64:
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

Luna_GetTicks:
    rdtsc           ; Читает такты в EDX:EAX
    shl rdx, 32     ; Сдвигаем EDX (старшие 32 бита) в верхнюю часть RDX
    or rax, rdx     ; Склеиваем с EAX в 64-битный RAX
    shr rax, 16     ; ВОТ ОНА, МАГИЯ: Сдвигаем весь результат на 16 бит вправо
    ret
    
Luna_AtomicXchg64:
    mov rax, rdx
    xchg [rcx], rax        ; XCHG атомарен сам по себе
    ret

Luna_AtomicAdd64:
    lock add [rcx], rdx    ; Префикс LOCK делает операцию неделимой
    ret

Luna_Prefetch:
    prefetcht0 [rcx]       ; Загрузить данные в L1 кэш заранее
    ret

Luna_CacheFlush:
    clflush [rcx]          ; Сбросить линию кэша (принудительное чтение из RAM)
    ret

Luna_MemIsZero:
    test rdx, rdx
    jz .is_zero
    mov r8, rdx
    shr r8, 4       ; r8 = количество блоков по 16 байт
    jz .tail        ; Если меньше 16 байт, идем в хвост
.simd_loop:
    movdqu xmm1, [rcx]
    ptest xmm1, xmm1
    jnz .not_zero
    add rcx, 16
    dec r8
    jnz .simd_loop
.tail:
    and rdx, 15     ; rdx теперь содержит ТОЛЬКО остаток (0-15 байт)
    jz .is_zero
    test rdx, 8
    jz .byte_check
    cmp qword [rcx], 0
    jne .not_zero
    add rcx, 8
.byte_check:
    and rdx, 7      ; rdx теперь содержит остаток (0-7 байт)
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

Luna_BitScanForward:
    bsf rax, rcx
    jz .empty
    ret
.empty:
    mov rax, -1
    ret

Luna_StrLen:
    xor rax, rax
.loop:
    cmp byte [rcx + rax], 0
    je .done
    inc rax
    cmp rax, 1024           ; ЗАЩИТА: если символ > 1КБ, это мусор
    jae .done
    jmp .loop
.done:
    ret

Luna_StrChr:
    mov rax, rcx        ; rax = указатель на строку (первый аргумент)
    movzx edx, dl       ; edx = символ для поиска (второй аргумент в dl)
.search:
    mov cl, [rax]       ; Берем текущий символ
    test cl, cl         ; Конец строки?
    jz .not_found
    cmp cl, dl          ; Сравниваем с искомым
    je .found
    inc rax
    jmp .search
.found:
    ret
.not_found:
    xor rax, rax
    ret

Luna_Alloc:
    sub rsp, 48             ; 32 (Shadow) + 16 (Alignment)
    mov r8, rcx             ; Размер
    call GetProcessHeap
    mov rcx, rax            ; Handle
    xor rdx, rdx            ; Flags = 0
    call HeapAlloc
    add rsp, 48
    ret

Luna_Calloc:
    sub rsp, 48             ; Было 40 — ЭТО ПРИЧИНА КРАША
    mov r8, rcx             ; Размер
    call GetProcessHeap
    mov rcx, rax            ; Хэндл кучи
    mov rdx, 8              ; HEAP_ZERO_MEMORY
    call HeapAlloc
    add rsp, 48
    ret

Luna_Free:
    test rcx, rcx
    jz .done
    sub rsp, 48
    mov r8, rcx             ; Указатель на блок
    call GetProcessHeap
    mov rcx, rax            ; Handle
    xor rdx, rdx            ; Flags = 0
    call HeapFree
    add rsp, 48
.done:
    ret

Luna_Realloc:
    sub rsp, 48             ; Исправлено с 40 на 48
    mov r9, rdx             ; Новый размер
    mov r8, rcx             ; Старый указатель
    call GetProcessHeap
    mov rcx, rax
    xor rdx, rdx
    call HeapReAlloc
    add rsp, 48
    ret