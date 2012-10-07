;General Project Program (ver 3.7)
;Level used to control flow to control speed
;Hi freq counter (upto 9999 Hz) included
;Jump back option during fmin and max modes included
;Display and counting at only 1 second intervals
;Dynamic lag included - 3 sec
;Includes auto backlight off
;Includes Easter
;all done

;TO DO:

;Include smart control (range,annunciation and messages)
;Includes smart error messaging
;solve Flicker problem
           
;NOTES
;both number ofpulses 1sec as well as 1/pulse duration method used
;to determine frequency

;REGS
     ;r0 = 1/32 sec count               
     ;r1 = pulse count lobyte regs
     ;r2 = pulse count hibyte regs  
     ;r3 = set freq                     
     ;r4 =                  
     ;r5 = error persistence time             
     ;r6 = sec count                    
     ;r7 = pulse hibyte counter ;general loop counter/msec count?

 ;frequency generation address
     ;ra0= lo byte ontime  value
     ;ra1= hi byte ontime  value
     ;ra2= lo byte offtime value
     ;ra3= hi byte offtime value
     ;ra4= freq count lobyte
     ;ra5= freq count hibyte 
     ;ra6= freq count integer value
     ;ra7= freq count decimal value 

;16bitdiv
     ;rb0= input value hibyte
     ;rb1= input value lobyte
     ;rb2= 
     ;rb3= resultant quotient hibyte
     ;rb4= resultant quotient lobyte
     ;rb5= 
     ;rb6= 
     ;rb7= resultant remainder

     ;rc0= gen purpose
     ;rc1= gen purpose
     ;rc2= 
     ;rc3= 
     ;rc4= 
     ;rc5= 
     ;rc6= 
     ;rc7= 

;TIMERS
     ;T0 = 1 sec period
     ;T1 = freq generation

;PORTS + PIN ASSIGNMENTS
  ;LCD-
       ;P0   = data port
       ;p2.7 = rs
       ;p2.6 = rw
       ;p2.5 = en of LCD
       ;p2.4 = backlight

  ;BUTTONS-       
       ;p2.0 = F buttons
       ;p2.1 = UP 
       ;p2.2 = DN
       ;p2.3 = BKL

  ;DAC-
       ;port 1

  ;FREQ-
       ;p3.2


;ADDRESSABLE BITS
       ;bit 00h = freq time period bit ;x(freq output bit)
       ;bit 01h = (bit 0 of RAM byte 20h)=sec count flag
       ;bit 02h = time/count-pulse mode bit
       ;bit 03h = error flag
       ;bit 04h = control action checkbit
       ;bit 05h = match bit
       ;bit 06h = range flag
       ;bit 07h = watchdog bit
       ;bit 08h = acknowledge bit
       
;_______________________________________________________

ftpbit equ 00h
secbit equ 01h
tcpbit equ 02h
;errbit equ 03h
chkbit equ 04h
macbit equ 05h
aprbit equ 06h
wdgbit equ 07h
ackbit equ 08h


fset equ 03h                    ;r3 = set freq

errval equ 09h                  ;type of error incurred
dacval equ 0ah                  ;reg bank 1
deldac equ 0bh                  ;ra0-ra7

fchi equ 0ch
fclo equ 0dh
fcnh equ 0eh
fcnl equ 0fh

rb0 equ 010h                    ;reg bank 2
rb1 equ 011h                    ;used for 16 bit division
rb2 equ 012h
rb3 equ 013h
rb4 equ 014h
rb5 equ 015h
rb6 equ 016h
rb7 equ 017h

rc0 equ 018h                    ;general purpose
rc1 equ 019h
rc2 equ 01ah
rc3 equ 01bh
rc4 equ 01ch
rc5 equ 01dh
rc6 equ 01eh
rc7 equ 01fh

fc0 equ 030h                    ;current display hundreds '0'
fc1 equ 031h                    ;div display tens     '3'
fc2 equ 032h                    ;div display units    '0'
fc3 equ 033h                    ;div display dec pt   '.'                    
fc4 equ 034h                    ;div display dec.1    '0'
fc5 equ 035h                       
fp0 equ 036h                    ;previous display hundreds '0'  
fp1 equ 037h                    ;div display tens     '3'
fp2 equ 038h                    ;div display units    '0'
fp3 equ 039h                    ;div display dec pt   '.'                                             
fp4 equ 03ah                    
fp5 equ 03bh                    
fs0 equ 03ch                    ;set display hundreds '0'
fs1 equ 03dh                    ;div display tens     '0'
fs2 equ 03eh                    ;div display units    '0'
fs3 equ 03fh                    ;div display dec pt   '.' 
fs4 equ 040h                    
fs5 equ 041h

dvdhi equ 042h                  ;16 bit/ 8bit div i/o regs
dvdlo equ 043h
dvsr  equ 044h
h2bh  equ 045h                  ;hex to ascii conversion regs
h2bl  equ 046h
h2bf  equ 047h

deadt  equ 048h
bklt   equ 049h
fine   equ 050h

;lcd from 8052.com

RS  equ p2.5            ;***** Order will change on PCB
EN  equ p2.7            ;remember to change!!
RW  equ P2.6            ;******* CHANGED !!! **********
eot equ 0feh
DATA equ p0
                    

;t1hi equ 045h                   ; 1 sec @ 4MHz w/ 7 repetitions
;t1lo equ 0f4h

;_______________________________________________________

org 0000h
        sjmp start

;Servicing External inerrupt 0
org 0003h                       ;ext int ex0 interrupt
        jb tcpbit,pulse        
        inc r1
        cjne r1,#00h,ext0
        inc r2
        setb 09h
ext0:   reti

;servicing Timer0 interrupt
org 000bh
intT0:  clr tcpbit              ;timer t0 for freq timeperiod
        reti

;servicing Timer1 interrupt
org 001bh                       
intT1:                          ;timer t1 for 1 sec        
        clr tcon.6              ;(1)stop timer t1
        mov tl1,#0f4h           ;(2)set starting no in t0 regs
        mov th1,#045h           ;(2)
        djnz r0,nosec           ;(2) total tsf =tsf - 8c
                                ;1 sec over
