    .equ portA, 0FE30h
    .equ portB, 0FE31h
    .equ portC, 0FE32h
    .equ control, 0FE33h

.org 00h                    ; reset vector
    ljmp main              ; go to 100h

.org 100h                   ; locate "start" at 100h in memory 
main:
    ; initiate all ports of the 8255 as outputs
    mov DPTR, #control
    mov A, #80h
    movx @DPTR, A

    ; set up serial port and use timer 1 for 9600 baud comm
    mov tmod, #20h
    mov tcon, #40h
    mov th1, #0FDh
    mov scon, #50h

main_loop:
    lcall getchr        ; get character from keyboard
    lcall sndchr        ; echo character to the PC screen 

    mov R0, #2             ; go through 24 steps 
    sjmp spin

getchr:
    jnb ri, getchr          ; wait for char to arrive
    mov A, sbuf             ; char arrives at sbuf -> move to A
    anl A, #7Fh             ; ASCII only needs bottom 7 bits, clear 8th
    clr ri                  ; clear flag
    ret
sndchr:
    clr scon.1
    mov sbuf, A
txloop:
    jnb scon.1, txloop
    ret

spin:
    mov DPTR, #portb
    mov A, #08h
    movx @DPTR, A 
    lcall delay

    mov A, #20h 
    movx @DPTR, A 
    lcall delay

    mov A, #10h
    movx @DPTR, A 
    lcall delay

    mov A, #40h
    movx @DPTR, A 
    lcall delay

    djnz R0, spin

    sjmp main_loop

delay:
    push acc

    mov R5, #03h
outer:
    mov R6, #0FFh
middle:
    mov R7, #0FFh
inner:
    djnz R7, inner
    djnz R6, middle
    djnz R5, outer

    pop acc
    ret



