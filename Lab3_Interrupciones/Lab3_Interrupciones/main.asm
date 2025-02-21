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
.equ PRESCALER = (1<<CS02) | (1<<CS00)				; Prescaler de TIMER0 (En este caso debe ser de 1024)
.equ TIMER_START = 158								; Valor inicial del Timer0 (100 ms)
.def COUNTER_BUTTON = R20							; Contador de botones
.def COUNTER_TEMP = R22								; Contador temporal (Para contador de segundos)
.def COUNTER_SECONDS = R23
.def SEVENSD_OUT = R21								; Registro temporal
.def COUNTER_COUNTER = R24							; Contador adicional

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
    LDI     R16, 0xFF			// Habilitar pull-ups internos
    OUT     PORTB, R16

	// Activación de pines de salida en el puerto C
    LDI     R16, 0xFF
    OUT     DDRC, R16
    LDI     R16, 0x00
    OUT     PORTC, R16
	
	// Configuración de Interrupciones
	LDI		R16, (1 << PCIE0)	// Habilitar interrupciones pin-change en PORTB
	STS		PCICR, R16

	LDI		R16, (1 << PCINT0) | (1 << PCINT1) // Habilitar interrupciones en PCINT0 y PCINT1
	STS		PCMSK0, R16

	SEI		// Habilitar Interrupciones	

MAINLOOP:
	OUT		PORTC, COUNTER
	RJMP	MAINLOOP


// Rutinas de Interrupción
ISR_PCINT0:
	IN		R17, PINB
	SBRS	R17, BTN_INC
	RJMP	INCREMENTO
	
	SBRS	R17, BTN_DEC
	RJMP	DECREMENTO
	
	RETI
	
INCREMENTO:
	INC		COUNTER
	ANDI	COUNTER, 0X0F	// Aplicar una máscara para truncar el contador a 4 bits 
	RETI

DECREMENTO:
	DEC		COUNTER
	ANDI	COUNTER, 0X0F	// Aplicar una máscara para truncar el contador a 4 bits
	RETI
		
	