sec:    mov r0,#07h             ;set fraction sec count in r0
        setb chkbit
        jb tcpbit,nosec
        clr ie.0                ;stop counter int0                                        
        mov fcnl,r1             ;mov freq count to ra4 & ra5
        mov fcnh,r2
        mov r1,#00h             ;reset freq count
        mov r2,#00h
        clr 09h                 ;rngbit
        setb ie.0               ;start counter
sec1:   jnb secbit,nosec        ;?? mov r6,#00h
        inc r6

nosec:  setb tcon.6             ;(1)start timer t1
        reti                    ;(2)

;_______________________________________________________

pulse:                          ;Servicing External inerrupt 0
        clr ie.0                ;on pin 12 (p3.2)        
        jb ftpbit,offb          ;(2)
onb:    mov th0,#00h            ;(2)
        mov tl0,#00h            ;(2)
        setb tcon.4             ;(1)start timer t1
        setb ftpbit             ;
        ;setb ie.0
        sjmp done0
offb:   nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop  
        clr tcon.4
        mov fchi,th0
        mov fclo,tl0
        clr ftpbit
        setb 05h
done0:  setb ie.0
        reti
                   

;_______________________________________________________
start:
        mov sp,#60h             ;set stack pointer to 70h
        mov p0,#00h             ;reset ports to 0
        mov p1,#00h
        mov p2,#00h
        mov p3,#00h

        clr psw.3               ;select regs bank 0
        clr psw.4

;setting default values
        mov r0,#07h             ;set fraction sec count in r0
        mov r1,#00h             ;reset freq cnt in r1
        mov r2,#00h             
        mov r3,#01eh            ;default setfreq=30
        mov r4,#00h             ;
        mov r5,#00h             ;default gain constant = 1
        mov r6,#00h             ;default sec count =0
        clr 00h
        clr 01h
        clr 02h
        clr 04h
        clr 05h
        clr 06h
        clr 07h
        setb p2.4


        mov dacval,#00h
        mov deldac,#00h
        mov deadt,#03h
        mov bklt,#0f0h
        mov r7,#00h        
;____________________________________________________________________

;LCD initialise and Display Routine here

init:   lcall dly
        setb p2.4

        lcall INIT_LCD
        lcall CLEAR_LCD

        setb EN
        clr RS
        mov DATA,#080h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg1a
        lcall LCD     

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg1b
        lcall LCD   
                      
        lcall dly
        lcall dly
        lcall dly
;__________________________________________________________________
        
pol0:   setb p3.2               ;configure pin 12 as input   
                                                                  
        setb ip.0               ;ext int 0 has hi priority
        setb ip.1               ;timer0 overflow has hi priority
        setb ip.3               ;timer1 overflow has hi priority??
        clr ip.2                ;ext int 1 has lo priority

               
        mov tl0,#00h            ;(2) 
        mov th0,#00h            ;(2)

        ;setb ie.0              ;enable ext int0
        ;setb ie.1              ;enable timer t0 int        
        
        mov r0,#07h             ;set fraction sec count in r0
        mov r1,#00h             ;reset freq cnt in r1

        orl tmod,#0ffh          ;
        anl tmod,#011h          ;use t1 as timer in mode 1
        orl ie,#08ah            ;enable ints and t1 int
        setb tcon.0             ;allow falling-edge triggered ext ints        

        clr tcpbit
        setb tcon.6             ;start t1 sec timing     
        setb ie.0               ;enable int0 to start counting

        lcall CLEAR_LCD

        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg0a
        lcall LCD      
 
        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg0b
        lcall LCD

pol0a:  setb secbit
        mov a,r6
        jb acc.1,dacon
        mov p1,#00h
        sjmp poll0
dacon:  mov p1,#0ffh

poll0:  setb p2.0
        setb p2.1
        setb p2.2
        setb p2.3
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#0fh
        jz pol0a

poll0b: lcall dbnc
        setb p2.0
        setb p2.1
        setb p2.2
        setb p2.3
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#0fh
        jz pol0a      

;__________________________________________________________________
;Input set freq here;
        setb p2.4

poll1a: mov r6,#00h
        clr secbit

        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg2a
        lcall LCD      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg2b
        lcall LCD      

disp1:  setb EN
        clr RS
        mov DATA,#0c7h
        clr EN
        lcall WAIT_LCD

        mov h2bh,#00h
        mov h2bl,fset           ;quo in a
        mov h2bf,#00h           ;rem in b
        lcall hex2asc

        mov a,fc0
        lcall DISPLAY
        mov a,fc1
        lcall DISPLAY
        mov a,fc2
        lcall DISPLAY

        mov a,#' ' 
        lcall DISPLAY
        mov a,#'H'
        lcall DISPLAY
        mov a,#'z'
        lcall DISPLAY

poll1:  setb p2.3       
        jnb p2.3,f1a        
        setb p2.2
        jnb p2.2,up1a
        setb p2.1
        jnb p2.1,dn1a
        setb p2.0
        jb p2.0,poll1b
        ;lcall bkl1a
poll1b: sjmp poll1
;____________________________________________________________________        

bkl1a:  lcall dbnc
        lcall dbnc
        setb p2.0
        jb p2.0,bkl1b
        cpl p2.4        ;tcpbit for testing
        mov r6,#00h
        setb secbit

        ;jnb 03h,bkl1b
        ;setb ackbit
bkl1b:  ret
;____________________________________________________________________

up1a:   lcall dbnc
        setb p2.2               ;increment set freq
        jb p2.2,poll1
        mov a,fset
up1:    lcall dbnc
        cjne a,#0c8h,up1b
        sjmp poll1
up1b:   inc fset
        sjmp disp1

dn1a:   lcall dbnc              ;decrement set freq
        setb p2.1
        jb p2.1,poll1
        mov a,fset
