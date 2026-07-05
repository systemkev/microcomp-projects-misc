.org 00h 
ljmp main

.org 200h
keytab:
    .db 00h, 33h, 32h, 31h
    .db 00h, 36h, 35h, 34h
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
    jnb P3.4, *                         ; check if data is available 
    mov A, P1                           ; move the input to the accumulator
    movc A, @A+dptr                     ; convert # in A from keypad to ascii
    clr ti
    mov sbuf, A
    jnb ti, *
    jb P3.4, *
    sjmp main_loop

init:
    ; set up serial port and use timer 1 for 9600 baud comm
    mov tmod, #20h
    mov tcon, #40h
    mov th1, #0FDh
    mov scon, #50h
    ret


