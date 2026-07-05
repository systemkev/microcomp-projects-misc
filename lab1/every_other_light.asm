; every other light on

mov P1, #00h		; clear the LED bank
mov P1, #10101010b	; turns on a single LED

loop:
	sjmp loop	; infinite loop
	