dn1:    lcall dbnc
        cjne a,#0ah,dn1b
        sjmp poll1
dn1b:   dec fset
        ajmp disp1

;____________________________________________________________________
;"Adjust Pressure for max spin..."

f1a:    lcall dbnc
        setb p2.3
        jb p2.3,poll1

f1:     setb p2.4
        clr secbit
        mov r6,#00h

        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg3a
        lcall lcd      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg3b
        lcall lcd     
                      
                
poll2:  setb p2.3
        jnb p2.3,f2a
        setb p2.2
        jnb p2.2,up2a
        setb p2.1
        jnb p2.1,up2a
        setb p2.0
        jb p2.0,poll2b
        lcall dbnc
        setb p2.0
        jb p2.0,poll2b
        lcall bkl1a
poll2b: sjmp poll2
;____________________________________________________________________

up2a:   lcall dbnc 
        setb p2.2
        jb p2.2,poll2
        setb p2.1
        jb p2.1,poll2
        ajmp poll1a

        
f2a:    lcall dbnc
        setb p2.3
        jb p2.3,poll2
;___________________________________________________________________
;Set Max Spin

f2:     clr tcpbit
        clr secbit
        setb p2.4
        setb tcon.6             ;start t1 sec timing     
        setb ie.0               ;enable int0 to start counting


        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg4a         ;"Set Max Spin "        
        lcall lcd
        
        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg7b         ;"F act:"
        lcall LCD

freq01: mov p1,#00h

        mov h2bh,fcnh
        mov h2bl,fcnl
        mov h2bf,#00h     
        lcall hex2asc           ;LCD display program here:                     

        setb en
        clr RS
        mov DATA,#0c7h
        clr EN
        lcall WAIT_LCD

        mov a,fc0               ;posn1.8
        lcall DISPLAY           
        mov a,fc1               ;1.9
        lcall DISPLAY           
        mov a,fc2               ;1.10
        lcall DISPLAY           

        mov a,fc3               ;1.11
        lcall DISPLAY           
        mov a,fc4               ;1.12
        lcall DISPLAY           
        mov a,fc5               ;1.13
        lcall DISPLAY         
                     
        mov a,#' '              ;1.14
        lcall DISPLAY           
        mov a,#'H'              ;1.15
        lcall DISPLAY           
        mov a,#'z'              ;1.16
        lcall DISPLAY

        setb p2.1
        setb p2.2
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#06h
        jz fmax0
        lcall dbnc
        setb p2.1
        setb p2.2
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#06h
        jz fmax0
        ajmp poll1a

fmax0:  mov a,fcnh
        jnz fjmp1
        mov a,r3
        add a,#05h
        cjne a,fcnl,fmax1
        sjmp poll10
fmax1:  jc poll10
fjmp1:  sjmp freq01

poll10: setb p2.3
        jb p2.3,fjmp1
        lcall dbnc
        setb p2.3
        jb p2.3,fjmp1
;___________________________________________________________________
;Adjust Gain message

f10a:   setb p2.4
        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg4b
        lcall lcd      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg4c
        lcall lcd     
                      
                
poll10a:setb p2.1
        setb p2.2
        setb p2.3
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#0eh
        jz poll10a
        lcall dbnc
        setb p2.1
        setb p2.2
        setb p2.3
        mov a,#00h
        mov a,p2
        cpl a
        anl a,#0eh
        jz poll10a
;___________________________________________________________________
;Adjust Gain

f10:         
        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg5a         ;"Adjust Gain "        
        lcall lcd
        
        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg7b         ;"F act:"
        lcall LCD

freq02: mov p1,#0ffh

        mov h2bh,fcnh
        mov h2bl,fcnl
        mov h2bf,#00h       
        lcall hex2asc           ;LCD display program here:
        
        setb en
        clr RS
        mov DATA,#0c7h
        clr EN
        lcall WAIT_LCD

        mov a,fc0               ;posn1.8
        lcall DISPLAY           
        mov a,fc1               ;1.9
        lcall DISPLAY           
        mov a,fc2               ;1.10
        lcall DISPLAY           

        mov a,fc3               ;1.11
        lcall DISPLAY           
        mov a,fc4               ;1.12
        lcall DISPLAY           
        mov a,fc5               ;1.13
        lcall DISPLAY         
                     
        mov a,#' '              ;1.14
        lcall DISPLAY           
        mov a,#'H'              ;1.15
        lcall DISPLAY           
        mov a,#'z'              ;1.16
        lcall DISPLAY

        setb p2.1
        jnb p2.1,fmin
        setb p2.2
        jnb p2.2,fmin
        sjmp fmin0
fmin:   lcall dbnc
        setb p2.1
        jb p2.1,fmin0
        setb p2.2
        jb p2.2,fmin0
        ajmp poll1a        

fmin0:  mov a,fcnh
        jnz freq02
        mov a,r3
        subb a,#05h
        cjne a,fcnl,fmin1
        sjmp poll11
fmin1:  jnc poll11
        sjmp freq02


poll11: setb p2.3        
        jb p2.3,freq02
        lcall dbnc
        setb p2.3
        jb p2.3,freq02
;___________________________________________________________________
;Start MAT

mat0:   lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg6a         ;"press F to start MAT Operation"
        lcall lcd      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg6b
        lcall lcd   
poll3:  setb p2.0
        setb p2.1
        setb p2.2
        setb p2.3
        mov a,p2
        jnb acc.3,f3a
        jnb acc.2,poll3c
        jnb acc.1,poll3c
        jb acc.0,poll3b
        lcall bkl1a
poll3b: sjmp poll3
poll3c: ajmp poll1a


;____________________________________________________________________
;Start opern here

