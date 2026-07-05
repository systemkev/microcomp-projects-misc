.org 0000h       ; Set origin to address 0 (Reset vector)

main:
    sjmp main    ; Infinite loop

keytab:
    .db 00h      ; Note the dot before "db"



