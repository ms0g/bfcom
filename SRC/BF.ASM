.model tiny
.data
filename db 13 dup(0)
buffer   db 512 dup(0)
.code
org 100h         

extrn _interpret:near

start:
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
    
    ; Read up to 511 bytes from file into buffer
    mov ah, 3Fh
    mov cx, 511
    lea dx, buffer
    int 21h
    jc read_fail
    
    mov si, ax                  ; AX = number of bytes actually read
    mov byte ptr buffer[si], 0  ; Null-terminate buffer at end of data read
    
    push ds
    push offset buffer
    call _interpret
    pop ax
    pop ds

    ; Close the file handle
    mov ah, 3Eh
    int 21h
    jmp done
open_fail:
    ; handle open error
    mov dx, offset msg_open_fail
    call print
    jmp done
read_fail:
    ; handle read error
    mov dx, offset msg_read_fail
    call print
    jmp done
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