f3a:    lcall dbnc
        setb p2.3               
        jb p2.3,poll3
        mov dacval,#00h                    
                    
        setb ip.0               ;ext int 0 has hi priority
        setb ip.1               ;timer0 overflow has hi priority
        setb ip.3               ;timer1 overflow has hi priority??                  
        clr ip.2                ;ext int 1 has lo priority
        clr ip.4                                        
        setb p3.2               ;configure p3.2 as input
               

        mov tl0,#00h            ;(2) 
        mov th0,#00h            ;(2)

        orl ie,#08ah            ;enable ints and t1 int
        setb tcon.0             ;allow falling-edge triggered ext intssetb tcon.4             ;start t0 pulse measurement          

        orl tmod,#0ffh          ;
        anl tmod,#011h          ;use t1 as timer in mode 1        

        setb tcon.6             ;start t1 timing       
        setb ie.0               ;enable int0 to start counting                                                             

;_______________________________________________________

;freq compare and LCD update  prog here:
f3:     lcall dly
        clr tcpbit
        clr psw.3               ;select regs bank 0
        clr psw.4
        mov r5,#01eh            ;error tolerance time = 30 sec
        mov bklt,#0f0h
        mov deadt,#03h
                                  
f3b:    clr secbit
        lcall CLEAR_LCD

        mov fp0,#00h
        mov fp1,#00h
        mov fp2,#00h
        mov fp3,#00h
        mov fp4,#00h

        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg7a         ;F set: 
        lcall LCD

        mov h2bh,#00h
        mov h2bl,fset
        mov h2bf,#00h
        lcall hex2asc

        mov fs0,fc0
        mov fs1,fc1
        mov fs2,fc2
        mov fs3,fc3
        mov fs4,fc4
        mov fs5,fc5

        setb EN
        clr RS
        mov DATA,#087h          ;display set freq Hz
        clr EN
        lcall WAIT_LCD
        mov a,fs0               ;posn1.8
        lcall DISPLAY           
        mov a,fs1               ;1.9
        lcall DISPLAY           
        mov a,fs2               ;1.10
        lcall DISPLAY           

        mov a,fs3               ;1.11
        lcall DISPLAY           
        mov a,fs4               ;1.12
        lcall DISPLAY           
        mov a,fs5               ;1.13
        lcall DISPLAY         
                     
        mov a,#' '              ;1.15
        lcall DISPLAY           
        mov a,#'H'              ;1.16
        lcall DISPLAY           
        mov a,#'z'              ;
        lcall DISPLAY
       

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg7b         ;"F set : "
        lcall LCD
        setb chkbit
        clr ackbit
        clr 03h
        setb p2.4
        setb secbit
;_______________________________________________________
;Main control loop

loop:   nop
        mov p1,dacval  
                                           
loop2:  jnb tcpbit,freq3
        sjmp freq1
freq3:  ajmp freq2
;contn0: ajmp contn1

;_______________________________________________________
;32 bit by 16 bit division
freq1:  
        mov rc0,fclo            ;lobyte in rc0    
        mov rc1,fchi            ;hibyte in rc1        
                
freq0:  mov rc5,rc0             ;lobyte in rc5
        mov rc6,rc1             ;hibyte in rc6
        mov rc2,#015h           ;divides 32b no by 16b no by div
        mov rc3,#016h           ;both nos by 2 until divisor = 8bit
        mov rc4,#05h            ;then carries out 16/8bit division
try:    mov a,rc6               ;check if hibyte is 0
        jz go1                  ;if yes,proceed
        clr c
        rrc a
        mov rc6,a
        mov a,rc5
        rrc a
        mov rc5,a

        mov a,rc4
        clr c
        rrc a
        mov rc4,a
        mov a,rc3
        rrc a
        mov rc3,a
        mov a,rc2
        rrc a
        mov rc2,a
        sjmp try

go1:    mov dvdhi,rc3
        mov dvdlo,rc2
        mov dvsr,rc5            ;Find 'x'=integer part of freq
        lcall b16div            ;Q in rb3
        mov r7,rb3

        mov rc5,rc0
        mov rc6,rc1

cx:     mov dvdhi,#0bah
        mov dvdlo,#03h
        mov dvsr,r7
        lcall b16div
        mov rc5,rb3              ;lobyt of quo ql in rc5
        mov rc6,rb4              ;hibyt of quo qh in rc6
        mov rc7,rb5              ;remainder in r rc7

        mov a,rc6
        mov b,#07h
        mul ab
        mov rc6,a
        mov a,rc5
        mov b,#07h
        mul ab
        mov rc5,a                ;lobyt of (q*7) in rc5
        mov a,b
        add a,rc6
        mov rc6,a                ;hibyt of (q*7) in rc6
        mov a,rc7
        mov b,#07h
        mul ab
        mov dvdhi,b
        mov dvdlo,a
        mov dvsr,r7
        lcall b16div
        mov a,rc5               ;quo of (r*7)/x in rb3
        add a,rb3
        mov rc5,a               ;
        jnc cx1
        inc rc6

cx1:    clr c                   ;find Cx-Cp
        mov a,rc5
        subb a,rc0
        jnc cx2
        cpl a
        inc a
        dec rc6
cx2:    mov rc5,a
        mov a,rc6
        subb a,rc1
        mov rc6,a
        jnc go2
        dec r7
        sjmp cx

go2:    mov a,rc6               ;find x(Cx-Cp)
        mov b,r7
        mul ab
        mov rc6,a
        mov a,rc5
        mov b,r7
        mul ab
        mov rc5,a
        mov a,b
        add a,rc6
        mov rc6,a

dv1:    mov dvdhi,rc1           ;Cp/64h
        mov dvdlo,rc0
        mov dvsr,#064h
        lcall b16div
        mov a,rb4                              
        jz x2                   ;check if hibyte is 0
        clr c                   ;if 12 bit val, mul div by 2
        rrc a        
        mov a,rb3
        rrc a
        mov rb3,a

        mov a,rc6
        clr c
        rrc a
        mov r6,a
        mov a,rc5
        rrc a
        mov rc5,a

x2:     mov dvdhi,rc6
        mov dvdlo,rc5
        mov dvsr,rb3
        lcall b16div   

        mov b,rb3
x5:     mov a,b
        cjne a,#063h,x3
        sjmp x4
