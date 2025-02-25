;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;

; NOTA: Voy a tirar todo el progreso previo y empezaré el código desde cero.
;       Quiero entender qué estoy haciendo

// - DIRECTIVAS DEL ENSAMBLADOR -
// Iniciar el código
.cseg		
.org	0x000
	RJMP	START

// Interrupciones PIN CHANGE
.org PCI0addr
	RJMP PCINT_ISR		; Vector de interrupción de Pin Change

// Registros
.def	COUNTER = R17
.def	OUT_PORTD = R18

// Definir la tabla en la memoria FLASH (Números del 1 al 10 en display de 7 segmentos)
.org	0x100
TABLA:
    .db 0xE7, 0x21, 0xCB, 0x6B, 0x2D, 0x6E, 0xEE, 0x23, 0xEF, 0x2F

// Setup
START:
	// Configuración de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

	// Inicializar contador
	CLR		COUNTER

	// Cargar en Z la dirección de la tabla
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	LPM		OUT_PORTD, Z
	OUT		PORTD, OUT_PORTD

	// Configurar los pines de PORTB como entradas
	LDI		R16, (1 << PB0) | (1 << PB1)
	OUT		PORTB, R16

	// Configurar los pines de PORTD como salidas
	LDI		R16, 0XFF
	OUT		DDRD, R16

	// Configuración de reloj de sistema
	LDI		R16, (1 << CLKPCE)	// Establecer el bit para habilitar Prescalers
	STS		CLKPR, R16
	LDI		R16, 0X08			// Utilizar un prescaler de 16
	STS		CLKPR, R16

	; Habilitar interrupciones de cambio de pin en PCINT0 y PCINT1
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
	STS		PCMSK0, R16

	; Habilitar interrupciones globales
	SEI


MAINLOOP:
	RJMP	MAINLOOP

// RUTINAS DE INTERRUPCIÓN -----------------------------------------------------

PCINT_ISR:
	PUSH	R16  ; Guardar registro random
	IN      R16, SREG   ; Guardar el estado de los flags
	PUSH	R16  ; Guardar registro random

	// Si PB0 está presionado, incrementar
	SBIC	PINB, PB0
	RJMP	INCREMENT

	// Si PB0 está presionado, decrementar
	SBIC	PINB, PB1
	RJMP	DECREMENT

	POP R16
    OUT SREG, R16
	POP		R16  ; Sacar registro random
	RETI

// Incrementar el contador hasta máximo 10 y reiniciar
INCREMENT:
	INC		COUNTER
	CPI		COUNTER, 10
	BRLO	UPDATE_DISPLAY
	LDI		COUNTER, 0
	RJMP	UPDATE_DISPLAY


// Incrementar el contador hasta mínimo 0 y reiniciar a 9
DECREMENT:
	DEC		COUNTER
	BRPL	UPDATE_DISPLAY
	LDI		COUNTER, 9
	RJMP	UPDATE_DISPLAY

UPDATE_DISPLAY:
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	
	
	; Multiplicar COUNTER por 2 y sumarlo a Z
    MOV		R16, COUNTER
    ADD		ZL, R16
    CLR		R1				; Asegurar que no haya residuos en R1
    ADC		ZH, R1			; Sumar acarreo a ZH

    ; Extraer el valor de la dirección a la que Z está apuntando
    LPM		OUT_PORTD, Z
	OUT		PORTD, OUT_PORTD

	POP		R16
    OUT		SREG, R16
	POP		R16  ; Sacar registro random
	RETI

