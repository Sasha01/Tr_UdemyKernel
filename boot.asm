; set origin to address 0
; we will use segment registers to make sure the actual address is 0x7C00
ORG 0

BITS 16 ; assemble should only use 16 bit codes

; Preparing the image to run on a real HW
; first 3 bytes of BPB
_start:
    jmp short start
    nop

; fill in the rest of BPB (33 bytes) with 0s
times 33 db 0

start:
    jmp 0x7C0:step2 ; this will make the CS (code segment) = 0x7C0

; implement interrupt 0; this is a divide by 0 exception
handle_zero:
    mov ah, 0x0E
    mov al, 'A' ; print A
    mov bx, 0
    int 0x10
    iret

; implement interrupt 1
handle_one:
    mov ah, 0x0E
    mov al, 'V' ; print V
    mov bx, 0
    int 0x10
    iret

step2:
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

    ; add interrupts to the vector table
    mov word[ss:0x00], handle_zero
    mov word[ss:0x02], 0x7C0
    mov word[ss:0x04], handle_one
    mov word[ss:0x06], 0x7C0

    ; trigger a divide by 0 exception
    mov ax, 0
    div ax
    ; trigger interrupt 1
    int 1

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