x3:     jc x4                   ;f dec part >99,sub 
        clr c
        mov a,b
        subb a,r7
        mov b,a
        inc r7        
        sjmp x5

x4:     ;mov a,r7
        mov fcnh,#00h
        mov fcnl,r7
        mov h2bh,#00h
        mov h2bl,fcnl
        mov h2bf,b
        sjmp fdisp
;_______________________________________________________

freq2:  mov h2bl,fcnl
        mov h2bh,fcnh
        mov h2bf,#00h        
;_______________________________________________________

fdisp:  lcall hex2asc
        nop                     ;LCD display program here:
        nop

;_______________________________________________________
;Control Action

loop0:  jnb chkbit,contn
        clr chkbit        

        jnb aprbit,loop3
        ;jb 03h,loop3
        cjne r6,#0f0h,loop3
        clr p2.4
        clr secbit
        mov r6,#00h

loop3:
;        jnb 03h,loop1        
;        djnz r5,loop2
;        cpl p2.4
;errmsg: nop                     ;If error persists for >30 sec,
;        nop                     ;display message here
;        inc r5                  ;until acknowledged or rectified

;        setb EN
;        clr RS
;        mov DATA,#80h
;        clr EN
;        lcall WAIT_LCD

;        mov a,errval
;        jz loop1
;        cjne a,#0ah,errm1
;        sjmp loop2                
;errm1:  cjne a,#01h,errm2
;        mov dptr,#ermsg1        ;"Increase airflow..."
;        sjmp errm0

;;errm2:  cjne a,#02h,loop1      ;WRONG!
;        mov dptr,#ermsg2        ;"Decrease airflow..."

;errm0:  lcall LCD
;        mov errval,#0ah         ;message displayed

;        sjmp loop2
        
;loop1:  mov r5,#01eh
;        setb p2.4

        mov a,fcnh
        jnz contn
        
ctrla:  mov a,fc0
        cjne a,fs0,ctrl1
ctrlb:  mov a,fc1
        cjne a,fs1,ctrl1


ctrlc:  djnz deadt,contn
        mov deadt,#02h
        
        clr aprbit
        mov a,fset
        cjne a,fcnl,aprox1
        setb aprbit
        mov a,h2bf
        jnz mac1
        setb macbit
        sjmp ctrl              
mac1:   cjne a,#0ah,mac2
        inc dacval
        sjmp ctrl
mac2:   jc mac3  
        inc dacval
mac3:   sjmp ctrl
       

aprox1: mov a,fset
        dec a
        cjne a,fcnl,aprox2
        setb aprbit
        mov a,h2bf
les1:   cjne a,#05ah,les2
        dec dacval
        sjmp ctrl
les2:   jnc les3  
        dec dacval
les3:   sjmp ctrl

aprox2: mov a,fc2
        cjne a,fs2,ctrl2
        sjmp contn
ctrl2:  mov a,dacval              ;correction for 1Hz error
        jc ctrl2b                 
        clr c
        add a,#05h               ;if act < set,inc a
        jnc ctrl2c
        mov a,#0ffh
        sjmp ctrl2c
ctrl2b: clr c
        subb a,#05h
        jnc ctrl2c
        mov a,#00h
ctrl2c: mov dacval,a
        sjmp ctrl

ctrl1:  mov a,dacval              ;correction for 10Hz error
        jc ctrl1b                 
        clr c
        add a,#0fh               ;if act < set,inc a
        jnc ctrl1c
        mov a,#0ffh
        sjmp ctrl1c
ctrl1b: clr c
        subb a,#0fh
        jnc ctrl1c
        mov a,#00h
ctrl1c: mov dacval,a

ctrl:   mov p1,dacval

;_______________________________________________________

contn:  mov a,fc0
        cjne a,fp0,lcdup
        mov a,fc1
        cjne a,fp1,lcdup
        mov a,fc2
        cjne a,fp2,lcdup
        mov a,fc3
        cjne a,fp3,lcdup
        mov a,fc4
        cjne a,fp4,lcdup
        mov a,fc5               ;***flicker!!!????
        cjne a,fp5,lcdup        ;***
        sjmp fmod        
                        
lcdup:  mov fp0,fc0
        mov fp1,fc1
        mov fp2,fc2
        mov fp3,fc3
        mov fp4,fc4
        mov fp5,fc5
               
        setb en
        clr RS
        mov DATA,#0c7h
        clr EN
        lcall WAIT_LCD

        mov a,fc0               ;posn1.8
        lcall DISPLAY           
        mov a,fc1               ;1.9
        lcall DISPLAY           
        mov a,fc2               ;1.10
        lcall DISPLAY           

        mov a,fc3               ;1.11
        lcall DISPLAY           
        mov a,fc4               ;1.12
        lcall DISPLAY           
        mov a,fc5               ;1.13
        lcall DISPLAY         
                     
        mov a,#' '              ;1.14
        lcall DISPLAY           
        mov a,#'H'              ;1.15
        lcall DISPLAY           
        mov a,#'z'              ;1.16
        lcall DISPLAY

        lcall dbnc
        lcall dbnc
        lcall dbnc
        ;lcall dbnc
        ;setb ie.0

;_______________________________________________________
;frequency mode
fmod:   mov a,fcnh
        jz fmod1
        clr tcpbit
        sjmp contn1

fmod1:  mov a,#09h 
        cjne a,fcnl,set1     
        setb tcpbit
        sjmp contn1

set1:   jnc clr1                ;if 9 > fint                
        setb tcpbit             ;if fint > 9,set tcpbit
        sjmp tog1
clr1:   clr tcpbit
        sjmp contn1

tog1:   mov a,#0c8h             ;200
        cjne a,fcnl,set2
        clr tcpbit              ;if 200 = fint ,clr tcpbit                    
        sjmp contn1
set2:   jnc tog2                ;if 200 > fint ,jump
        clr tcpbit              ;if 200 < fint ,clr tcpnit
        sjmp contn1

