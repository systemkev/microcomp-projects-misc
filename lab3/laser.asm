; simple program that draws a diagonal line

    .org 8000h
    .equ x_dac, 0xFE40
    .equ y_dac, 0xFE44

mov A, #00h

main:
    mov DPTR, #x_dac
    movx @DPTR, A

    mov DPTR, #y_dac 
    movx @DPTR, A 

    lcall delay

    inc A
    sjmp main

delay: 
    mov R2, #5
outer:
    mov R3, #5
inner:
    djnz R3, inner
    djnz R2, outer
    ret 



