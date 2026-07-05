.org 8000h

mov DPTR, #9000h        ; load counter from 9000h
movx A, @DPTR
mov R1, A               ; store original count
mov R0, A               ; initialize current count

loop:
    djnz R0, loop       ; 2 machine cycles: loop R0 times

    cpl P1.0            ; 1 cycle: complement ONLY pin 0 on Port 1

    mov A, R1           ; 1 cycle: reload for next round
    mov R0, A           ; 1 cycle
    sjmp loop           ; 2 cycles: loop infinitely