.org 00h
ljmp main

.org 200h
keytab:
    .db 10h, 33h, 32h, 31h
    .db 20h, 36h, 35h, 34h
    .db 00h, 39h, 38h, 37h
    .db 00h, 00h, 30h, 00h

.org 100h
main: 
    lcall init
    mov dptr, #keytab
    clr P1.7
    clr P1.6
    clr P1.5
    clr P1.4

main_loop: 
    ; get num1
    mov R0, #30h                ; location for storage of num1
    mov R1, #03h                ; 3 digit counter
    lcall get_input
    lcall new_line

    ; get num2
    mov R0, #33h                ; location for storage of num2
    mov R1, #03h
    lcall get_input 
    lcall new_line

    ; convert ascii nums to hex nums
    mov R0, #30h
    mov R1, #36h
    lcall convert_to_bin

    mov R0, #33h
    mov R1, #37h 
    lcall convert_to_bin

    ; get operation
    mov R0, #38h
    mov R1, #01h
    lcall get_input

    mov R0, #39h                ; store add/sub result
    check_1:                    ; check for addition
    cjne A, #10h, check_2
    lcall add_num
    lcall ascii_result
    sjmp main_loop

    check_2:                    ; check for subtraction
    cjne A, #20h, main_loop
    lcall sub_num
    lcall ascii_result
    sjmp main_loop

ascii_result:
    mov A, @R0                  ; get result of operation
    mov R3, #03h
    loop:
        inc R0
        mov B, #0Ah
        div AB
        mov R2, A
        mov A, B
        add A, #30h
        mov @R0, A
        mov A, R2
        djnz R3, loop
    mov R3, #03h
    send:
        clr ti
        mov sbuf, @R0
        jnb ti, *
        dec R0
        djnz R3, send
    lcall new_line
    ret

get_input:
    jnb P3.4, *                         ; check if data is available 
    mov A, P1                           ; move the input to the accumulator
    movc A, @A+dptr                     
    clr ti
    mov sbuf, A
    jnb ti, *
    jb P3.4, *
    mov @R0, A
    inc R0
    djnz R1, get_input
    ret

new_line:
    clr ti
    mov A, #0DH
    mov sbuf, A
    l1:
        jnb ti, l1
    
    clr ti
    mov A, #0AH
    mov sbuf, A
    l2:
        jnb ti, l2
    clr ti
    ret 

add_num:
    mov A, 36h
    mov B, 37h                   
    add A, B
    mov @R0, A
    clr ti
    mov sbuf, #2Bh
    jnb ti, *
    lcall new_line
    ret

sub_num:
    clr C
    mov A, 36h
    mov B, 37h 
    clr C
    subb A, B
    mov @R0, A
    clr ti
    mov sbuf, #2Dh
    jnb ti, *
    lcall new_line
    ret

convert_to_bin: 
    mov A, @R0
    clr C
    subb A, #30h
    mov B, #64h
    mul AB
    push ACC

    inc R0
    mov A, @R0
    clr C
    subb A, #30h
    mov B, #0Ah
    mul AB
    push ACC
    
    inc R0
    mov A, @R0
    clr C
    subb A, #30h
    pop 0F0h                            ; load into B register
    add A, B
    pop 0F0h
    add A, B

    mov @R1, A
    ret

init: 
; initialize all serial communications
    mov tmod, #20h              ; timer 1 on, 0 off
    mov th1, #0FDh              ; set TH1 to 253 for 9600 baud rate
    mov tcon, #40h              ; 0100_0000 (1 turns on timer 1)
    mov scon, #50h              ; enables REN and 8 bit UART
    ret

