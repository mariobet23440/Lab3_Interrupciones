;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;


; Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000
JMP     START
.org    PCI0addr
JMP     ISR_PCINT0



; Definiciones
.equ BTN_INC = PB1
.equ BTN_DEC = PB0

// Lookup Table para Display de 7 Segmentos
.equ SEVENSD0 =	0b0111_0111
.equ SEVENSD1 =	0b0100_0001
.equ SEVENSD2 =	0b0011_1011
.equ SEVENSD3 =	0b0110_1011
.equ SEVENSD4 =	0b0100_1101
.equ SEVENSD5 =	0b0110_1110
.equ SEVENSD6 =	0b0111_1110
.equ SEVENSD7 =	0b0100_0011
.equ SEVENSD8 =	0b0111_1111
.equ SEVENSD9 =	0b0100_1111
.equ SEVENSDA =	0b0101_1111
.equ SEVENSDB =	0b0111_1100
.equ SEVENSDC =	0b0011_0110
.equ SEVENSDD =	0b0111_1001
.equ SEVENSDE =	0b0011_1110
.equ SEVENSDF =	0b0001_1110 

; Variables (Estos registros NO se tocan en MAINLOOP)
.def COUNTER = R17

START:

; Configurar la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
    ; Activación de pines de entrada en el puerto B
    LDI     R16, 0xFF            ; Habilitar pull-ups internos
    OUT     PORTB, R16

    ; Activación de pines de salida en el puerto C
    LDI     R16, 0xFF
    OUT     DDRC, R16
    LDI     R16, 0x00
    OUT     PORTC, R16
    
    ; Configuración de Interrupciones
    LDI     R16, (1 << PCIE0)    ; Habilitar interrupciones pin-change en PORTB
    STS     PCICR, R16

    LDI     R16, (1 << PCINT0) | (1 << PCINT1) ; Habilitar interrupciones en PCINT0 y PCINT1
    STS     PCMSK0, R16

    SEI     ; Habilitar Interrupciones    

MAINLOOP:
    OUT     PORTC, COUNTER
    RJMP    MAINLOOP

; Rutina de Interrupción PCINT0
ISR_PCINT0:
    PUSH    R16              ; Guardar el contenido de R16 en la pila
    IN      R16, PINB        ; Leer el estado del puerto B

    SBRS    R16, BTN_INC     ; Si PB1 está en LOW, incrementar
    RCALL   INCREMENTO

    SBRS    R16, BTN_DEC     ; Si PB0 está en LOW, decrementar
    RCALL   DECREMENTO

ISR_END:
    POP     R16              ; Recuperar R16 antes de salir
    RETI                     ; Salir de la interrupción

; Incrementar el contador
INCREMENTO:
    INC     COUNTER
    ANDI    COUNTER, 0x0F   ; Aplicar una máscara para truncar el contador a 4 bits
    RET                      ; Retornar a ISR_PCINT0

; Decrementar el contador
DECREMENTO:
    DEC     COUNTER
    ANDI    COUNTER, 0x0F   ; Aplicar una máscara para truncar el contador a 4 bits
    RET                      ; Retornar a ISR_PCINT0


/*
; Definiciones
.include "m328Pdef.inc"

.equ BTN_INC = PB0       ; Botón de incremento
.equ BTN_DEC = PB1       ; Botón de decremento
.equ DISP = PORTD        ; Puerto del display

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

; ==========================
; SECCIÓN DE CÓDIGO PRINCIPAL
; ==========================

.cseg
.org 0x00
    rjmp RESET

RESET:
    ldi r16, 0xFF
    out DDRD, r16         ; Configura PORTD como salida (para el display)
    
    ldi r16, 0x03
    out PORTB, r16        ; Activa pull-ups en PB0 y PB1

    clr r17               ; Inicializa contador en 0
    rjmp MAIN_LOOP

MAIN_LOOP:
    sbic PINB, BTN_INC    ; Si el botón de incremento está presionado
    rjmp INC_COUNT

    sbic PINB, BTN_DEC    ; Si el botón de decremento está presionado
    rjmp DEC_COUNT

    rjmp MAIN_LOOP        ; Repite el bucle

INC_COUNT:
    cpi r17, 9            ; Si ya es 9, no incrementa
    breq MAIN_LOOP
    inc r17               ; Incrementa el contador
    rjmp UPDATE_DISPLAY

DEC_COUNT:
    cpi r17, 0            ; Si ya es 0, no decrementa
    breq MAIN_LOOP
    dec r17               ; Decrementa el contador

UPDATE_DISPLAY:
    ldi ZH, high(TABLE * 2)  ; La tabla está en memoria de programa (se accede en palabras)
    ldi ZL, low(TABLE * 2)
    add ZL, r17               ; Apunta al índice correcto
    lpm r16, Z                ; Carga el valor del display
    out DISP, r16             ; Muestra el número
    rjmp MAIN_LOOP

; ==========================
; SECCIÓN DE TABLA EN MEMORIA DE PROGRAMA
; ==========================

.org 0x100  ; Dirección alineada correctamente en memoria de programa
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

*/