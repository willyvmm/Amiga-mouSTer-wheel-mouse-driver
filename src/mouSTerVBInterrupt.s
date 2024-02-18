;mouSTer Driver

            ;INCLUDE    "dos/dos.i"
            ;INCLUDE    "lvo/exec_lib.i
            ;INCLUDE    "hardware/custom.i"

;interrupts control
INTENA         = $DFF09A                        ;w
INTENAR        = $DFF01C                        ;r

;CIAA
CIAAPRA        = $BFE001
CIAADDRA       = $BFE201                        ;0=input 1=output 

;potgo
POTGO          = $DFF034                        ;w
POTGOR         = $DFF016                        ;r    

;potgohax
POTGO_INTENA   = POTGO-INTENA 
POTGOR_INTENA  = POTGOR-INTENA 
INTENAR_INTENA = INTENAR-INTENA


;mouse
LMBnumber      = 6
LMBmask        = 1<<LMBnumber
LMBnegMask     = ~LMBmask

MMBnumber      = 8
MMBdirNR       = 9

MMBmask        = 1<<MMBnumber
MMBdirMask     = 1<<MMBdirNR	

MMBnegMask     = ~MMBmask
MMBnegDirMask  = ~MMBdirMask

MMB1val        = $ff00
MMB0val        = MMB1val&MMBnegMask

;interprocess data

cb_head        = $00
cb_tail        = $01
cb_sign        = $02
cb_task        = $06
cb_buff        = $0A

;Signals

;TODO mouse in port2 - modified code, or separate driver. Not supported yet.

			
* Entered with:       
*  D0 == scratch      
*  D1 == scratch      
*                     
*  A0 == scratch (execept for highest pri vertb server)
*  A1 == is_Data
*  A5 == vector to interrupt code (scratch)
*  A6 == scratch

            SECTION    CODE 
            XDEF       _mouSTerVBinterrupt

spare_sync:
            ; When the LMB is pressed, we can use MMB line to signal the mouSTer to release LMB and sync.
            ; In case of compatybility issues,with potgo, potgo.resource should be used. Maybe include in future updates.
            ;
            ; this part is only executed when LMB is pressed ... soo its not so important to be sexy optimized.

            ; get status of MMB, if pressed just leave .. 
            ; we can go further and implement RMB as second spare_spare method
            ; but ... is it relaly necessary? NO. Who really need to hold MMB pressed and use wheel?
            ; a0 is pointing to INTENA
            ; 0 in POTGOR button presed

            btst       #MMBnumber,POTGOR_INTENA(a0)
            beq        Exit                     ; MMB pressed ... nothing to do, unless LMB spare sync will be programmed.
                                   
            move.w     #MMB0val,POTGO_INTENA(a0)    ; assert MMB low

            moveq      #8,d1                  
                          
LMBloop:    btst       #LMBnumber,(a5)                          ; wait for LMB high
            dbne       d1,LMBloop
            beq.s      clean_up_potgo_and_exit ; sorry ... still low, give up.
            
            move.w     #MMB1val,POTGO_INTENA(a0)
            bra.s      sync                     ; and jump to the main program
            
clean_up_potgo_and_exit:
            move.w     #MMB1val,POTGO_INTENA(a0)

waitMMBup:  btst       #MMBnumber,POTGOR_INTENA(a0) ;wait for mmb become high again
            beq        waitMMBup                  ; risk od deadlock in case of faulty hardware !! 

            bra      Exit               
; ------------- Entry point ------------------

_mouSTerVBinterrupt
            movem.w    D2-D7,-(SP)

   			;Prepare a5 and a6
            lea        CIAAPRA,a5               ;CIAAPRA
            lea        $200(a5),a6              ;CIAADDRA

			;-------------------------------------------
			;Enter critical section, disable interrupts.
			;------------------------------------------
            lea        INTENA,a0		
            move.w     INTENAR_INTENA(a0),d0    ; read interrupts status
            ori.w      #$8000,d0                ; Set set bit ;)
            swap       d0                       ; keep for later
            ;lea                 INTENA,a0		
       
			
            bclr.b     #LMBnumber,(a5)          ; put the correct value in output data register.
            btst.b     #LMBnumber,(a5)          ; Check if LMB is not pressed ... 
            beq.s      spare_sync               ; we still have a tiny few us window where mouster can report LMB
                                                ; but i think this is not worth covering this case.

