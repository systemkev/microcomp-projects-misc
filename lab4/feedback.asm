; ==========================================
; kevin toledo fernandez
; 8051 prop-ctrl & lcd telemetry
; io: dac fe00h, adc fe10h, 8255 fe30h
; logic: vout = (vref - vadc) * gain | clamp 00-ffh
; timing: t0 @ 125hz
; regs: r1=gain, r2=vref, r3=vadc
; subs: isr, write_cmd/data, print_num
; ==========================================
    .equ dac, 0FE00h
    .equ adc, 0FE10h
    .equ portA, 0FE30h
    .equ portB, 0FE31h
    .equ portC, 0FE32h
    .equ control, 0FE33h

    .org 0000h
    ljmp main

    .org 000Bh      ; timer 0 ISR
    ; service routine
    ljmp ISR_timer0

    .org 001Bh      ; Timer 1 ISR 
    ljmp ISR_timer1

    .org 0100h
main:
    ; ==========================================
    ; define global variables 
    ; ==========================================
    ; gain in R1
    mov R1, #2
    ; reference voltage in R2 
    mov R2, #80h

    ; ==========================================
    ; set up LCD and timers
    ; ==========================================
    mov TMOD, #11h          ; configure timer 0 in 16 bit mode
    mov TH0, #0xE3          ; configured to sample at 125 Hz
    mov TL0, #0x33
    mov TH1, #4Ch           ; 50ms delay (at 11.0592MHz)
    mov TL1, #00h
    mov R4, #0              ; initialize our software counter

    setb ET0                ; enable interrupts 
    setb ET1                ; enable timer 1 interrupt          
    setb EA 

    ; set all ports to output
    mov DPTR, #control
    mov A, #80h
    movx @DPTR, A

    ; initialize 8-bit comm, 5x7 char set
    mov A, #38h
    lcall write_cmd

    ; turn display on, hide cursor
    mov A, #0Ch
    lcall write_cmd

    ; clear screen
    mov A, #01h
    lcall write_cmd

main_lcd:
    mov R5, #00h 
main_loop_lcd :
    mov DPTR, #message
    mov A, R5
    movc A, @A+DPTR   

    jz display_gainref          ; jump if "0" ==> end of string!

    lcall write_data            ; write to LCD 
    inc R5
    sjmp main_loop_lcd

display_gainref:
    ; print Vref (from R2)
    mov A, R2 
    lcall print_number 

    ; print comma
    mov A, #0x2C
    lcall write_data

    ; print Gain (from R1)
    mov A, R1 
    lcall print_number

end_loop: 
    setb TR0                ; start timers
    setb TR1  

update_wait_loop:
    jnb 00h, update_wait_loop ; wait here until the ISR sets this bit 
    clr 00h                   ; clear the flag so we don't update twice

    ; instead of clearing the whole screen (which causes flickering),
    ; we just move the cursor to the start of the numbers.
    ; "Vrf,gain=" is 9 characters. Position 9 on Line 1 is 89h.
    mov A, #89h             
    lcall write_cmd

    lcall display_gainref     ; update the numbers
    sjmp update_wait_loop     ; keep waiting

ISR_timer0: 
    push acc
    push PSW

    clr TR0
    mov TH0, #0E3h          
    mov TL0, #33h
    setb TR0

    ; first sample the ADC
    ; we do this by writing to it (which makes it measure the voltage) 
    ; and then reading from it 
    mov DPTR, #adc          
    mov A, #00h
    movx @DPTR, A

; we need to wait ~200us for the adc
; to finish reading
    mov R0, #200
adc_delay:
    djnz R0, adc_delay

computation:
    ; we can now safely read the adc's output
    mov DPTR, #adc
    movx A, @DPTR
    mov R3, A           ; store temporarily in R3

    ; first check if Vref - Vadc > 0 
    ; since dac cannot output negative voltage
    clr C
    mov A, R2 
    subb A, R3

    jc negative_gain        ; jump if we would get a negative gain 

; if the gain is positive, we next need to check that
; it wont be greater than FFh
positive_gain:
    mov B, R1               ; get the gain
    mul AB                  ; this performs (Vref - Vadc) * gain

    ; check if overflowed
    jb OV, overflow

; if it didn't overflow, send (Vref-Vadc) * gain to DAC
no_overflow:
    mov DPTR, #dac
    movx @DPTR, A 
    sjmp exit_ISR_timer0

; if it overflowed, just send the max value to the DAC (FFh)
overflow:
    mov DPTR, #dac
    mov A, #0FFh
    movx @DPTR, A
    sjmp exit_ISR_timer0

; in this case, just send 00h to the DAC
negative_gain:
    mov DPTR, #dac
    mov A, #00h
    movx @DPTR, A

exit_ISR_timer0:
    pop PSW
    pop acc
    reti

;*************************************************
; send hex in acc to LCD as instruction
;*************************************************
write_cmd:
    ; E is bit 2
    ; R/W is bit 1
    ; RS is bit 0
    ; RS = 0 for cmd
    
    ; push command from A to portA
    mov DPTR, #portA
    movx @DPTR, A 

    ; set E line is low and RS=0
    mov DPTR, #portC
    mov A, #00h
    movx @DPTR, A

    ; lift the E line
    mov DPTR, #portC
    mov A, #04h  
    movx @DPTR, A        

    ; lower the E line
    mov A, #00h
    movx @DPTR, A

    ; call delay subroutine to give 
    ; LCD display time

    lcall delay
    ret

;*************************************************
; send hex in acc to LCD as data
;*************************************************
write_data:
    ; E is bit 2
    ; R/W is bit 1
    ; RS is bit 0
    ; RS = 1 for data

    ; push data from A to portA
    mov DPTR, #portA
    movx @DPTR, A

    ; set E line low and RS=1
    mov DPTR, #portC
    mov A, #01h
    movx @DPTR, A

    ; lift the E line
    mov DPTR, #portC
    mov A, #05h
    movx @DPTR, A

    ; lower the E line
    mov A, #01h
    movx @DPTR, A 

    lcall delay
    ret

; we need a delay of at least 1.52 ms
; after the falling edge of the E line
delay:
    mov R7, #04h
outer:
    mov R6, #0FFh
inner:
    djnz R6, inner
    djnz R7, outer
    ret

message:
    .byte "Vrf,gain=", 0

;*************************************************
; convert 8-bit hex in A to 3 decimal ASCII digits 
; and send them to the LCD
;*************************************************
print_number:
    mov B, #100
    div AB          ; divide A by 100. A = Hundreds digit, B = Remainder
    add A, #30h     ; add 0x30 to convert number to ASCII character
    lcall write_data

    mov A, B        ; move the remainder back into A
    mov B, #10
    div AB          ; divide A by 10. A = Tens digit, B = Units digit
    
    ; print Tens digit
    add A, #30h     ; convert to ASCII
    lcall write_data
    
    ; print Units digit
    mov A, B        ; move units digit into A
    add A, #30h     ; convert to ASCII
    lcall write_data
    ret

ISR_timer1:
    push ACC
    push PSW
    
    ; reload timer 1 for 50ms 
    clr TR1
    mov TH1, #4Ch
    mov TL1, #00h
    setb TR1
    
    inc R4              ; incremenet software tick counter
    mov A, R4
    cjne A, #40, exit_t1 ; If R4 != 40, just exit
    
    ; if we reach here, 2 seconds have passed
    mov R4, #0          ; reset software counter
    xrl 02h, #80h       ; toggle R2 (Vref) between 0 and 128
    setb 00h
    
exit_t1:
    pop PSW
    pop ACC
    reti


