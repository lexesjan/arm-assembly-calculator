  AREA  AsmTemplate, CODE, READONLY
  IMPORT  main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

  EXPORT  start
start

IO1DIR EQU 0xE0028018
IO1SET EQU 0xE0028014
IO1CLR EQU 0xE002801C
IO1PIN EQU 0xE0028010
INCREASE_NUM_BUTTON EQU 23
DECREASE_NUM_BUTTON EQU 22
PLUS_BUTTON EQU 21
MINUS_BUTTON EQU 20
CLEAR_BUTTON EQU -21
RESET_BUTTON EQU -20

  ; initialise SP

  ldr r13, =0x40002000 ; initialise SP to top of stack

  ;
  ; main
  ;

  bl initLED                    ; initLED()
  bl initButtons                ; initButtons()
whileT                          ; while (true) {
  mov r4, #0                    ;   num = 0
  mov r5, #0                    ;   sum = 0
  mov r6, #PLUS_BUTTON          ;   prev_operator = PLUS_BUTTON
  mov r7, #0                    ;   first_press = false
  mov r8, #0                    ;   reset = false
  bl clearNumDisplay            ;   clearNumDisplay()
whileReset
  cmp r8, #0                    ;   while (!reset)
  bne eWhileReset               ;   {
  ldr r0, =4000000              ;     button_index = readButtonPress(4000000);
  bl readButtonPress
  mov r9, r0
  cmp r9, #INCREASE_NUM_BUTTON  ;     if (button_index == INCREASE_NUM_BUTTON ||
  beq ifIncOrDecBtn             ;           button_index == DECREASE_NUM_BUTTON)
  cmp r9, #DECREASE_NUM_BUTTON  ;     {
  beq ifIncOrDecBtn
  b ifNotIncOrDecBtn
ifIncOrDecBtn
  cmp r7, #0                    ;       if (!first_press)
  bne ifNotFirstPress           ;       {
  cmp r9, #INCREASE_NUM_BUTTON  ;         if (button_index == INCREASE_NUM_BUTTON)
  bne ifIncBtn                  ;         {
  add r4, #1                    ;           num++
  b ifNotIncBtn                 ;         }
ifIncBtn                        ;         else
                                ;         {
  sub r4, #1                    ;           num--
ifNotIncBtn                     ;         }
  b ifFirstPress                ;       }
ifNotFirstPress                 ;       else
                                ;       {
  mov r0, r4                    ;         displayNum(num)
  bl displayNum
  mov r7, #0                    ;         first_press = false
ifFirstPress                    ;       }
  mov r0, r4                    ;       displayNum(num)
  bl displayNum
  b whileReset
ifNotIncOrDecBtn                ;     }
  cmp r9, #PLUS_BUTTON          ;     else if (button_index == PLUS_BUTTON ||
  beq ifPlusOrMinusBtn          ;               button_index == MINUS_BUTTON)
  cmp r9, #MINUS_BUTTON         ;     {
  beq ifPlusOrMinusBtn
  b ifNotPlusOrMinusBtn
ifPlusOrMinusBtn
  cmp r6, #PLUS_BUTTON          ;      if (prev_operator == PLUS_BUTTON)
  bne ifNotPlusBtn              ;      {
  add r5, r4                    ;        sum += num
  b eIfPlusBtn                  ;      }
ifNotPlusBtn                    ;      else
                                ;      {
  sub r5, r4                    ;        sum -= num
eIfPlusBtn                      ;      }
  mov r0, r5                    ;      displayNum(sum)
  bl displayNum
  mov r6, r9                    ;      prev_operator = button_index
  mov r7, #1                    ;      first_press = true
  mov r4, #0                    ;      num = 0
  b whileReset                  ;    }
ifNotPlusOrMinusBtn             ;    else if (button_index == CLEAR_BUTTON)
  cmp r9, #CLEAR_BUTTON         ;    {
  bne ifNotClearButton
  mov r6, #PLUS_BUTTON          ;      prev_operator = PLUS_BUTTON
  mov r7, #0                    ;      first_press = false
  mov r4, #0                    ;      num = 0
  mov r0, r4                    ;      displayNum(num)
  bl displayNum
  b whileReset                  ;    }
ifNotClearButton                ;    else if (button_index == RESET_BUTTON)
  cmp r9, #RESET_BUTTON         ;    {
  bne whileReset
  mov r8, #1                    ;      reset = true
                                ;    }
  b whileReset                  ;   }
eWhileReset
  b whileT                      ; }

stop  B  stop

;
; reverse
; reverses the input num bitwise
; parameters:
;   r0 - num - to reverse
;   r1 - num_bits - is significant bits to reverse
; return:
;   r0 - reversed bits
;
reverse
  stmfd sp!, {r4, lr}
  sub r1, r1, #1              ; num_bits--
  mov r2, #1                  ; mask = 1
  mov r4, #0                  ; result = 0
rWhileN
  cmp r0, #0                  ; while (num != 0)
  beq reWhileN                ; {
  and r3, r0, r2              ;   bit = mask & num
  cmp r3, #0                  ;   if (bit != 0)
  beq reif                    ;   {
  orr r4, r4, r2, lsl r1      ;     result |= 1 << num_bits
reif                          ;   }
  mov r0, r0, lsr #1          ;   num >>= 1
  sub r1, r1, #1              ;   num_bits--
  b rWhileN                   ; }
reWhileN
  mov r0, r4                  ; reversed = result
  ldmfd sp!, {r4, pc}

;
; clearNumDisplay
; clears the 4 bit number displayed on the LEDs
; parameters:
;   none
; return:
;   none
;
clearNumDisplay
  ldr  r0,=IO1SET
  ldr  r1,=0x000f0000  ;select P1.19--P1.16
  str  r1,[r0]    ;set them to turn the LEDs off
  bx lr

;
; displayNum
; displays the 4 bit input number
; parameters:
;   r0 - input - the number to dispay
; return:
;   none
;
displayNum
  stmdb sp!, {r4, lr}
  mov r4, r0
  bl clearNumDisplay            ; clearNumDisplay()
  mov r0, r4
  and r0, #0xf                  ; input &= 0xf
  mov r1, #4                    ; input = reverse(input, 4);
  bl reverse
  lsl r0, #16                   ; input <<= 16
  ldr r1, =IO1CLR               ; temp = IO1CLR
  str r0, [r1]                  ; turnOnLEDS(input)
  ldmia sp!, {r4, pc}


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
  and r1, #0xf                   ; curr_state &= 0xf
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
  add r0, #MINUS_BUTTON         ;   index += MINUS_BUTTON
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
