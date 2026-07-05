; dynamic pattern

mov A, #01h			   		; move first pattern into accumulator

main:
    mov P1, #00Fh			; clear display
	mov P1, A				; push accumulator value into P1
    mov R0, #0FFh			; bound for outer loop of delay
    acall delay_outer		; call delay loop
    rl A					; rotate A to the left
	sjmp main				; loop

; loops to slow down the changing of the lights
delay_outer:					
	nop						; nop helps to slow down things
	mov R1, #0FFh

inner_loop:
	nop
	djnz R1, inner_loop	
	djnz R0, delay_outer
	ret
	
