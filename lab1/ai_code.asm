.ORG 8000H 

START:
    MOV A, #02H       ; Initialize A with 2

COUNT_LOOP:
    MOV P1, A         ; Show value on Port 1
    ACALL DELAY       
    
    ADD A, #02H       ; Next even number
    CJNE A, #66H, COUNT_LOOP ; Stop after displaying 100 (64H)
    
    SJMP START        ; Restart back at 2

DELAY:                ; ~130ms delay at 12MHz
    MOV R0, #0FFH
D1: MOV R1, #0FFH
D2: DJNZ R1, D2
    DJNZ R0, D1
    RET
