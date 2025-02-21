;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;

// Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000

// Definiciones
.equ BTN_INC = PB1
.equ BTN_DEC = PB0

// Variables (Estos registros NO se tocan en MAINLOOP)
.def COUNTER = R16

// Configurar la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
    // Activación de pines de entrada en el puerto B
    LDI     R16, 0x00
    OUT     DDRB, R16
    LDI     R16, 0xFF            ; Habilitar pull-ups internos
    OUT     PORTB, R16

    // Activación de pines de salida en el puerto C
    LDI     R16, 0xFF
    OUT     DDRC, R16
    LDI     R16, 0x00
    OUT     PORTC, R16
    
    // Configuración de Interrupciones
    LDI     R16, (1 << PCIE0)    ; Habilitar interrupciones pin-change en PORTB
    STS     PCICR, R16

    LDI     R16, (1 << PCINT0) | (1 << PCINT1) ; Habilitar interrupciones en PCINT0 y PCINT1
    STS     PCMSK0, R16

    SEI     ; Habilitar Interrupciones    

MAINLOOP:
    OUT     PORTC, COUNTER
    RJMP    MAINLOOP

// Rutinas de Interrupción
ISR_PCINT0:
    SBI     PCIFR, PCIF0  ; Limpiar el flag de interrupción
    IN      R17, PINB
    
    SBIS    PINB, BTN_INC  ; Si BTN_INC está en 0 (presionado), salta a INCREMENTO
    RJMP    INCREMENTO
    
    SBIS    PINB, BTN_DEC  ; Si BTN_DEC está en 0 (presionado), salta a DECREMENTO
    RJMP    DECREMENTO

    RETI

INCREMENTO:
    INC     COUNTER
    ANDI    COUNTER, 0x0F   ; Aplicar una máscara para truncar el contador a 4 bits
    RETI

DECREMENTO:
    DEC     COUNTER
    ANDI    COUNTER, 0x0F   ; Aplicar una máscara para truncar el contador a 4 bits
    RETI
