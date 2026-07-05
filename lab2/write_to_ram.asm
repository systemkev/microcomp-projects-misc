.org 8000h
    mov dptr, #9000h
    mov a, #0CAh
    movx @dptr, a
    ljmp 0000h       ; Jump back to the main (ROM) monitor