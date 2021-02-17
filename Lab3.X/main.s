    ;Archivo:	    main.s
    ;Dispositivo:   PIC16F887
    ;Autor:	    Margareth Vela
    ;Compilador:    pic-as(v2.31), MPLABX V5.45
    ;
    ;Programa:	    Botones y Timer0
    ;Hardware:	    LEDs en puerto C y E, display 7 seg en puerto D  
    ;		    & push buttons en puerto A
    ;Creado: 14 feb, 2021
    ;Última modificación: 16 feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscilador interno sin salidas
  CONFIG  WDTE = OFF            ; WDT disabled (reinicio dispositivo del pic)
  CONFIG  PWRTE = ON            ; PWRT enabled (espera de 72ms al iniciar)
  CONFIG  MCLRE = OFF           ; El pin de MCLR se utiliza como I/O
  CONFIG  CP = OFF              ; Sin protección de código
  CONFIG  CPD = OFF             ; Sin protección de datos
  CONFIG  BOREN = OFF           ; Sin reinicio cuándo el voltaje de alimentacion baja de 4v
  CONFIG  IESO = OFF            ; Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           ; Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = ON              ; Programacion en bajo voltaje permitida

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Protección de autoescritura por el programa desactivada
  CONFIG  WRT = OFF             ; Reinicio abajo de 4V, (BOR21V=2.1V)

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr ;Share memory
    contador : DS 1 ;1 byte
        
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
PSECT resetvector, class=code, delta=2, abs
ORG 0x0000   ;Posición 0000h para el reset
resetvector:
    goto setup

;-------------------------------------------------------------------------------
; Código Principal 
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x000A ;Posición para el código
 
tabla:
    andlw   0x0F	; Se utilizan solo los 4 bits menos signficativos 
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
    call config_reloj	; Configuración del reloj
    call config_io	; Configuración de I/O
    call config_tmr0	; Configuración inicial del tmr0

loop:
    btfsc   PORTA, 0 ; Se presiona el push para incrementar
    call    inc_push 
    btfsc   PORTA, 1 ; Se presiona el push para decrementar
    call    dec_push
    btfss   T0IF
    goto    $-5	     ; Revisa si algún push está siendo presionado
    call    reiniciar_tmr0
    incf    PORTC    ; Se incrementa el contador del tmr0
    
    btfsc   PORTE, 0 ;Si la alarma está activa, se apaga
    bcf	    PORTE, 0
    call    alarma   
    goto    loop
    
;-------------------------------------------------------------------------------
; Sub rutinas de configuración
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL ;Banco 11
    clrf    ANSEL ;Pines digitales
    clrf    ANSELH
    
    banksel TRISA ;Banco 01
    movlw   0xF0  ;Se utilizan solo los 4 bits menos significativos como salida
    movwf   TRISC ;Salida del timer 0
    movlw   0xF0  ;Se utilizan solo los 4 bits menos significativos como salida
    clrf    TRISD ;Display 7seg
    clrf    TRISE ;Led de alarma
    
    banksel PORTA ;Banco 00
    clrf    PORTC ;Comenzar contador binario en 0
    clrf    PORTD ;Comenzar contador hexadecimal en 0
    clrf    PORTE ;La alarma está apagada
    clrf    contador ;Comenzar el contador del display en 0
    return

config_reloj:
    banksel OSCCON
    bcf	    IRCF2  ;IRCF = 010 frecuencia=250kHz
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;Reloj interno
    return
    
;-------------------------------------------------------------------------------
; Sub rutinas para TMR0
;-------------------------------------------------------------------------------
config_tmr0:
    banksel TRISA
    bcf	    T0CS    ;Reloj intero
    bcf	    PSA	    ;Prescaler al TMR0
    bsf	    PS2
    bsf	    PS1
    bcf	    PS0	    ;PS = 110  prescaler = 1:128 
    banksel PORTA
    call reiniciar_tmr0
    return
  
reiniciar_tmr0:
    movlw   12	    ;Número inicial del tmr0
    movwf   TMR0    
    bcf	    T0IF
    return

;-------------------------------------------------------------------------------
; Sub rutinas para display
;-------------------------------------------------------------------------------
inc_push:
    btfsc   PORTA, 0 ;Antirebote
    goto    $-1
    incf    contador ;Se incrementa la variable de contador
    movwf   contador, 0
    call    tabla
    movwf   PORTD;Se incrementa el display
    return
    
dec_push:
    btfsc   PORTA, 1 ;Antirebote
    goto    $-1
    decf    contador ;Se decrementa la variable de contador
    movwf   contador, 0 
    call    tabla 
    movwf   PORTD;Se decrementa el display 
    return    
;-------------------------------------------------------------------------------
; Sub rutinas para alarma
;-------------------------------------------------------------------------------
alarma:
    bcf	    STATUS, 2  ;Se apaga la bandera de Zero 
    movwf   contador, 0	;Se mueve el valor de contador display al registro w
    subwf   PORTC, 0  ;Se resta con el valor del contador tmr0
    btfsc   STATUS, 2 ;Revisión de la bandera de Zero
    bsf	    PORTE, 0  ;Si está encendida la bandera, se enciende la alarma
    btfsc   STATUS, 2 ;Revisión de la bandera de Zero
    clrf    PORTC  ;Si está encendida la bandera, se reinicia la salida del tmr0
    btfsc   STATUS, 2  ;Revisión de la bandera de Zero
    call    reiniciar_tmr0 ;Si está encendida la bandera, se reinicio el tmr0
    return
       
end