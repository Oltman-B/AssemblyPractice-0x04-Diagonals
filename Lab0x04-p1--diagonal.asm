section .data

space db 0x20 ; Space character
new_line db 0x0A ; New line character

section .bss

; Reserve memory for buffer
buffer resb 512
buffer_size equ $ - buffer

spaceCount resb 1

bytes_read resb 1
buffer_offset resb 1        ; Used to store offset into buffer for printing


section .text
    global _start

_start:

do:
    ; Read into buffer
    mov edx, buffer_size
    mov ecx, buffer
    mov ebx, 0
    mov eax, 3
    int 0x80

    ; Store count of bytes actually read
    mov [bytes_read], eax
    cmp eax, 0
    jnz process_input       ; System read not return 0, process data
    jmp end_while           ; Else, no bytes read, (eof) exit loop

process_input:
    mov ecx, [bytes_read]       ; Set loop index to number of bytes read
process_loop:
    xor ebx, ebx                ; Clear ebx to 0
    mov bl, [bytes_read]
    sub ebx, ecx                ; Calculate offset by subtracting current 'index' from bytes read
                                ; This effectively makes offset increment from 0
    mov [buffer_offset], ebx    ; Store offset index in buffer_offset
    push ecx                    ; Save index on stack so ecx can be used for print

    ; Print spaces before each character
    mov cl, [spaceCount]       ; Store spaceCount in index register
    cmp cl, 0
    jz end_no_space            ; If space count is 0, skip space loop
space_loop:
    mov edx, 1                  ; System to print 1 character (byte) per loop iter
    push ecx                     ; Save index
    mov ecx, space            ; Print space character
    mov ebx, 1                  ; Standard out
    mov eax, 4                  ; System-write
    int 0x80
    pop ecx                     ; Restore index
loop space_loop
end_no_space:
    
    ; Print next character in buffer
    mov edx, 1                  ; System to print 1 character (byte) per loop iter
    xor eax, eax                ; Zero eax
    mov eax, buffer             ; Move start addr of buffer into eax
    add eax, [buffer_offset]    ; Add offset to buffer address to get next char index
    push eax                    ; Store value of current character addr on stack
    mov ecx, eax              ; Pass calculated addr of next character in buffer to system call
    mov ebx, 1                  ; Standard out
    mov eax, 4                  ; System-write
    int 0x80

    ; Handle case where last character was new line.
    pop ebx                ; Pop address of last character to ebx. 
    cmp byte [ebx], 0x0A   ; Check to see if last printed character is new line
                                         ; is new line character, if it is, reset space count to 0.
    jnz endif                            ; If last char was not new line, don't set space count to 0
    mov byte [spaceCount], 0             ; Reset space count to 0 after new line
    jz skip_new_line                     ; Skip printing new line if last character was a new line.
endif:    
    ; Print new line
    mov edx, 1
    mov ecx, new_line
    mov ebx, 1
    mov eax, 4
    int 0x80
    inc byte [spaceCount]            ; Increment space count after each character is printed
skip_new_line:
    pop ecx                     ; Restore index into ecx for decrementing
    dec ecx
    jnz process_loop            ; code segment too long for loop, had to switch to manual decrement
    ; Processing loop finished, return to top of outer loop
    jmp do                      ; Check for more data to read
end_while:

; End program
mov eax, 1
mov ebx, 0
int 0x80
