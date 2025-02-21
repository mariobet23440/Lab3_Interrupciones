;
; Contador en ATmega328P con Display de 7 Segmentos
; Muestra el mismo número en PORTC y PORTD
;

;==============================
; ENCABEZADO
;==============================
.include "M328PDEF.inc"

.cseg
.org    0x0000
    JMP     START
.org    PCI0addr
    JMP     ISR_PCINT0

;==============================
; DEFINICIONES
;==============================
.equ BTN_INC = PB1
.equ BTN_DEC = PB0

; Lookup Table para Display de 7 Segmentos (cátodo común)
.equ SEVENSD0 = 0b01110111
.equ SEVENSD1 = 0b01000001
.equ SEVENSD2 = 0b00111011
.equ SEVENSD3 = 0b01101011
.equ SEVENSD4 = 0b01001101
.equ SEVENSD5 = 0b01101110
.equ SEVENSD6 = 0b01111110
.equ SEVENSD7 = 0b01000011
.equ SEVENSD8 = 0b01111111
.equ SEVENSD9 = 0b01001111
.equ SEVENSDA = 0b01011111
.equ SEVENSDB = 0b01111100
.equ SEVENSDC = 0b00110110
.equ SEVENSDD = 0b01111001
.equ SEVENSDE = 0b00111110
.equ SEVENSDF = 0b00011110 

; Variables
.def COUNTER = R17
.def TEMP = R18

;==============================
; INICIALIZACIÓN
;==============================
START:
    ; Configurar la pila
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

SETUP:
    ; Configurar botones (entrada con pull-ups)
    LDI     R16, 0xFF
    OUT     PORTB, R16

    ; Configurar displays como salida
    LDI     R16, 0xFF
    OUT     DDRC, R16
    OUT     DDRD, R16

    ; Inicializar contador en 0
    LDI     COUNTER, 0x00
    CALL    UPDATE_DISPLAY

    ; Configuración de Interrupciones
    LDI     R16, (1 << PCIE0)    ; Habilitar interrupciones pin-change en PORTB
    STS     PCICR, R16

    LDI     R16, (1 << PCINT0) | (1 << PCINT1) ; Habilitar interrupciones en PCINT0 y PCINT1
    STS     PCMSK0, R16

    SEI     ; Habilitar interrupciones    

MAINLOOP:
    RJMP    MAINLOOP

;==============================
; RUTINA DE INTERRUPCIÓN PCINT0
;==============================
ISR_PCINT0:
    PUSH    R16
    PUSH    TEMP

    IN      TEMP, PINB        ; Leer estado de los botones

    SBRS    TEMP, BTN_INC     ; Si PB1 está en LOW, incrementar
    RCALL   INCREMENTO

    SBRS    TEMP, BTN_DEC     ; Si PB0 está en LOW, decrementar
    RCALL   DECREMENTO

    CALL    UPDATE_DISPLAY    ; Asegurar que se muestra el número correcto
	RETI

ISR_END:
    POP     TEMP
    POP     R16
    RETI

;==============================
; INCREMENTAR / DECREMENTAR
;==============================
INCREMENTO:
    INC     COUNTER
    ANDI    COUNTER, 0x0F    ; Asegurar que solo cuenta de 0 a 15
    RET

DECREMENTO:
    DEC     COUNTER
	ANDI    COUNTER, 0x0F    ; Asegurar que solo cuenta de 0 a 15
	RET



;==============================
; ACTUALIZAR DISPLAY
;==============================
UPDATE_DISPLAY:
    LDI     ZH, HIGH(TABLE)      ; Cargar dirección base de la tabla
    LDI     ZL, LOW(TABLE)
    ADD     ZL, COUNTER          ; Sumar el índice correcto
    LPM     R16, Z               ; Leer el valor del display
    OUT     PORTC, COUNTER       ; Mostrar el número en PORTC
    OUT     PORTD, R16           ; Mostrar en PORTD (display)
    RET

;==============================
; TABLA DE LOOKUP
;==============================
.org 0x100  ; Asegurar alineación correcta
TABLE:
    .dw SEVENSD0
    .dw SEVENSD1
    .dw SEVENSD2
    .dw SEVENSD3
    .dw SEVENSD4
    .dw SEVENSD5
    .dw SEVENSD6
    .dw SEVENSD7
    .dw SEVENSD8
    .dw SEVENSD9
    .dw SEVENSDA
    .dw SEVENSDB
    .dw SEVENSDC
    .dw SEVENSDD
    .dw SEVENSDE
    .dw SEVENSDF
