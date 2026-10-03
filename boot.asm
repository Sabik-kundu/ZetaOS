[bits 16]
[org 0xC700]

KERNEL_SEG equ 0x1000
KERNEL_SECTORS equ 120
KERNEL_ADDR equ 0x10000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xC700
    sti
    mov [boot_drive], dl

    mov si, msg_boot
    call print16

    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc disk_error

    in al, 0x92
    or al, 2
    out 0x92, al

    cli
    lgdt [gdr_ptr]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08: pm32

print16:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bx, 7
    int 0x10
    jmp print16

.done:
    ret

disk_error:
    mov si, msg_err
    call print16
    cli
.hang:
    hlt
    jmp .hang

; -- 32-bit protected mode unlocked --

[bits 32]
pm32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    mov edi, 0x70000
    xor eax, eax
    mov ecx, 3072
    rep stosd
    mov dword [0x70000], 0x71003
    mov dword [0x71000], 0x72003  
    mov dword [0x72000], 0x00000083
    mov dword [0x72008], 0x00200083

    mov eax, 0x70000
    mov cr3, eax
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    jmp 0x18:lm64

; -- 64-bit Hyper active Long Mode --

[bits 64]
lm64:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000
    mov rax, KERNEL_ADDR
    jmp rax

boot_drive: db 0
msg_boot:   db "zetaOS: booting...", 13, 10, 0
msg_err:    db "zetaOS: disk read error", 13, 10, 0
 
align 4
dap:
    db 0x10, 0
    dw KERNEL_SECTORS
    dw 0x0000, KERNEL_SEG
    dq 1 

align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00AF9A000000FFFF
gdt_end:
gdt_ptr:
    dw gdt_end - gdt - 1
    dd gdt

times 510-($-$$) db 0
dw 0xAA55