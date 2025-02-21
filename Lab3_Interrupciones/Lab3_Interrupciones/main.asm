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
