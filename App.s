  AREA  RESET, CODE, READONLY
;  IMPORT  main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

;  EXPORT  start
start

IO1DIR EQU 0xE0028018
IO1SET EQU 0xE0028014
IO1CLR EQU 0xE002801C
IO1PIN EQU 0xE0028010

  bl initLED
  bl initButtons

stop  B  stop

;
; initLED
; sets P1.19--P1.16 to output and initialises LEDs to off
; parameters:
;   none
; return:
;   none
;
initLED
  ldr  r1,=IO1DIR
  ldr  r2,=0x000f0000  ;select P1.19--P1.16
  str  r2,[r1]    ;make them outputs
  ldr  r1,=IO1SET
  str  r2,[r1]    ;set them to turn the LEDs off
  bx lr

;
; initButtons
; sets P1.20--P1.23 to input
; parameters:
;   none
; return:
;   none
;
initButtons
  ldr r0, =IO1DIR
  ldr r1, [r0];           temp = Mem.word[IO1DIR]
  bic r1, #(0xf << 20);   bic(temp, 0x00f00000)
  str r1, [r0];           setInput(P1.23--P1.20);
  bx lr

  END
