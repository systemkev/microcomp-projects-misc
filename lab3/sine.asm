; sine
    .org 8000h
main:
    clr ea
    mov R1, #00h
loop:
    mov DPTR, #sine_table           ; load address into DPTR
    mov A, R1                       ; load offset 
    movc A, @A+DPTR                 ; fetch value from table

    mov DPTR, #0FE40h               ; address of DAC
    movx @DPTR, A
    
    inc R1                          ; move to next value
    sjmp loop                       ; loops infinitely

sine_table:
    .DB 80h, 83h, 86h, 89h, 8Ch, 8Fh, 92h, 95h, 98h, 9Bh, 9Eh, 0A2h, 0A5h, 0A7h, 0AAh, 0ADh
    .DB 0B0h, 0B3h, 0B6h, 0B9h, 0BCh, 0BEh, 0C1h, 0C4h, 0C6h, 0C9h, 0CBh, 0CEh, 0D0h, 0D3h, 0D5h, 0D7h
    .DB 0DAh, 0DCh, 0DEh, 0E0h, 0E2h, 0E4h, 0E6h, 0E8h, 0EAh, 0EBh, 0EDh, 0EEh, 0F0h, 0F1h, 0F3h, 0F4h
    .DB 0F5h, 0F6h, 0F8h, 0F9h, 0FAh, 0FAh, 0FBh, 0FCh, 0FDh, 0FDh, 0FEh, 0FEh, 0FEh, 0FFh, 0FFh, 0FFh
    .DB 0FFh, 0FFh, 0FFh, 0FFh, 0FEh, 0FEh, 0FEh, 0FDh, 0FDh, 0FCh, 0FBh, 0FAh, 0FAh, 0F9h, 0F8h, 0F6h
    .DB 0F5h, 0F4h, 0F3h, 0F1h, 0F0h, 0EEh, 0EDh, 0EBh, 0EAh, 0E8h, 0E6h, 0E4h, 0E2h, 0E0h, 0DEh, 0DCh
    .DB 0DAh, 0D7h, 0D5h, 0D3h, 0D0h, 0CEh, 0CBh, 0C9h, 0C6h, 0C4h, 0C1h, 0BEh, 0BCh, 0B9h, 0B6h, 0B3h
    .DB 0B0h, 0ADh, 0AAh, 0A7h, 0A5h, 0A2h, 9Eh, 9Bh, 98h, 95h, 92h, 8Fh, 8Ch, 89h, 86h, 83h
    .DB 80h, 7Ch, 79h, 76h, 73h, 70h, 6Dh, 6Ah, 67h, 64h, 61h, 5Dh, 5Ah, 58h, 55h, 52h
    .DB 4Fh, 4Ch, 49h, 46h, 43h, 41h, 3Eh, 3Bh, 39h, 36h, 34h, 31h, 2Fh, 2Ch, 2Ah, 28h
    .DB 25h, 23h, 21h, 1Fh, 1Dh, 1Bh, 19h, 17h, 15h, 14h, 12h, 11h, 0Fh, 0Eh, 0Ch, 0Bh
    .DB 0Ah, 09h, 07h, 06h, 05h, 05h, 04h, 03h, 02h, 02h, 01h, 01h, 01h, 00h, 00h, 00h
    .DB 00h, 00h, 00h, 00h, 01h, 01h, 01h, 02h, 02h, 03h, 04h, 05h, 05h, 06h, 07h, 09h
    .DB 0Ah, 0Bh, 0Ch, 0Eh, 0Fh, 11h, 12h, 14h, 15h, 17h, 19h, 1Bh, 1Dh, 1Fh, 21h, 23h
    .DB 25h, 28h, 2Ah, 2Ch, 2Fh, 31h, 34h, 36h, 39h, 3Bh, 3Eh, 41h, 43h, 46h, 49h, 4Ch
    .DB 4Fh, 52h, 55h, 58h, 5Ah, 5Dh, 61h, 64h, 67h, 6Ah, 6Dh, 70h, 73h, 76h, 79h, 7Ch