tog2:   mov a,#0beh
        cjne a,fcnl,set3
        setb tcpbit             ;if 190 = fint ,clr tcpnit
        sjmp contn1
set3:   jnc contn1              ;if 190 > fint ,jump contn
        setb tcpbit
     
;_______________________________________________________
;error

errmod: jb macbit,noerr

        mov a,fcnl
        jnz err0
        mov errval,#01h         ;type 1 error
        setb 03h
        sjmp poll4

err0:   mov a,fset
        cjne a,fcnl,err1
        sjmp noerr
err1:   jnc more1               ;if fact < fset
less1:  mov a,dacval
        jnz noerr
        mov errval,#01h         ;type 1 error
        setb 03h
        sjmp poll4

more1:  mov a,dacval
        cjne a,#0ffh,noerr
        mov errval,#02h         ;type 2 error
        setb 03h
        sjmp poll4

noerr:  jnb 03h,noerr1
        setb ackbit
noerr1: clr 03h

contn1: nop
;_______________________________________________________
;keypad polling
poll4:  setb p2.3
        jnb p2.3,f4a
        setb p2.2
        jnb p2.2,f4a
        setb p2.1
        jnb p2.1,f4a
        setb p2.0
        jb p2.0,poll4b
        lcall dbnc
        setb p2.0
        jb p2.0,poll4b
        lcall bkl1a
poll4b: ajmp loop
;__________________________________________________________________

f4a:    lcall dbnc
        setb p2.3
        jb p2.3,poll4
        setb p2.4
        mov bklt,#0f0h
f4b:    jnb p2.3,f4b
        lcall dbnc
        lcall dbnc

f4:     lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg8a
        lcall lcd      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg6b
        lcall lcd

        ;cpl tcpbit              ;***** Testing!!! *******
        
        mov r6,#00h 
        setb secbit
poll5:  ;setb p2.4
        ;setb p2.0
        setb p2.1
        setb p2.2
        setb p2.3
        mov a,p2
        jnb acc.3,f5a
        jnb acc.2,f5b
        jnb acc.1,f5b
        ;jb acc.0,poll5b
        ;lcall bkl1a
poll5b: cjne r6,#05h,poll5d
poll5c: ajmp f3b
poll5d: jnc poll5
        sjmp poll5

f5b:    lcall dbnc
        setb p2.2
        jb p2.2,f5c
        ajmp f3b
f5c:    setb p2.1
        jb p2.1,poll5
        ajmp f3b

f5a:    lcall dbnc
        setb p2.3
        jb p2.3,poll5

f5:     setb p2.4
        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg9a
        lcall lcd      

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

        mov dptr,#msg6b
        lcall lcd

        lcall dly        
        clr ie.0                ;stop counter int0
        clr tcon.6              ;stop timer t1
        clr tcon.4
        mov p1,#00h

        setb p2.0
        jb p2.0,end1
        lcall dbnc
        lcall dbnc
        setb p2.0
        jb p2.0,end1

;_______________________________________________________
;Easter

easter: mov r7,#00h
eloop:          
        lcall CLEAR_LCD
        setb EN
        clr RS
        mov DATA,#80h
        clr EN
        lcall WAIT_LCD

        inc r7
        mov a,r7 
        cjne a,#05h,estm1a
        sjmp end1

estm1a: jnc end1
        cjne a,#01h,estm2a
        mov dptr,#eastr1a       ;"Designe & "
        sjmp estm0a
        
estm2a: cjne a,#02h,estm3a
        mov dptr,#eastr2a       ;"Kunal Kandekar &"
        sjmp estm0a

estm3a: cjne a,#03h,estm4a
        mov dptr,#eastr3a       ;"Under Guidance"
        sjmp estm0a

estm4a: mov dptr,#eastr4a       ;"

estm0a: lcall LCD

        setb EN
        clr RS
        mov DATA,#0c0h
        clr EN
        lcall WAIT_LCD

estm1b: cjne a,#01h,estm2b
        mov dptr,#eastr1b       ;"
        sjmp estm0b

estm2b: cjne a,#02h,estm3b
        mov dptr,#eastr2b       ;"
        sjmp estm0b

estm3b: cjne a,#03h,estm4b
        mov dptr,#eastr3b       ;"
        sjmp estm0b

estm4b: mov dptr,#eastr4b        ;"Decrease airflow..."

estm0b: lcall LCD

poll6:  setb p2.3
        jb p2.3,poll6
        lcall dbnc
        lcall dbnc
        setb p2.3           
        jb p2.3,poll6
        sjmp eloop        

end1:   ajmp init

;_______________________________________________________
 
;SUBROUTINES
;_______________________________________________________
;data processing and conversion subroutine here

b16div:
        mov rb0,dvdhi
        mov rb1,dvdlo
        mov rb2,dvsr

        mov a,rb0
        jnz cont1
        mov a,rb1
        mov b,rb2
        div ab
        mov rb3,a
        mov rb5,b
        ljmp done5

cont1:  mov rb3,#00h
        mov rb4,#00h
                
loopdv: mov a,rb1               ;lobyt in a                        
        mov b,rb2               ;divisor in rb2
        div ab                  ;Qn in a, Rn in b
        add a,rb3               ;sigma Q in r3
        mov rb3,a
        jnc nxt
        inc rb4
        
nxt:    mov rb5,b               ;rem in rb5
        mov a,#0ffh             ;0ff in a
        mov b,rb2               ;r2 in b
        div ab                  ;Q2 in a,Rb2 in b
        mov rb7,b               ;rem in rb7
        mov b,rb0               ;hibyt in b
        mov rb6,a
        mov a,rb0
        jnz nx4
        ;cjne a,#00h,nx4
        ;mov a,rb5
        ;sjmp done5
done5:  ret                     ;Qlo in rb3,Qhi in rb4,R in rb5

nx4:    mov a,rb6
        mul ab                  ;a,b=(ab x Q)lo,hi
        add a,rb3               ;sigma Q in r3
        jnc nx2
        inc rb4     
