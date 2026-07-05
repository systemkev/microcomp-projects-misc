.org 8000h
    .equ portA, 0FE30h
    .equ portC, 0FE32h
    .equ control, 0FE33h

;*************************************************
; 1. SETUP THE DISPLAY
;*************************************************
setup:
    ; set all ports to output
    mov DPTR, #control
    mov A, #80h
    movx @DPTR, A

    ; initialize 8-bit comm, 2 lines, 5x7 char set
    mov A, #38h
    lcall write_cmd

    ; turn display on, hide cursor
    mov A, #0Ch
    lcall write_cmd

    ; clear screen
    mov A, #01h
    lcall write_cmd

;*************************************************
; 2. DIAGNOSTIC MAIN LOOP
;*************************************************
main_loop:
    mov A, #48h         ; 48h is the exact ASCII hex code for 'H'
    lcall write_data    ; Send it directly to the LCD
    sjmp main_loop      ; Loop forever! 

;*************************************************
; SUBROUTINES (WITH TIMING FIXES)
;*************************************************
write_cmd:
    ; Push command to portA
    mov DPTR, #portA
    movx @DPTR, A 

    ; Pre-set RS=0, E=0
    mov DPTR, #portC
    mov A, #00h
    movx @DPTR, A

    ; Lift E line (E=1, RS=0)
    mov A, #04h  
    movx @DPTR, A        

    ; Lower E line (E=0, RS=0)
    mov A, #00h
    movx @DPTR, A

    lcall delay
    ret

write_data:
    ; Push data to portA
    mov DPTR, #portA
    movx @DPTR, A

    ; Pre-set RS=1, E=0
    mov DPTR, #portC
    mov A, #01h
    movx @DPTR, A

    ; Lift E line (E=1, RS=1)
    mov A, #05h
    movx @DPTR, A

    ; Lower E line (E=0, RS=1)
    mov A, #01h
    movx @DPTR, A 

    lcall delay
    ret

delay:
    mov R7, #04h
outer:
    mov R6, #0FFh
inner:
    djnz R6, inner
    djnz R7, outer
    ret



