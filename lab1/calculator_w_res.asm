.org 00h
ljmp main                       ; jump to start of code

.org 100h
main: 
    lcall init                  ; set up serial and timers

main_loop: 
    ; get num1
    mov R0, #30h                ; location for storage of num1
    mov R1, #03h                ; 3 digit counter
    lcall get_routine           ; fetch digits from serial
    lcall new_line              ; print carriage return/line feed

    ; get num2
    mov R0, #33h                ; location for storage of num2
    mov R1, #03h                ; 3 digit counter
    lcall get_routine           ; fetch digits from serial
    lcall new_line              ; print carriage return/line feed

    ; convert ascii nums to hex nums
    mov R0, #30h                ; point to first ascii number
    mov R1, #36h                ; result destination for num1
    lcall convert_to_bin        ; process first number

    mov R0, #33h                ; point to second ascii number
    mov R1, #37h                ; result destination for num2
    lcall convert_to_bin        ; process second number

    ; get operation
    mov R0, #38h                ; store operator here
    mov R1, #01h                ; only need 1 character
    lcall get_routine           ; fetch '+', '-', etc.

    check_1:                    ; check for addition
    cjne A, #2Bh, check_2       ; compare against '+' hex 2bh
    lcall add_num               ; call addition routine
    lcall display_result        ; send result to pc screen
    lcall new_line              ; formatting
    sjmp main_loop              ; restart process

    check_2:                    ; check for subtraction
    cjne A, #2Dh, main_loop     ; compare against '-' hex 2dh
    lcall sub_num               ; call subtraction routine
    lcall display_result        ; send result to pc screen
    lcall new_line              ; formatting
    sjmp main_loop              ; restart process

new_line:
    clr ti                      ; clear transmit interrupt flag
    mov A, #0DH                 ; load carriage return
    mov sbuf, A                 ; send to serial buffer
    l1:
        jnb ti, l1              ; wait for bit to finish
    
    clr ti                      ; clear flag for next char
    mov A, #0AH                 ; load line feed
    mov sbuf, A                 ; send to serial buffer
    l2:
        jnb ti, l2              ; wait for bit to finish
    clr ti                      ; final flag clear
    ret 

add_num:
    mov A, 36h                  ; load binary num1
    mov B, 37h                  ; load binary num2 
    add A, B                    ; add them together
    mov P1, A                   ; output result to port 1
    ret

sub_num:
    clr C                       ; clear carry for subb
    mov A, 36h                  ; load binary num1
    mov B, 37h                  ; load binary num2
    clr C                       ; ensure carry is clear
    subb A, B                   ; subtract num2 from num1
    mov P1, A                   ; output result to port 1
    ret

display_result:
    ; this routine converts the hex in A to 3 ascii digits
    mov B, #64h                 ; divide by 100
    div AB                      ; A = hundreds, B = remainder
    add A, #30h                 ; convert to ascii
    lcall send_char             ; print hundreds
    
    mov A, B                    ; get remainder
    mov B, #0Ah                 ; divide by 10
    div AB                      ; A = tens, B = ones
    add A, #30h                 ; convert to ascii
    lcall send_char             ; print tens
    
    mov A, B                    ; get ones
    add A, #30h                 ; convert to ascii
    lcall send_char             ; print ones
    ret

send_char:
    clr ti                      ; clear flag
    mov sbuf, A                 ; send char
    wait_tx:
        jnb ti, wait_tx         ; wait for completion
    ret

get_routine:
    jnb ri, get_routine         ; wait for receive interrupt
    mov A, sbuf                 ; read byte from buffer
    anl A, #7Fh                 ; mask bit 7
    clr ri                      ; clear receive flag

    clr ti                      ; clear transmit flag
    mov sbuf, A                 ; echo character back

    txloop:
        jnb ti, txloop          ; wait until echo is sent
    
    mov @R0, A                  ; save char to memory
    inc R0                      ; move to next memory slot
    djnz R1, get_routine        ; loop until R1 is 0
    ret

convert_to_bin: 
    mov A, @R0                  ; get hundreds digit
    clr C                       ; clear carry
    subb A, #30h                ; convert ascii to binary
    mov B, #64h                 ; multiplier for 100
    mul AB                      ; result in A (assuming < 255)
    push ACC                    ; save result on stack

    inc R0                      ; move to tens digit
    mov A, @R0                  ; load it
    clr C                       ; clear carry
    subb A, #30h                ; convert ascii to binary
    mov B, #0Ah                 ; multiplier for 10
    mul AB                      ; result in A
    push ACC                    ; save result on stack
    
    inc R0                      ; move to ones digit
    mov A, @R0                  ; load it
    clr C                       ; clear carry
    subb A, #30h                ; convert ascii to binary
    pop 0F0h                    ; pop tens result into B
    add A, B                    ; add tens to ones
    pop 0F0h                    ; pop hundreds result into B
    add A, B                    ; add hundreds to total

    mov @R1, A                  ; store final binary value
    ret

init: 
; initialize all serial communications
    mov tmod, #20h              ; timer 1, mode 2 (8-bit auto)
    mov th1, #0FDh              ; set th1 for 9600 baud
    mov tcon, #40h              ; start timer 1 (tr1 = 1)
    mov scon, #50h              ; mode 1, enable receiver
    ret



