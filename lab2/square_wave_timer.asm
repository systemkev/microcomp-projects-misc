    .org 0000h
    ljmp main

    .org 000Bh          ; timer 0 interrupt vector
        cpl P1.0
        reti

    .org 0100h

main:
    mov P1, #00h
    mov DPTR, #9000h        ; get byte at 9000h to use for timer
    movx A, @DPTR           ;

    mov TMOD, #02h          ; set mode to timer 0 on (mode 2 autoreload)
    mov TH0, A              ; load timer value into TH0
    mov IE, #82h            ; enable all + enable timer 0 ISR

    setb TR0

loop:
    sjmp loop


