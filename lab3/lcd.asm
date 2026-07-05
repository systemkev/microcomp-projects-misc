; lcd
    .org 8000h
    .equ portA, 0xFE30
    .equ portB, 0xFE31
    .equ portC, 0xFE32
    .equ control, 0xFE33
    ; port A is located at FE30h
    ; port B is unused
    ; port C is located at FE32h
    ; control reg is located at FE33h

;*************************************************
; set up the display
;*************************************************
setup:
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

;*************************************************
; !!!!!! MAIN !!!!!!
;*************************************************

main:
    mov R2, #00h 
main_loop:
    mov DPTR, #message
    mov A, R2
    movc A, @A+DPTR   

    jz end_loop                 ; jump if "0" ==> end of string!

    lcall write_data            ; write to LCD 
    inc R2
    sjmp main_loop
end_loop:
    sjmp *

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

    ; lift the E line
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
    .byte "6.115 rocks!", 0



