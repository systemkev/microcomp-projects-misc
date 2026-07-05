    .equ portB, 0FE31h    ; Port B: Connected to Stepper Motor (Pins 10-15)
    .equ control, 0FE33h  ; 8255 Control Register
    .equ adc, 0FE10h      ; ** REPLACE WITH YOUR ADC ADDRESS **

.org 00h                    
    ljmp main              

.org 100h                   
main:
    ; Initiate 8255 ports as outputs
    mov DPTR, #control
    mov A, #80h
    movx @DPTR, A

    ; Set up serial port and use timer 1 for 9600 baud comm
    mov tmod, #20h
    mov tcon, #40h
    mov th1, #0FDh
    mov scon, #50h

    ; Initialize hardware states
    mov R2, #00h        ; R2 keeps track of which motor phase we are on
    setb P3.5           ; Ensure SpinDude LEDs are OFF by default (Active LOW)

main_loop:
    lcall getchr        ; Wait for any character from terminal to start
    
    ; We seek to make the stepper execute 24 steps (360 degrees)
    mov R0, #24         ; Set outer loop counter for 24 rotations 

scan_loop:
    lcall take_step     ; Rotate turntable exactly 15 degrees (1 step)
    lcall delay_motor   ; Allow turntable to stop jiggling and settle

    mov R1, #00h        ; Initialize LED/Photo index counter (0 to 15)

led_loop:
    ; 1. Route the 0-15 index to P1.4 - P1.7 safely
    mov A, R1           ; Get the current channel index (e.g., 0000 0101)
    swap A              ; Move it to the upper nibble  (e.g., 0101 0000)
    mov R3, A           ; Temporarily store shifted value
    mov A, P1           ; Read current state of Port 1
    anl A, #0Fh         ; Clear the top 4 bits, keep the bottom 4 bits safe
    orl A, R3           ; Merge the safe bottom bits with the new top bits
    mov P1, A           ; Output to Port 1 to select the LED/Photo pair

    ; 2. Turn ON the LED and wait for it to settle
    clr P3.5            ; Bring E1 LOW to enable LED
    lcall delay_optics  

    ; 3. Read the illumination intensity from the ADC
    mov DPTR, #adc
    movx @DPTR, A       ; Dummy write to trigger ADC conversion start
    lcall delay_adc     
    movx A, @DPTR       ; Read the 0-255 analog value into Accumulator

    ; 4. Turn OFF the LED and print the value
    push acc            ; Save ADC value
    setb P3.5           ; Bring E1 HIGH to disable LED
    pop acc             ; Restore ADC value

    lcall print_hex     ; Print 2-digit hex
    mov A, #' '         
    lcall sndchr        ; Print space

    ; 5. Advance to the next LED
    inc R1
    cjne R1, #16, led_loop  

    ; 6. End of the 16-column row: Send Carriage Return & Line Feed
    mov A, #0Dh         
    lcall sndchr
    mov A, #0Ah         
    lcall sndchr

    ; 7. Advance the Turntable
    djnz R0, scan_loop  

    sjmp main_loop      ; Image complete! Wait for the next key press.


; =========================================
; SUBROUTINES
; =========================================

; --- Stepper Motor State Machine ---
take_step:
    mov DPTR, #portB
    cjne R2, #00h, check_step1
    mov A, #0F7h        ; Phase 0 (Inverted 08h)
    sjmp output_step
check_step1:
    cjne R2, #01h, check_step2
    mov A, #0DFh        ; Phase 1 (Inverted 20h)
    sjmp output_step
check_step2:
    cjne R2, #02h, check_step3
    mov A, #0EFh        ; Phase 2 (Inverted 10h)
    sjmp output_step
check_step3:
    mov A, #0BFh        ; Phase 3 (Inverted 40h)
    mov R2, #0FFh       ; Reset state 
output_step:
    movx @DPTR, A       ; Send phase to L293D
    inc R2              ; Advance state for the next time we take a step
    ret

; --- Print Hexadecimal Helper ---
print_hex:
    push acc            
    swap a              
    anl a, #0Fh         
    lcall hex_ascii     
    lcall sndchr        
    pop acc             
    anl a, #0Fh         
    lcall hex_ascii     
    lcall sndchr        
    ret

hex_ascii:
    add a, #30h         
    cjne a, #3Ah, check_alpha 
check_alpha:
    jc skip_alpha
    add a, #07h         
skip_alpha:
    ret

; --- Communication ---
getchr:
    jnb ri, getchr          
    mov A, sbuf             
    anl A, #7Fh             
    clr ri                  
    ret

sndchr:
    clr scon.1
    mov sbuf, A
txloop:
    jnb scon.1, txloop
    ret

; --- Delays ---
delay_motor:
    push acc
    mov R5, #03h        
outer_m:
    mov R6, #0FFh
middle_m:
    mov R7, #0FFh
inner_m:
    djnz R7, inner_m
    djnz R6, middle_m
    djnz R5, outer_m
    pop acc
    ret

delay_optics:
    push acc
    mov R6, #020h       
opt_loop:
    mov R7, #0FFh
opt_inner:
    djnz R7, opt_inner
    djnz R6, opt_loop
    pop acc
    ret

delay_adc:
    mov R7, #0FFh       
adc_loop:
    djnz R7, adc_loop
    ret




