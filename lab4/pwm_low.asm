.equ portb, 0FE31h
.equ contr, 0FE33h

.org 0000h
    ljmp main

.org 000Bh      ; timer ISR
    ; service routine
    ljmp ISR_timer0

.org 0100h
main:
    ; turn all pins into outputs for the 8255
    mov DPTR, #contr
    mov A, #80h
    movx @DPTR, A

    ; configure timer for 16 bit
    mov TMOD, #01h      
    mov TH0, #0000h
    mov TL0, #0000h
    mov R0, #14             ; for a 1s delay, we want 14 interrupts to go off before we toggle
    setb ET0                ; enale timer 0 interrupt
    setb EA                 ; global interrupt enable
    setb TR0                ; start timer

    mov DPTR, #portb        ; turn OFF outputs of L293D
    mov A, #0
    movx @DPTR, A
    
    mov R1, #00h            ; we will use P1 to keep track of high/low

    sjmp *                  ; wait here for interrupts 

ISR_timer0:
    clr TR0                 ; stop timer reload
    mov TH0, #0000h         ; reload is mandatory in 16 bit mode
    mov TL0, #0000h

    setb TR0                ; restart timer

    djnz R0, exit_ISR_timer0

    mov R0, #14             ; reset software counter
    mov A, R1               ; access high/low tracker
    xrl A, #40h             ; toggles bit (if 1 -> 0, if 0 -> 1)
    mov R1, A
    
    mov DPTR, #portb        ; update portb
    movx @DPTR, A

exit_ISR_timer0:
    reti

