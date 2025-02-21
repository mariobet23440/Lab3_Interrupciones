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

// Configurar la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
	// Activación de pines de entrada en el puerto B
    LDI     R16, 0x00
    OUT     DDRB, R16
    LDI     R16, 0xFF	// Desactivar salidas inicialmente
    OUT     PORTB, R16	// Por alguna razón no funciona si usamos algunos bits de PORTC como entradas y otros como salidas
	// Sin embargo, usar el puerto B solo para recibir entradas fue una solución rápida que terminó funcionando.
	
	// Activación de pines de salida en el puerto C
    LDI     R16, 0xFF	// Primeros cuatro bits como salidas y los primeros dos bits como entradas
    OUT     DDRC, R16
    LDI     R16, 0xF0	// Activar Pull-ups en entradas y desactivar salidas inicialmente
    OUT     PORTC, R16

	// Activación de pines de salida en el puerto D
    LDI     R16, 0xFF	// Primeros cuatro bits como salidas y los primeros dos bits como entradas
    OUT     DDRD, R16
    LDI     R16, 0x00	// Desactivar salidas inicialmente
    OUT     PORTD, R16

	// Configurar Prescaler Principal
	LDI		R16, (1 << CLKPCE)
	STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0x04			// CAMBIAR A 0X04
    STS     CLKPR, R16          // Configurar Prescaler a 1 MHz

	// Inicializar timer0
    CALL    INIT_TMR0

	// Inicializar GPRs
	CLR		COUNTER_TEMP
	CLR		COUNTER_SECONDS
	CLR		COUNTER_BUTTON
	CLR		SEVENSD_OUT
	CLR		COUNTER_COUNTER
