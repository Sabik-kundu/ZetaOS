bits 16

kernel_start:
    mov ah, 0x0E
    mov al, 'B'
    int 0x10

    mov al, 'O'
    int 0x10

    mov al, 'K'
    int 0x10

    mov al, 'A'
    int 0x10

hang:
    jmp hang

    