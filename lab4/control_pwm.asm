.equ portb, 0FE31h
.equ contr, 0FE33h

.org 0000h
    ljmp main

.org 000Bh      ; timer 0 ISR
    ; service routine
    ljmp ISR_timer0

.org 001Bh      ; timer 1 ISR
    ljmp ISR_timer1

.org 0100h
main:
    mov P1, #0FFh            ; clear port 1

    ; turn all pins into outputs for the 8255
    mov DPTR, #contr
    mov A, #80h
    movx @DPTR, A

    ; define global variable for motor movement (R4)
    ; no movement == #00h 
    ; move right == send #08h to L293D
    ; move left == send #10h
    ; move up == send #20h
    ; move down == send #40h 
    mov R4, #00h

    ; define global variable for duty cycle (R5)
    ; 01h means D=1
    ; 02h means D=0.5
    mov R5, #01h       

    ; define global variable for last PWM
    ; previously high == #01h
    ; previously low == #00h
    mov R6, #00h

    ; configure timer 0 and 1 for 8 bit auto reload
    ; timer 0 will be used to control keypad
    ; timer 1 will be used for PWM
    mov TMOD, #22h      
    mov TH0, #0x00
    mov TL0, #0xD0
    mov TH1, #0x00
    setb ET0                ; enale timer 0 interrupt
    setb ET1 
    setb EA                 ; global interrupt enable
    setb TR0                ; start timer
    setb TR1 

    mov DPTR, #portb        ; turn OFF outputs of L293D
    mov A, #0
    movx @DPTR, A
    
    mov R1, #00h            ; we will use P1 to keep track of last pressed

    sjmp *                  ; wait here for interrupts 

; ========================
; ========================
; TIMER 0 INTERRUPT SERVICE ROUTINE
; this timer gets inputs from the keypad 
; ========================
; ========================
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
    mov R4, A
    sjmp exit_ISR_timer0

check_right:
    cjne A, #0F5h, check_down
    mov A, #08h
    movx @DPTR, A
    mov R4, A
    sjmp exit_ISR_timer0

check_down:
    cjne A, #0F3h, check_up
    mov A, #40h
    movx @DPTR, A
    mov R4, A
    sjmp exit_ISR_timer0

check_up:
    cjne A, #0F2h, stop_movement
    mov A, #20h
    movx @DPTR, A
    mov R4, A
    sjmp exit_ISR_timer0

stop_movement:
    mov A, #00h
    movx @DPTR, A
    mov R4, A

; sets DT = 0.5
check_pwm_0:
    mov A, P1               ; reread P1 since it was overwritten before 
    cjne A, #0FFh, check_pwm_1
    mov R5, #02h
    sjmp exit_ISR_timer0

; sets DT = 1
check_pwm_1: 
    cjne A, #0FEh, exit_ISR_timer0
    mov R5, #01h

exit_ISR_timer0:
    pop PSW 
    pop acc
    reti

; ========================
; ========================
; TIMER 1 INTERRUPT SERVICE ROUTINE
; this timer handles the PWM
; ========================
; ========================
ISR_timer1:
    push acc
    push PSW

    mov DPTR, #portb
    mov A, R4
    jz exit_ISR_timer1

    ; this handles the PWM behavior
    ; if R5 == 2, we skip every other request (DT = 0.5)
    ; if R5 == 1, we service every request (DT = 1)
    
    cjne R5, #02h, go_high

toggle_high:
    cjne R6, #00h, toggle_low
    mov R6, #01h
    sjmp go_high

toggle_low:
    mov A, #00h
    mov @DPTR, A
    mov R6, A 
    sjmp exit_ISR_timer1

go_high:
    mov A, R4
    mov @DPTR, A

exit_ISR_timer1:
    pop PSW
    pop acc 
    reti


