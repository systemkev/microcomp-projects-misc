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

    ; configure timer for 8 bit
    mov TMOD, #01h      
    mov TH0, #0xFF
    mov TL0, #0xF0 
    setb ET0                ; enale timer 0 interrupt
    setb EA                 ; global interrupt enable
    setb TR0                ; start timer

    mov R0, #04h            ; counter
    mov R1, #0b00001000     ; start with 1 ON
    mov R2, #064h           ; counter for ISR

    ; output 1 on = 0000_1000
    ; output 2 on = 0001_0000
    ; output 3 on = 0010_0000
    ; output 4 on = 0100_0000

    sjmp *                  ; wait here for interrupts 

ISR_timer0:
    push acc
    clr TR0
    mov TH0, #3Ch           
    mov TL0, #0B0h
    setb TR0

    djnz R2, ISR_exit
    mov R2, #64h            ; reload 

    djnz R0, continue
    
; branch not taken!
    mov R0, #04h            ; reload counter
    mov R1, #0b00001000     ; reload
    sjmp update_hardware

; branch taken
continue:
    mov A, R1           ; fetch current status
    rl A                ; rotate (basically jumps to the next one to be on)
    mov R1, A

update_hardware:
    mov DPTR, #portb        ; send out data to port B
    mov A, R1
    movx @DPTR, A

ISR_exit:
    pop acc
    reti