nx2:    mov rb3,a
        mov a,rb4
        add a,b
        mov rb4,a

        inc rb7
        mov a,rb7
        mov b,rb0
        mul ab                  ;rem x hibyt
        add a,rb5
        jnc nx3
        inc b
nx3:    mov rb1,a
        mov rb0,b
        sjmp loopdv


 
hex2asc:mov a,h2bh
        jnz b16c
        mov a,h2bl
        mov b,h2bf

        mov rc0,b
        mov b,#064h             
        div ab                  ;hundreds in a, remainder in b
        mov rc1,b               ;rem in rc1

        add a,#030h
        mov fc0,a

        mov a,rc1
        mov b,#0ah
        div ab                  ;tens in a, units in b
        mov rc1,b               ;units in rc1
        add a,#030h
        mov fc1,a

        mov a,rc1
        add a,#030h
        mov fc2,a             

        mov fc3,#'.'
                   
        mov a,rc0               ;fraction in hex form in a
        mov b,#0ah
        div ab
        mov rc1,b               ;rem in rc1
        add a,#030h
        mov fc4,a
        mov a,rc1
        add a,#030h
        mov fc5,a
        ret

b16c:   mov dvdhi,h2bh
        mov dvdlo,h2bl
        mov dvsr,#064h
        lcall b16div
        mov rc0,rb3             ;quotient
        mov rc1,rb5             ;remainder

b16c0:  mov a,rc1
        cjne a,#063h,b16c1
        sjmp b16c2
b16c1:  jc b16c2
        mov a,rc1
        clr c
        subb a,rc0
        mov rc1,a
        inc rc0
        sjmp b16c0

b16c2:  mov a,rc1               ;tens and units in hex form in a
        mov b,#0ah
        div ab
        mov rc2,b               ;rem in rc1
        add a,#030h
        mov fc4,a
        mov a,rc2
        add a,#030h
        mov fc5,a

        mov a,rc0               ;hundreds in hex form in a
        mov b,#0ah
        div ab
        mov rc2,b               ;rem in rc1
        add a,#030h
        mov fc2,a
        mov a,rc2
        add a,#030h
        mov fc3,a

        mov fc0,#' '
        mov fc1,#'0'
        ret         

;_______________________________________________________
;LCD subtoutines here                             

INIT_LCD:
        setb EN
        clr RS
        mov DATA,#38h
        clr EN
        lcall WAIT_LCD

        setb EN
        clr RS
        mov DATA,#0ch
        clr EN
        lcall WAIT_LCD

        setb EN
        clr RS
        mov DATA,#06h
        clr EN
        lcall WAIT_LCD
        ret

CLEAR_LCD:
        setb EN
        clr RS
        mov DATA,#01h
        clr EN
        lcall WAIT_LCD
        ret
        
          
WAIT_LCD:
        setb EN ;Start LCD command
        clr RS ;It's a command
        setb RW ;It's a read command
        mov DATA,#0FFh ;Set all pins to FF initially
        mov A,DATA ;Read the return value
        jb ACC.7,WAIT_LCD ;If bit 7 high, LCD still busy
        clr EN ;Finish the command
        clr RW ;Turn off RW for future commands
        ret

LCD:    clr a
        movc a,@a+dptr
        inc dptr
        cjne a,#eot,cont
        ret

cont:   lcall DISPLAY
        sjmp lcd
                     
DISPLAY:             
        setb EN
        setb RS
        mov DATA,A
        clr EN

        lcall WAIT_LCD
        ret

;_______________________________________________________
;software delay subroutines here

dbnc:   mov rc6,#020h            ;debounce delay time 96 msec @ 4MHz
dlya:   mov rc7,#0fah            ;(2)
dlyb:   nop                      ;(1)
        nop                      ;(1)
        djnz rc7,dlyb            ;(2) -> 250  x 4  =1000  cycles
        djnz rc6,dlya            ;(2) -> 1002 x 32 =32064 cycles
        ret

dly:    mov rc6,#0dah            ;software 1 sec delay @ 4MHz
dlyc:   mov rc7,#0ffh            ;(2)
dlyd:   nop                      ;(1)
        nop                      ;(1)
        nop                      ;(1)
        nop                      ;(1)
        djnz rc7,dlyd            ;(2) -> 255  x 6  =1530  cycles
        djnz rc6,dlyc            ;(2) -> 
        ret
        
dly1:   lcall dbnc               ;software 0.45 sec delay
        lcall dbnc
        lcall dbnc
        lcall dbnc
        ret
;_______________________________________________________
;lookup tables for LCD messages
msg0a:  db 'A'
        db 'd'
        db 'j'
        db 'u'
        db 's'
        db 't'
        db ' '
        db 'N'
        db 'o'
        db 'z'
        db 'z'
        db 'l'
        db 'e'
        db ' '        
        db eot

msg0b:  db 'f'
        db 'o'
        db 'r'
        db ' '
        db 'p'
        db 'u'
        db 'l'
        db 's'
        db 'e'
        db 's'
        db '.'
        db '.'
        db '.'
        db ' '
        db eot

msg1a:  db ' '
        db ' '
        db 'M'
        db 'a'
        db 'g'
        db 'i'
        db 'c'
        db ' '
        db 'A'
        db 'n'
        db 'g'
        db 'l'
        db 'e'
        db ' '
        db ' '
        db ' '
        db eot

msg1b:  db ' '
        db ' '
        db ' '
        db ' '
        db 'T'
        db 'u'
        db 'r'
        db 'n'
        db 'i'
        db 'n'
        db 'g'
        db ' '
        db ' '
        db eot


msg2a:  db 'S'
        db 'e'
        db 't'
        db ' '
        db 'R'
        db 'e'
        db 'q'
        db 027h
        db 'd'
        db ' '
        db 'R'
        db 'o'
        db 't'
        db 'o'
        db 'r'
        db ' '
        db eot

msg2b:  db 'S'
        db 'p'
        db 'e'
        db 'e'
        db 'd'
        db ':'
        db ' '
        db ' '
        db ' '
        db ' '
        db eot

