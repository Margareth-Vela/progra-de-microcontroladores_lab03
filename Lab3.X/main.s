    ;Archivo:	    main.s
    ;Dispositivo:   PIC16F887
    ;Autor:	    Margareth Vela
    ;Compilador:    pic-as(v2.31), MPLABX V5.40
    ;
    ;Programa:	    Botones y Timer0
    ;Hardware:	    LEDs en puerto C y E, display 7 seg en puerto D  
    ;		    & push buttons en puerto A
    ;Creado: 14 feb, 2021
    ;Última modificación: 16 feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr ;share memory
    contador : DS 1 ;1 byte
        
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
PSECT resetvector, class=code, delta=2, abs
ORG 0x0000
resetvector:
    goto setup

;-------------------------------------------------------------------------------
; Código Principal 
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x000A
 
tabla:
    andlw   0x0F
    addwf   PCL		; PC = offset + PCL 
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01101111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;b
    retlw   00111001B	;C
    retlw   01011110B	;d
    retlw   01111001B	;E
    retlw   01110001B	;F
                                           
setup:
    call config_reloj
    call config_io
    call config_tmr0

loop:
    btfsc   PORTA, 0 ;se presiona el push
    call    inc_push 
    btfsc   PORTA, 1 ;se presiona el push
    call    dec_push
    btfss   T0IF
    goto    $-5
    call    reiniciar_tmr0
    incf    PORTC
    
    btfsc   PORTE, 0
    bcf	    PORTE, 0
    call    alarma
    goto    loop
    
;-------------------------------------------------------------------------------
; Sub rutinas de configuración
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL ;banco 11
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA ;banco 01
    movlw   0xF0
    movwf   TRISC ;salida del timer 0
    movlw   0xF0
    clrf    TRISD ;display 7seg
    clrf    TRISE
    
    banksel PORTA ;banco 00
    clrf    PORTC ;comenzar contador binario en 0
    clrf    PORTD ;comenzar contador hexadecimal en 0
    clrf    PORTE   
    clrf    contador
    return

config_reloj:
    banksel OSCCON
    bcf	    IRCF2  ;IRCF = 010 250kHz
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;reloj interno
    return
    
;-------------------------------------------------------------------------------
; Sub rutinas para TMR0
;-------------------------------------------------------------------------------
config_tmr0:
    banksel TRISA
    bcf	    T0CS    ;reloj intero
    bcf	    PSA	    ;prescaler al TMR0
    bsf	    PS2
    bsf	    PS1
    bcf	    PS0	    ;PS = 110  1:128 
    banksel PORTA
    call reiniciar_tmr0
    return
  
reiniciar_tmr0:
    movlw   12
    movwf   TMR0
    bcf	    T0IF
    return

;-------------------------------------------------------------------------------
; Sub rutinas para display
;-------------------------------------------------------------------------------
inc_push:
    btfsc   PORTA, 0 ;antirebote
    goto    $-1
    incf    contador
    movwf   contador, 0
    call    tabla
    movwf   PORTD;se incrementa el display
    return
    
dec_push:
    btfsc   PORTA, 1 ;antirebote
    goto    $-1
    decf    contador
    movwf   contador, 0
    call    tabla 
    movwf   PORTD;se decrementa el display 
    return    
;-------------------------------------------------------------------------------
; Sub rutinas para alarma
;-------------------------------------------------------------------------------
alarma:
    bcf	    STATUS, 2
    movwf   contador, 0
    subwf   PORTC, 0
    btfsc   STATUS, 2
    bsf	    PORTE, 0
    btfsc   STATUS, 2
    clrf    PORTC
    btfsc   STATUS, 2
    call    reiniciar_tmr0
    return
       
end
 
    


