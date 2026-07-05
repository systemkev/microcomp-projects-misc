.org 8000h
main:
    ; fetch first input at 9000h
    mov DPTR, #9000h
    movx A, @DPTR
    mov R0, A

    ; fetch second input at 9001h
    inc DPTR
    movx A, @DPTR
    mov R1, A

add_f:
    add A, R0               ; add operation
    inc DPTR
    movx @DPTR, A           ; store at 9002h

sub_f:
    mov A, R0               ; reload input 1 into acc
    clr C
    subb A, R1              ; sub operation
    inc DPTR
    movx @DPTR, A           ; store at 9003h

mul_f:
    mov A, R0               ; load inputs into A & B for multiplication
    mov B, R1
    mul AB
    mov R2, A               ; temporarily store low byte in R2 so we can send high byte first
    inc DPTR                ; store 2 byte result of multiplication in 9004/5h
    mov A, B
    movx @DPTR, A
    inc DPTR
    mov A, R2                ; DPTR only talks to A
    movx @DPTR, A

div_f:
    mov A, R0               ; load inputs into A & B for division
    mov B, R1
    div AB
    inc DPTR                ; store quotient in 9006h and remainder in 9007
    movx @DPTR, A
    inc DPTR
    mov A, B
    movx @DPTR, A

ljmp 0000h


    


