.equ portb, 0FE31h
.equ contr, 0FE33h

.org 0000h
    ljmp main

.org 000Bh      ; timer ISR
    ; service routine
    ljmp ISR_timer0

.org 0100h
main:
    mov P1, #0FFh            ; clear port 1

    ; turn all pins into outputs for the 8255
    mov DPTR, #contr
    mov A, #80h
    movx @DPTR, A

    ; configure timer 0 for 8 bit auto reload
    mov TMOD, #02h      
    mov TH0, #0x00
    mov TL0, #0xD0
    setb ET0                ; enale timer 0 interrupt
    setb EA                 ; global interrupt enable
    setb TR0                ; start timer

    mov DPTR, #portb        ; turn OFF outputs of L293D
    mov A, #0
    movx @DPTR, A
    
    mov R1, #00h            ; we will use P1 to keep track of last pressed

    sjmp *                  ; wait here for interrupts 

ISR_timer0:
    push acc                ; protect acc and PSW
    push PSW            

    setb TR0                ; restart timer

    mov A, P1               ; get current state of keypad
    mov DPTR, #portb       ; fetch address of port b
    
    ; move right == send #08h to L293D
    ; move left == send #10h
    ; move up == send #20h
    ; move down == send #40h 

check_left:
    cjne A, #0F9h, check_right
    mov A, #10h
    movx @DPTR, A
    sjmp exit_ISR_timer0

check_right:
    cjne A, #0F5h, check_down
    mov A, #08h
    movx @DPTR, A
    sjmp exit_ISR_timer0

check_down:
    cjne A, #0F3h, check_up
    mov A, #40h
    movx @DPTR, A
    sjmp exit_ISR_timer0

check_up:
    cjne A, #0F2h, stop_movement
    mov A, #20h
    movx @DPTR, A
    sjmp exit_ISR_timer0

stop_movement:
    mov A, #00h
    movx @DPTR, A

exit_ISR_timer0:
    pop PSW 
    pop acc
    reti