sync:       move.w     #$7FFF,(a0)              ; disable interrupts (set bit clr)
			;every line below is syncd with eCLK
			;and should execute (almost) exactly same speed on all machines.
			;move.b d3,(a5)	; write 0 to output
			;a5 CIAAPRA		(PoRt A)
			;a6 CIAADDDRA 	(Data Direction Register A)
            
            bset.b     #LMBnumber,(a6)          ;LMB as output + set Low
            bset.b     #LMBnumber,(a5)          ;LMB Set high
            bclr.b     #LMBnumber,(a6)          ;LMB as input

            move.b     (a5),d0
            move.b     (a5),d1 
            move.b     (a5),d2
            move.b     (a5),d3 
            move.b     (a5),d4
            move.b     (a5),d5 
            move.b     (a5),d6                  ; parity
            move.b     (a5),d7                  ; stop bit (0)

			;----------------------------------------
			;End Critical section, restore interrupts.
			;----------------------------------------
            swap       d0
            move.w     d0,(a0)
            swap       d0

			; check bit 7 LOW - now we're almost sure the data is correct.
            ; This is a safety feature that detects state when no mouSTer is present.
            ; by modyfying mouSTer firmware, 
            ; it's possible to end processing in this point when no new events.
            ; Just set all bits high. I'm too lazy to implement this.
            andi.b     #LMBmask,d7
            bne.s      Exit

b6:         rol.b      #2,d6
            andi.b     #%00000001,d6            

b5:         add.b      d5,d5                    ; 12 cycles 6 bytes per bit
            add.b      d5,d5                    ; alternative may be roxl.b #2,dx; roxl.b #1,d6.
            addx.b     d6,d6                    ; 2 bytes shorter but 18 cycles. May be faster on 040+. Not verified.

b4:         add.b      d4,d4
            add.b      d4,d4
            addx.b     d6,d6

b3:         add.b      d3,d3
            add.b      d3,d3
            addx.b     d6,d6

b2:         add.b      d2,d2
            add.b      d2,d2
            addx.b     d6,d6

b1:         add.b      d1,d1
            add.b      d1,d1
            addx.b     d6,d6

b0:         add.b      d0,d0
            add.b      d0,d0
            addx.b     d6,d6

bitsDone:		
            ; d6 contains valid state data. Unless parity

parity:         
            ifnd       NO_PARITY
            move.b     d6,d0                ; calculate parity, may be ommited but not recommended.
            Move.b     d0,d1
            lsr.b      #4,d1
            eor.b      d1,d0
            andi.b     #%00001111,d0
            move.w     #$6996,d1
            btst       d0,d1
            beq.s      Exit
            endif

            ; check if something changed
            lea        lastState(PC),a0
            cmp.b      (a0),d6  
            beq.s      Exit
            move.b     d6,(a0)

            ; and send data to the main task.

		    ; The circular buffer is so huge (256)B so its almost not possible to to overrun it
            ; so ... we do not check for buffer overrun.
            ; in case of overrun the buffer will appear as empty.

            moveq      #0,d1
            move.b     (a1),d1                  ; cb_head

			;move data to the buffer
            move.b     d6,cb_buff(a1,d1)        ;data 
            addq.b     #1,d1                    ;increase the head
            move.b     d1,(a1)                  ;and save it

            ; signal the main task
            move.l     cb_sign(a1),d0
            move.l     cb_task(a1),a1
            move.l     4.w,a6
            jsr        _LVOSignal(a6) 
	
Exit:
            move.w     (sp)+,d2
            move.w     (sp)+,d3
            move.w     (sp)+,d4
            move.w     (sp)+,d5
            move.w     (sp)+,d6
            move.w     (sp)+,d7
          

            lea        _custom,a0
            moveq      #0,d0                   
            rts
; ---------------- end interrupt -------------
    
; local "static" data
lastState:  dc.b       0                        ; last state signaled to main thread

            end
