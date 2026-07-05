.org 8000h
; ==================
; auto strike lamp!
; ==================

set_mode:
    setb P1.0                   ; configure as input 
    mov DPTR, #0FE03h           ; configuration for 8254
    mov A, #01110110b
    movx @DPTR, A               ; mode 3 

start:
    mov R0, #00h                ; MSB of the initial count for the 8254
    mov R1, #0A7h               ; LSB of the initial count for the 8254
    
    mov DPTR, #0FE01h           ; location for 8254 counter 0

    mov A, R1
    movx @DPTR, A               ; move LSB and MSB into 8254
    mov A, R0
    movx @DPTR, A

fast:
    lcall delay                 ; call delay loop
    jnb P1.0, slow              ; check for LOW Schmitt output

    clr C
    mov A, R1                   ; move LSB into A
    add A, #03h                  ; add 10 to LSB
    movx @DPTR, A               ; send LSB of new counter to 8254
    mov R1, A                   ; update R1

    mov A, R0                   ; move MSB into A
    addc A, #00                 ; add any carry into A
    movx @DPTR, A               ; send MSB of new counter to 8254
    mov R0, A                   ; update R0

    sjmp fast                   ; loop while still HIGH

slow:
    lcall delay                 ; call delay loop
    jb P1.0, end_loop           ; check for HIGH ==> lamp struck!

    clr C
    mov A, R1                   ; move LSB into A
    add A, #1h                  ; add 1 to LSB
    movx @DPTR, A               ; send LSB of new counter to 8254
    mov R1, A                   ; update R1

    mov A, R0                   ; move MSB into A
    addc A, #00                 ; add any carry into A
    movx @DPTR, A               ; send MSB of new counter to 8254
    mov R0, A                   ; update R0

    sjmp slow                   ; loop until lamp strikes

delay:
; the purpose of this delay loop is to allow a small amount of time for
; the circuit to react to the new changes. i kept it at 3 time constants
; which is about 15ms for this circuit

    mov R2, #0FFh                    ; 256 count for outer loop

    outer:
        mov R3, #15                ; 10 count for inner loop 

    inner:
        djnz R3, inner
        djnz R2, outer 
    
    ret

end_loop:
    sjmp end_loop                   ; once struck, just stay there



