.org 8000h

mov P1, #00h                ; clear display

mov DPTR, #9000h            ; get value at address 9000h (high byte)
movx A, @DPTR               ; 
mov R2, A                   ; for reload

inc DPTR                    ; new address is 9001h (low byte)
movx A, @DPTR               ; 
mov R3, A                   ; for reload 

start:
    cpl P1.0                ; complement the LEDs

    mov A, R2
    mov R0, A               ; high byte

    mov A, R3
    mov R1, A               ; low byte

    mov A, R1               
    jz high                 ; if low byte == 0, jump to high

low:
    djnz R1, low            ; dec low byte till 0

high:
    mov A, R0
    jz start                ; if high byte == 0, restart
    dec R0                  ; ow, dec R0
    sjmp low                ; low will dec from FFh to 0 





