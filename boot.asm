[bits 16]
[org 0x7C00]

KERNEL_SEG     equ 0x1000          ; 0x1000:0000 = physical 0x10000
KERNEL_SECTORS equ 120             ; 60 KB max kernel (linker.ld asserts this)
KERNEL_ADDR    equ 0x10000
DISK_RETRIES   equ 3

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [boot_drive], dl

    mov ax, 0x0003
    int 0x10

    mov si, msg_boot
    call print16

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb no_long_mode
    mov eax, 0x80000001
    cpuid
    bt edx, 29
    jnc no_long_mode

    mov byte [retries], DISK_RETRIES
.try_read:
    mov word [dap_count], KERNEL_SECTORS
    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jnc .loaded
    mov [disk_status], ah
    xor ax, ax
    mov dl, [boot_drive]
    int 0x13
    dec byte [retries]
    jnz .try_read
    jmp disk_error
.loaded:

    
    in al, 0x92
    or al, 2
    out 0x92, al

    ; --- enter protected mode ---
    cli
    lgdt [gdt_ptr]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pm32

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

print_hex8:
    mov cl, al
    shr al, 4
    call .nib
    mov al, cl
.nib:
    and al, 0x0F
    cmp al, 10
    sbb al, 0x69
    das
    mov ah, 0x0E
    mov bx, 7
    int 0x10
    ret

disk_error:
    mov si, msg_err
    call print16
    mov al, [disk_status]
    call print_hex8
    jmp halt16

no_long_mode:
    mov si, msg_nolm
    call print16
halt16:
    cli
.hang:
    hlt
    jmp .hang

; ---------------- 32-bit protected mode ----------------
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

; ---------------- 64-bit long mode ----------------
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

; ---------------- data ----------------
boot_drive:  db 0
retries:     db 0
disk_status: db 0
msg_boot:   db "zetaOS: booting...", 13, 10, 0
msg_err:    db "zetaOS: disk read error 0x", 0
msg_nolm:   db "zetaOS: 64-bit CPU required", 13, 10, 0

align 4
dap:
    db 0x10, 0
dap_count:
    dw KERNEL_SECTORS
    dw 0x0000, KERNEL_SEG
    dq 1                     ; start at LBA 1

align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF   ; 0x08 code32
    dq 0x00CF92000000FFFF   ; 0x10 data
    dq 0x00AF9A000000FFFF   ; 0x18 code64
gdt_end:
gdt_ptr:
    dw gdt_end - gdt - 1
    dd gdt

times 510-($-$$) db 0
dw 0xAA55