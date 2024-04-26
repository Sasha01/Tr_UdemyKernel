; set origin to address 0
; we will use segment registers to make sure the actual address is 0x7C00
ORG 0

BITS 16 ; assemble should only use 16 bit codes

start:
    cli ; clear interrupts

    ; starting critical section

    mov ax, 0x7C0
    mov ds, ax ; set data segment
    mov es, ax ; set extra segment

    ; set the stack segment to 0x00, because we will use just the stack pointer
    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7C00

    ; ending critical section
    sti ; enable interrupts
    
    mov si, message ; move the address of the label "message" into the SI reg
    call print
    jmp $ ; jump to itself so we never return

print:
; we set BX reg to 0
; interrupt 0x10 will consider BL = foreground color, BH = page number
; we don't care about this at the moment
    mov bx, 0
; a label with a "." is local, only applies to the label above, in this case "print"
.loop: 
    lodsb ; load the char that the SI register points to into AL and increment SI
    cmp al, 0 ; compare AL with 0
    je .done ; if the comparison is true, jump to .done label
    call print_char 
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh ; load 0x0E into AH register to be used by the interrupt
    ; interrupt 0x10 will output the character from register AL 
    int 0x10 ; trigger the BIOS interrupt 0x10 - see Ralf Brown's interrupt list
    
    ret ; return

; db -> put to file the following bytes
message: db 'Hello World!', 0

; fill at least 510 bytes of data
times 510-($ - $$) db 0

; the remaining 2 bytes will be filled with 55 AA (little endian)
; these need to be at byte 511 and 512
dw 0xAA55 ; dw will put 2 bytes(one word) into the file