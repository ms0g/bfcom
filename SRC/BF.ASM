.model tiny
.data
BUFFER_SIZE equ 10000
TAPE_SIZE   equ 30000

filename db 13 dup(?)
buffer   db BUFFER_SIZE dup(?)
tape     db TAPE_SIZE dup(?)

.code
org 100h         

extrn _interpret:near

start:
    mov di, offset tape
    xor al, al
    mov cx, 30000
    rep stosb
    ; Get the command line from the PSP
    mov si, 80h                 ; SI = offset 0x80 in PSP = length of command line tail
    mov cl, [si]                ; CL = number of characters in command line tail
    mov si, 81h                 ; SI = offset 0x81 in PSP = start of command line tail string
    xor ch, ch
    lea di, filename 
cpy_loop:
    lodsb                       ; Load byte from DS:SI into AL and increment SI
    cmp al, 0Dh                 ; Check for carriage return (end of command line)
    je cpy_done                 ; If CR, end copying
    cmp al, ' '                 
    je cpy_loop                 ; Skip spaces, load next char
    stosb                       ; Store AL into ES:DI and increment DI
    loop cpy_loop
cpy_done:
    xor al, al                  ; Null-terminate the filename string
    stosb 
    
    ; Open the file specified by filename (read-only)
    mov ah, 3Dh
    xor al, al                  ; Read-only mode (0)
    lea dx, filename            ; DS:DX points to filename
    int 21h
    jc open_fail    
    mov bx, ax                  ; Save returned file handle in BX
    
    ; Read up to XXX bytes from file into buffer
    mov ah, 3Fh
    mov cx, BUFFER_SIZE - 1
    lea dx, buffer
    int 21h
    jc read_fail
    
    mov si, ax                  ; AX = number of bytes actually read
    mov byte ptr buffer[si], 0  ; Null-terminate buffer at end of data read
    
    push ds
    push offset tape
    push offset buffer
    call _interpret
    pop ax
    pop ax
    pop ds
    jmp close_file
open_fail:
    ; handle open error
    mov dx, offset msg_open_fail
    call print
    jmp done
read_fail:
    ; handle read error
    mov dx, offset msg_read_fail
    call print
close_file:
    mov ah, 3Eh
    int 21h
done: 
    mov ax, 4c00h
    int 21h

print:
    mov ah, 09h
    int 21h
    ret

msg_open_fail db 'Open failed$'
msg_read_fail db 'Read failed$'

end start
