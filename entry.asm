bits 64
default rel

section .text
global _start
extern kmain
extern __bss_start
extern __bss_end

_start:
    cld
    mov rdi, __bss_start
    mov rcx, __bss_end
    sub rcx, rdi
    xor eax, eax
    rep stosb

    and rsp, -16
    sub rsp, 40
    call kmain
.halt:
    cli
    hlt
    jmp .halt