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

  ; initialise SP
  ldr r13, =0x40002000 ; initialise SP to top of stack

  bl initLED
  bl initButtons
whileT
  ldr r0, =4000000
  bl readButtonPress
  b whileT

stop  B  stop

;
; readButtonPress
; reads if the button pressed (P1.23--P1.20) is long or short and returns the
; index of the button pressed
; parameters:
;   r0 - cutoff - long button press cutoff
; return:
;   r0 - index - index of the button pressed, will be positive (20 to 23) if
;                short press else negative (-20 to -23)
;
readButtonPress
  stmdb sp!, {r4-r8, lr}
  mov r8, r0
  ldr r4, =IO1PIN
readButtonPressDoWhile0         ; do {
  ldr r5, [r4]                  ;   curr_state = Mem.word[IO1PIN] & (0xf << 20)
  and r5, #(0xf << 20)
  cmp r5, #(0xf << 20)
  beq readButtonPressDoWhile0   ; } while (curr_state == 0x00f00000)
  bl getButtonIndex             ; button_index = getButtonIndex()
  mov r6, #1                    ; mask = 1 << button_index
  lsl r6, r0                    ;
  mov r7, #0                    ; i = 0
readButtonPressDoWhile1         ; do {
  ldr r5, [r4]                  ;   curr_state = Mem.word[IO1PIN] & mask
  and r5, r6
  add r7, #1                    ;   i++
  cmp r5, #0
  beq readButtonPressDoWhile1   ; } while (curr_state == 0)
  cmp r7, r8                    ; if (i < cutoff)
  bge getButtonIndexif0         ; {
  ldmia sp!, {r4-r8, pc}        ;   return button_index
                                ; }
getButtonIndexif0               ; else
                                ; {
  rsb r0, #0                    ;   button_index = neg(button_index)
  ldmia sp!, {r4-r8, pc}        ;   return button_index
                                ; }

;
; getButtonIndex
; returns the index of the button pressed from P1.23--P1.20
; parameters:
;   none
; return:
;   r0 - the index of the button pressed (20 to 23) else if no button pressed
;        returns 0
;
getButtonIndex
  ldr r0, =IO1PIN
  ldr r1, [r0]                  ; curr_state = (Mem.word[IO1PIN] & (0xf << 20))
  and r1, #(0xf << 20)          ;  >> 20
  lsr r1, #20
  mvn r1, r1                    ; curr_state ~= curr_state
  and r1, 0xf                   ; curr_state &= 0xf
  mov r2, #0                    ; i = 0
getButtonIndexWhile0
  cmp r1, #0                    ; while (curr_state != 0)
  beq getButtonIndexeWhile0     ; {
  lsr r1, #1                    ;   curr_state >>= 1
  add r2, #1                    ;   i++
  b getButtonIndexWhile0        ;
getButtonIndexeWhile0           ; }
  cmp r2, #0                    ; if (i == 0)
  bne getButtonIndexeif0        ; {
  mov r0, #0                    ;   return 0;
  bx lr                         ; }
getButtonIndexeif0              ; else
  sub r2, #1                    ; {
  mov r0, r2                    ;   index = i - 1
  add r0, #20                   ;   index += 20
  bx lr                         ;   return index
                                ; }

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
  ldr r1, [r0]            ; temp = Mem.word[IO1DIR]
  bic r1, #(0xf << 20)    ; bic(temp, 0x00f00000)
  str r1, [r0]            ; setInput(P1.23--P1.20);
  bx lr

  END