msg3a:  db 'A'
        db 'd'
        db 'j'
        db 'u'
        db 's'
        db 't'
        db ' '
        db 'V'
        db 'a'
        db 'l'
        db 'v'
        db 'e'
        db ' '        
        db 't'
        db 'i'
        db 'l'
        db eot

msg3b:  db 'F'
        db 'a'
        db 'c'
        db 't'
        db ' '
        db '>'
        db ' '
        db 'F'
        db 's'
        db 'e'
        db 't'
        db '.'
        db '.'
        db '.'
        db ' '
        db eot

msg4a:  db 'S'
        db 'e'
        db 't'
        db ' '
        db 'M'
        db 'a'
        db 'x'
        db ' '
        db 'S'
        db 'p'
        db 'i'
        db 'n'
        db ':'
        db ' '
        db eot


msg4b:  db 'A'
        db 'd'
        db 'j'
        db 'u'
        db 's'
        db 't'
        db ' '        
        db 'G'
        db 'a'
        db 'i'
        db 'n'
        db ' '
        db 't'
        db 'i'
        db 'l'
        db ' '
        db eot

msg4c:  db 'F'
        db 'a'
        db 'c'
        db 't'
        db ' '
        db '<'
        db ' '
        db 'F'
        db 's'
        db 'e'
        db 't'
        db '.'
        db '.'
        db '.'
        db ' '
        db eot


msg5a:  db 'S'
        db 'e'
        db 't'
        db ' '
        db 'M'
        db 'i'
        db 'n'
        db ' '
        db 'S'
        db 'p'
        db 'i'
        db 'n'
        db '.'
        db '.'
        db '.'
        db ' '
        db eot


msg6a:  db 'P'
        db 'r'
        db 'e'
        db 's'
        db 's'
        db ' '
        db 'F'
        db ' '
        db 't'
        db 'o'
        db ' '
        db 's'
        db 't'
        db 'a'
        db 'r'
        db 't'
        db eot

msg6b:  db 'M'
        db 'A'
        db 'T'
        db ' '
        db 'O'
        db 'p'
        db 'e'
        db 'r'
        db 'a'
        db 't'
        db 'i'
        db 'o'
        db 'n'
        db '.'
        db '.'
        db '.'
        db eot

msg7a:  db 'F'
        db ' '
        db 's'
        db 'e'
        db 't'
        db ':'
        db ' '
        db eot

msg7b:  db 'F'
        db ' '
        db 'a'
        db 'c'
        db 't'
        db ':'
        db ' '
        db eot

msg8a:  db 'P'
        db 'r'
        db 'e'
        db 's'
        db 's'
        db ' '
        db 'F'
        db ' '
        db 't'
        db 'o'
        db ' '
        db 'h'
        db 'a'
        db 'l'
        db 't'
        db ' '
        db eot

msg9a:  db 'I'
        db 'n'
        db 't'
        db 'e'
        db 'r'
        db 'r'
        db 'u'
        db 'p'
        db 't'
        db 'i'
        db 'n'
        db 'g'
        db ' '
        db eot

ermsg1: db 'I'
        db 'n'
        db 'c'
        db 'r'
        db 'e'
        db 'a'
        db 's'
        db 'e'
        db ' '
        db 'A'
        db 'i'
        db 'r'
        db 'f'
        db 'l'
        db 'o'
        db 'w'
        db eot

ermsg2: db 'D'
        db 'e'
        db 'c'
        db 'r'
        db 'e'
        db 'a'
        db 's'
        db 'e'
        db ' '
        db 'A'
        db 'i'
        db 'r'
        db 'f'
        db 'l'
        db 'o'
        db 'w'
        db eot

eastr1a:db ' '
        db ' '
        db ' '
        db 'D'
        db 'e'
        db 's'
        db 'i'
        db 'g'
        db 'n'
        db 'e'
        db 'd'
        db ' '
        db '&'
        db ' '
        db eot

eastr1b:db 'D'
        db 'e'
        db 'v'
        db 'e'
        db 'l'
        db 'o'
        db 'p'
        db 'e'
        db 'd'
        db ' '
        db 'b'
        db 'y'
        db '.'
        db '.'
        db '.'
        db ' '
        db eot

eastr2a:db 'K'
        db 'u'
        db 'n'
        db 'a'
        db 'l'
        db ' '
        db 'K'
        db 'a'
        db 'n'
        db 'd'
        db 'e'
        db 'k'
        db 'a'
        db 'r'
        db ' '
        db '&'
        db eot

eastr2b:db 'S'
        db 'u'
        db 'b'
        db 'o'
        db 'd'
        db 'h'
        db ' '
        db 'J'
        db 'o'
        db 's'
        db 'h'
        db 'i'
        db ','
        db 'V'
        db 'I'
        db 'T'        
        db eot

eastr3a:db 'U'
        db 'n'
        db 'd'
        db 'e'
        db 'r' 
        db ' '
        db 'g'
        db 'u'
        db 'i'
        db 'd'
        db 'a'
        db 'n'
        db 'c'
        db 'e'
        db ' '
        db ' '
        db eot

eastr3b:db 'o'
        db 'f'
        db ' '
        db 'D'
        db 'r'
        db '.'
        db ' '
        db 'G'
        db 'a'
        db 'n'
        db 'a'
        db 'p'
        db 'a'
        db 't'
        db 'h'
        db 'y'
        db eot

eastr4a:db 'a'
        db 't'
        db ' '
        db 'N'
        db 'M'
        db 'R'
        db ' '
        db 'D'
        db 'e'
        db 'p'
        db 't'
        db ','
        db ''
        db 'N'
        db 'C'
        db 'L'
        db eot

eastr4b:db '2'
        db '0'
        db '0'
        db '0'
        db ' '
        db '-'
        db ' '
        db '2'
        db '0'
        db '0'
        db '2'
        db ' '
        db ' '
        db ' '
        db ' '
        db ' '
        db eot


;_______________________________________________________
   
        end

