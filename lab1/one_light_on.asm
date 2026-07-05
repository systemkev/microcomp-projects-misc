; turns an LED on

mov P1, #00h		; clear the LED bank
mov P1, #01h		; turns on a single LED

loop:
	sjmp loop	; infinite loop
	
