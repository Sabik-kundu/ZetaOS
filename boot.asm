org 0x7C00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, msg_loading
    call print_string

    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, 16
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    mov si, msg_ok
    call print_string

    jmp 0x1000:0x0000

disk_error:
    mov si, msg_error
    call print_string
    jmp $

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp print_string
.done:
    ret

msg_loading:
    db "BokaOS: Loading kernel...", 0x0D, 0x0A, 0
msg_ok:
    db "OK", 0x0D, 0x0A, 0
msg_error:
    db "Disk read error!", 0x0D, 0x0A, 0
msg_error:
    db "Disk read error", 0x0D, 0x0A, 0
boot_drive:
    db 0

times 510 - ($-$$) db 0
dw 0xAA55