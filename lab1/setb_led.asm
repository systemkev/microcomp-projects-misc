; turns an LED on

; clear everything first
clr P1.7
clr P1.6
clr P1.5
clr P1.4
clr P1.3
clr P1.2
clr P1.1
clr P1.0

; set first LED
setb P1.0

loop:
	sjmp loop	; infinite loop
	