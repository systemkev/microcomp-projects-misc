.equ portb, 0FE31h
.equ contr, 0FE33h

.org 8000h
main:
    ; turn all pins into outputs for the 8255
    mov DPTR, #contr
    mov A, #80h
    movx @DPTR, A

loop:
    ; toggle on the fourth output
    mov DPTR, #portb
    mov A, #40h
    movx @DPTR, A

    lcall delay

    ; toggle off all outputs
    mov DPTR, #portb
    mov A, #00h
    movx @DPTR, A

    lcall delay

    sjmp loop

; 5 second delay loop
delay:
    mov R0, #010h
outer:
    mov R1, #0FFh 
middle:
    mov R2, #0FFh
inner:
    djnz R2, inner
    djnz R1, middle
    djnz R0, outer
    ret


