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

; read sector into memory
; see https://www.ctyme.com/intr/rb-0607.htm
; AH = 02h
    mov ah, 0x02
; AL = number of sectors to read (must be nonzero)
    mov al, 1 ; read one sector
; CH = low eight bits of cylinder number
    mov ch, 0
; CL = sector number 1-63 (bits 0-5)
    mov cl, 2 ; read sector 2 (sector numbers start at 1 for CHS)
; high two bits of cylinder (bits 6-7, hard disk only)
; DH = head number
    mov dh, 0
; DL = drive number (bit 7 set for hard disk) => automatically set when bios boots 
; ES:BX -> data buffer
    mov bx, buffer
    int 0x13
    jc error ; if the carry flag is set (there is an error in the interrupt)
    mov si, buffer
    call print
    jmp $

error:
    mov si, error_message
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

error_message: db "Failed to load sector", 0

; fill at least 510 bytes of data
times 510-($ - $$) db 0

; the remaining 2 bytes will be filled with 55 AA (little endian)
; these need to be at byte 511 and 512
dw 0xAA55 ; dw will put 2 bytes(one word) into the file

; set a label where to write from disk
; this will reference RAM memory just past the boot sector
; the BIOS just loads one sector for booting, to this is just a lable, it won't be loaded
buffer: