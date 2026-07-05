;=================================================================
; 6.115 LAZERDILLO WEB-SERIAL COMBINED PROGRAM
;=================================================================
    .equ x_dac, 0FE10h
    .equ y_dac, 0FE14h

    ; RAM Addresses for our Phase Accumulators (Variables)
    .equ x_frac, 30h
    .equ x_int, 31h
    .equ y_frac, 32h
    .equ y_int, 33h
    .equ rot_frac, 34h
    .equ rot_int, 35h

;=================================================================
; VECTOR TABLE
;=================================================================
    .org 0000h
    ljmp init

    .org 000Bh              ; Timer 0 Interrupt Vector
    ljmp timer0_isr

;=================================================================
; INITIALIZATION 
;=================================================================
    .org 0030h
init:
    ; 1. Configure Timers
    ; Timer 1 (Serial) Mode 2, Timer 0 (Interrupts) Mode 2
    mov TMOD, #22h     

    ; 2. Setup Serial (Timer 1)
    mov TH1, #0FDh          ; 9600 baud
    mov SCON, #50h          ; 8-bit data, Mode 1
    
    ; 3. Setup Hardware Engine (Timer 0)
    mov TH0, #04Ch          ; 5120 Hz refresh rate
    mov TL0, #04Ch      
    mov TCON, #51h          ; Start BOTH timers (TR1=1, TR0=1)

    ; 4. Clear LED Status and Memory
    mov P1, #00h            ; All LEDs off (No shape, No rotation)
    mov x_frac, #00h
    mov x_int, #00h
    mov y_frac, #00h
    mov y_int, #00h
    mov rot_frac, #00h
    mov rot_int, #00h

    ; 5. Turn on the Laser (Moved to P3.5 so it doesn't fight LEDs!)
    setb P3.5               

    ; 6. Enable Interrupts
    mov IE, #82h            ; Enable Global (EA) and Timer 0 (ET0)

;=================================================================
; MAIN SERIAL LOOP (Listens to the webpage forever)
;=================================================================
lazloop:
    clr RI                  ; flush the serial input buffer
    lcall getcmd            ; read the single-letter command
    mov R2, A               ; put the command number in R2
    ljmp nway               ; branch to a monitor routine

endloop:                    
    sjmp lazloop            ; loop forever


;=================================================================
; THE UNIVERSAL HARDWARE ENGINE (Timer 0 ISR)
; Runs 5,120 times a second to draw the shapes based on P1
;=================================================================
timer0_isr:
    push ACC                ; Save Accumulator
    push PSW                ; Save Program Status Word
    push DPL                ; MUST SAVE DPTR LOW BYTE
    push DPH                ; MUST SAVE DPTR HIGH BYTE
    mov PSW, #08h           ; Switch to Register Bank 1 for safe math

    ; determine shape from nibble 1
    mov A, P1
    anl A, #0F0h            ; Isolate shape bits
    
    cjne A, #0A0h, check_circle
    ; tie fighter
    mov R0, #40h            ; X Frac Step (0.25)
    mov R1, #01h            ; X Int Step (1.00)
    mov R2, #0C0h           ; Y Frac Step (0.75)
    mov R3, #03h            ; Y Int Step (3.00)
    mov R4, #40h            ; Base Y Phase Shift (90 degrees)
    sjmp check_rotation

check_circle:
    cjne A, #0B0h, check_figure
    ; circle
    mov R0, #00h            ; X Frac Step (0.00)
    mov R1, #04h            ; X Int Step (4.00)
    mov R2, #00h            ; Y Frac Step (0.00)
    mov R3, #04h            ; Y Int Step (4.00)
    mov R4, #40h            ; Base Y Phase Shift (90 degrees)
    sjmp check_rotation

check_figure:
    cjne A, #0C0h, exit_isr 
    ; curve (a=1, b=4)
    mov R0, #00h            ; X Frac Step (0.00)
    mov R1, #01h            ; X Int Step (1.00)
    mov R2, #00h            ; Y Frac Step (0.00)
    mov R3, #04h            ; Y Int Step (4.00)
    mov R4, #00h            ; Base Y Phase Shift (0 degrees)
    sjmp check_rotation

    ; determine the rotation nibble
check_rotation:
    mov A, P1
    anl A, #0Fh             ; Isolate rotation bits
    
    cjne A, #01h, check_10hz
    mov R5, #06h            ; 0.5 Hz Rotation (Adds ~6 to fraction)
    sjmp execute_math
check_10hz:
    cjne A, #02h, check_15hz
    mov R5, #0Dh            ; 1.0 Hz Rotation (Adds ~13 to fraction)
    sjmp execute_math
check_15hz:
    cjne A, #04h, no_rotation
    mov R5, #13h            ; 1.5 Hz Rotation (Adds ~19 to fraction)
    sjmp execute_math
no_rotation:
    mov R5, #00h            ; 0 Hz Rotation

    ; execute the phase acc math
execute_math:
    ; Advance X
    mov A, x_frac
    add A, R0
    mov x_frac, A
    mov A, x_int
    addc A, R1
    mov x_int, A

    ; Output X
    mov DPTR, #sine_table
    movc A, @A+DPTR
    mov DPTR, #x_dac
    movx @DPTR, A

    ; Advance Y
    mov A, y_frac
    add A, R2
    mov y_frac, A
    mov A, y_int
    addc A, R3
    mov y_int, A

    ; Advance Rotation Phase
    mov A, rot_frac
    add A, R5
    mov rot_frac, A
    mov A, rot_int
    addc A, #00h
    mov rot_int, A

    ; Add Rotation & Base Phase to Y
    mov A, y_int
    add A, R4               ; Add Base Phase
    add A, rot_int          ; Add Time-Varying Rotation Phase

    ; Output Y
    mov DPTR, #sine_table
    movc A, @A+DPTR
    mov DPTR, #y_dac
    movx @DPTR, A

exit_isr:
    pop DPH                 ; Restore DPTR High Byte (Last In, First Out!)
    pop DPL                 ; Restore DPTR Low Byte
    pop PSW                 ; Restore registers
    pop ACC
    reti


;=================================================================
; WEBPAGE SERIAL SUBROUTINES
;=================================================================  
jumtab:
    .dw badcmd ; command '@' 00
    .dw tfight ; command 'a' 01        tie fighter 
    .dw circle ; command 'b' 02        circle 
    .dw figure ; command 'c' 03        lissajous
    .dw slorot ; command 'd' 04     slowest rotation 0 Hz
    .dw medrot ; command 'e' 05        medium rotation 0.5 Hz
    .dw hghrot ; command 'f' 06        high rotation 1 Hz
    .dw maxrot ; command 'g' 07     fastest rotation 1.5 Hz
    .dw badcmd ; command 'h' 08
    .dw badcmd ; command 'i' 09
    .dw badcmd ; command 'j' 0a
    .dw badcmd ; command 'k' 0b
    .dw badcmd ; command 'l' 0c
    .dw badcmd ; command 'm' 0d
    .dw badcmd ; command 'n' 0e
    .dw badcmd ; command 'o' 0f
    .dw badcmd ; command 'p' 10
    .dw badcmd ; command 'q' 11
    .dw badcmd ; command 'r' 12 
    .dw badcmd ; command 's' 13
    .dw badcmd ; command 't' 14
    .dw badcmd ; command 'u' 15
    .dw badcmd ; command 'v' 16
    .dw badcmd ; command 'w' 17 
    .dw badcmd ; command 'x' 18
    .dw badcmd ; command 'y' 19
    .dw badcmd ; command 'z' 1a

tfight:
    mov A, P1        
    anl A, #0Fh        
    add A, #0A0h    
    mov P1, A
    ljmp endloop 

circle:
    mov A, P1        
    anl A, #0Fh        
    add A, #0B0h    
    mov P1, A
    ljmp endloop 

figure:
    mov A, P1        
    anl A, #0Fh        
    add A, #0C0h    
    mov P1, A
    ljmp endloop 

slorot:
    mov A, P1         
    anl A, #0F0h    
    mov P1, A
    ljmp endloop

medrot:
    mov A, P1         
    anl A, #0F0h    
    add A, #01h        
    mov P1, A
    ljmp endloop    

hghrot:
    mov A, P1         
    anl A, #0F0h    
    add A, #02h        
    mov P1, A
    ljmp endloop

maxrot:
    mov A, P1         
    anl A, #0F0h    
    add A, #04h        
    mov P1, A
    ljmp endloop

nway:
    mov dptr, #jumtab     
    mov a, r2             
    rl a                 
    inc a                 
    movc a, @a+dptr     
    push acc             
    mov a, r2             
    rl a                 
    movc a, @a+dptr     
    push acc             
    ret                 

getcmd:
    lcall getchr     
    clr acc.5         
    clr C             
    subb a, #'@'     
    jnc cmdok1         
    lcall badpar
cmdok1:
    push acc         
    subb a, #1Bh     
    jc cmdok2
    lcall badpar     
cmdok2:
    pop acc         
    ret

badpar:
    mov P1, #00h
    ljmp endloop
    
badcmd:
    mov P1, #00h
    ljmp endloop

getchr:
    jnb ri, getchr     
    mov a, sbuf     
    anl a, #7fh     
    clr ri             
    ret

; ==========================================
; TRUE 256-STEP SINE LOOKUP TABLE
; ==========================================
sine_table:
    .db 0x80, 0x82, 0x83, 0x85, 0x86, 0x88, 0x89, 0x8B
    .db 0x8C, 0x8E, 0x90, 0x91, 0x93, 0x94, 0x96, 0x97
    .db 0x98, 0x9A, 0x9B, 0x9D, 0x9E, 0xA0, 0xA1, 0xA2
    .db 0xA4, 0xA5, 0xA6, 0xA7, 0xA9, 0xAA, 0xAB, 0xAC
    .db 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4
    .db 0xB5, 0xB6, 0xB7, 0xB8, 0xB8, 0xB9, 0xBA, 0xBB
    .db 0xBB, 0xBC, 0xBC, 0xBD, 0xBD, 0xBE, 0xBE, 0xBE
    .db 0xBF, 0xBF, 0xBF, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0
    .db 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xBF, 0xBF
    .db 0xBF, 0xBE, 0xBE, 0xBE, 0xBD, 0xBD, 0xBC, 0xBC
    .db 0xBB, 0xBB, 0xBA, 0xB9, 0xB8, 0xB8, 0xB7, 0xB6
    .db 0xB5, 0xB4, 0xB3, 0xB2, 0xB1, 0xB0, 0xAF, 0xAE
    .db 0xAD, 0xAC, 0xAB, 0xAA, 0xA9, 0xA7, 0xA6, 0xA5
    .db 0xA4, 0xA2, 0xA1, 0xA0, 0x9E, 0x9D, 0x9B, 0x9A
    .db 0x98, 0x97, 0x96, 0x94, 0x93, 0x91, 0x90, 0x8E
    .db 0x8C, 0x8B, 0x89, 0x88, 0x86, 0x85, 0x83, 0x82
    .db 0x80, 0x7E, 0x7D, 0x7B, 0x7A, 0x78, 0x77, 0x75
    .db 0x74, 0x72, 0x70, 0x6F, 0x6D, 0x6C, 0x6A, 0x69
    .db 0x68, 0x66, 0x65, 0x63, 0x62, 0x60, 0x5F, 0x5E
    .db 0x5C, 0x5B, 0x5A, 0x59, 0x57, 0x56, 0x55, 0x54
    .db 0x53, 0x52, 0x51, 0x50, 0x4F, 0x4E, 0x4D, 0x4C
    .db 0x4B, 0x4A, 0x49, 0x48, 0x48, 0x47, 0x46, 0x45
    .db 0x45, 0x44, 0x44, 0x43, 0x43, 0x42, 0x42, 0x42
    .db 0x41, 0x41, 0x41, 0x40, 0x40, 0x40, 0x40, 0x40
    .db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x41, 0x41
    .db 0x41, 0x42, 0x42, 0x42, 0x43, 0x43, 0x44, 0x44
    .db 0x45, 0x45, 0x46, 0x47, 0x48, 0x48, 0x49, 0x4A
    .db 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52
    .db 0x53, 0x54, 0x55, 0x56, 0x57, 0x59, 0x5A, 0x5B
    .db 0x5C, 0x5E, 0x5F, 0x60, 0x62, 0x63, 0x65, 0x66
    .db 0x68, 0x69, 0x6A, 0x6C, 0x6D, 0x6F, 0x70, 0x72
    .db 0x74, 0x75, 0x77, 0x78, 0x7A, 0x7B, 0x7D, 0x7E



