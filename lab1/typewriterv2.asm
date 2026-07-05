.org 00h                    ; reset vecotr
    ljmp start              ; go to 100h

.org 100h                   ; locate "start" at 100h in memory 

start:
    mov R0, #41h            ; 65 keystrokes
    lcall init              
    loop:                       
        lcall getchr        ; get character from keyboard
        lcall sndchr        ; echo character to the PC screen 
        sjmp loop
init: 
; set up serial port and use timer 1 for 9600 baud comm
    mov tmod, #20h
    mov tcon, #40h
    mov th1, #0FDh
    mov scon, #50h
    ret
getchr:
    jnb ri, getchr          ; wait for char to arrive
    mov A, sbuf             ; char arrives at sbuf -> move to A
    anl A, #7Fh             ; ASCII only needs bottom 7 bits, clear 8th
    clr ri                  ; clear flag
    ret
sndchr:
    clr ti
    mov sbuf, A
    mov P1, A
txloop:
    jnb scon.1, txloop
    djnz R0, return         ; keep going till we hit 65 keystrokes
    lcall clrf              ; when we hit 65 keystrokes, go to clear routine
    return:
    ret
    
clrf:
    clr ti
    mov sbuf, #0Dh          ; carriage return ascii code
    jnb ti, *
    clr ti

    mov sbuf, #0Ah          ; line feed ascii code
    jnb ti, *
    clr ti

    mov R0, #41h            ; reset 65 keystroke limit
    ret
    
    