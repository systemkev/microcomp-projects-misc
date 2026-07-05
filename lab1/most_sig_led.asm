; turns an most significant LED on

mov P1, #00h		; clear the LED bank
mov P1, #10000000b	; turns on the most significant LED

loop:
	sjmp loop	; infinite loop
	
