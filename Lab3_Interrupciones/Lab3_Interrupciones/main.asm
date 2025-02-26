;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;

; NOTA: De aquí en adelante trabajaré la entrega del POSTLAB

// --------------------------------------------------------------------
// | DIRECTIVAS DEL ENSAMBLADOR                                       |
// --------------------------------------------------------------------
; Iniciar el código
.cseg		
.org	0x0000
	RJMP	START

; Interrupciones PIN CHANGE
.org PCI0addr
	RJMP PCINT_ISR		; Vector de interrupción de Pin Change

; Interrupciones por overflow de TIMER0 (Modo Normal)
.org OVF0addr           ; Vector de interrupción para TIMER0_OVF
    RJMP TIMER0_ISR        ; Saltar a la rutina de interrupción

// --------------------------------------------------------------------
// | DEFINICIONES DE REGISTROS DE USO COMÚN Y CONSTANTES DE ASSEMBLER |
// --------------------------------------------------------------------

// Definiciones ()
.equ PRESCALER = (1<<CS02) | (1<<CS00)				; Prescaler de TIMER0 (En este caso debe ser de 1024)
.equ TIMER_START = 158								; Valor inicial del Timer0 (para un delay de 100 ms)

// Registros
.def	BTN_COUNTER = R17	; Contador de botones
.def	SCOUNTER1 = R18		; Contador de segundos
.def	SCOUNTER2 = R19		; Contador de decenas de segundos
.def	OUT_PORTC = R20		; Salida a PORTC
.def	OUT_PORTD = R21		; Salida a PORTD

// --------------------------------------------------------------------
// | TABLAS															  |
// --------------------------------------------------------------------

// Definir la tabla en la memoria FLASH (Números del 1 al 10 en display de 7 segmentos)
.org	0x100
TABLA:
    .db 0xE7, 0x21, 0xCB, 0x6B, 0x2D, 0x6E, 0xEE, 0x23, 0xEF, 0x2F

// --------------------------------------------------------------------
// | SETUP															  |
// --------------------------------------------------------------------

START:
	// - CONFIGURACIÓN DE LA PILA - 
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

	// - INICIALIZACIÓN DE TABLA -
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	LPM		OUT_PORTD, Z
	OUT		PORTD, OUT_PORTD
	
	// - CONFIGURACIÓN DE PINES -
	// Configurar los pines 0 y 1 de PORTB como entradas
	LDI		R16, (1 << PB0) | (1 << PB1)
	OUT		PORTB, R16

	// Configurar los pines 2 y 3 de PORTB como salidas
	LDI		R16, (1 << PB2) | (1 << PB3)
	OUT		DDRB, R16

	// Configurar los pines de PORTC como salidas
	LDI		R16, 0XFF
	OUT		DDRD, R16
	
	// Configurar los pines de PORTD como salidas
	LDI		R16, 0XFF
	OUT		DDRD, R16

	// - CONFIGURACIÓN DEL RELOJ DE SISTEMA -
	LDI		R16, (1 << CLKPCE)	// Establecer el bit para habilitar Prescalers
	STS		CLKPR, R16
	LDI		R16, 0X08			// Utilizar un prescaler de 16
	STS		CLKPR, R16

	// - HABILITACIÓN DE INTERRUPCIONES PC -
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16
	LDI		R16, (1 << PCINT0) | (1 << PCINT1)
	STS		PCMSK0, R16
	
	// - INICIALIZACIÓN DE TIMER0 -
	// No cambiamos los bits WGM dado que la configuración por default es el modo normal
	LDI     R16, PRESCALER				// Configurar un registro para setear las posiciones de CS01 y CS00
    OUT     TCCR0B, R16					// Setear prescaler del TIMER0 a 64 (CS01 = 1 y CS00 = 0)
    LDI     R16, TIMER_START			// Empezar el conteo con un valor de 158
    OUT     TCNT0, R16					// Cargar valor inicial en TCNT0

	// - HABILITACIÓN DE INTERRUPCIONES POR OVERFLOW EN TIMER0 -
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16

	// - HABILITACIÓN DE INTERRUPCIONES GLOBALES -
	SEI

	// - INICIALIZACIÓN DE REGISTROS DE PROPÓSITO GENERAL -
	CLR		BTN_COUNTER
	CLR		SCOUNTER1
	CLR		SCOUNTER2

// --------------------------------------------------------------------
// | MAINLOOP														  |
// --------------------------------------------------------------------

MAINLOOP:
	CALL	UPDATE_DISPLAY1
	CALL	UPDATE_DISPLAY2
	RJMP	MAINLOOP

// --------------------------------------------------------------------
// | RUTINAS NO DE INTERRUPCIÓN										  |
// --------------------------------------------------------------------

// Actualizar display 1 (Unidades)
UPDATE_DISPLAY1:
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	
	; Sumar el contador de segundos 1 a Z
    MOV		R16, SCOUNTER1
    ADD		ZL, R16
    CLR		R1				; Asegurar que no haya residuos en R1
    ADC		ZH, R1			; Sumar acarreo a ZH

    ; Extraer el valor de la dirección a la que Z está apuntando
    LPM		OUT_PORTD, Z
	OUT		PORTD, OUT_PORTD

	; Activar display 1 y desactivar display 2
	SBI		PORTB, PB2
	CBI		PORTB, PB3

	RET

// Actualizar display 2 (Unidades)
UPDATE_DISPLAY2:
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	
	; Sumar el contador de segundos 1 a Z
    MOV		R16, SCOUNTER2
    ADD		ZL, R16
    CLR		R1				; Asegurar que no haya residuos en R1
    ADC		ZH, R1			; Sumar acarreo a ZH

    ; Extraer el valor de la dirección a la que Z está apuntando
    LPM		OUT_PORTD, Z
	OUT		PORTD, OUT_PORTD

	; Activar display 2 y desactivar display 1
	CBI		PORTB, PB2
	SBI		PORTB, PB3

	RET

// --------------------------------------------------------------------
// | RUTINAS DE INTERRUPCIÓN POR CAMBIO EN PINES					  |															  |
// --------------------------------------------------------------------
PCINT_ISR:
	PUSH	R16  ; Guardar registro random
	IN      R16, SREG   ; Guardar el estado de los flags
	PUSH	R16  ; Guardar registro random

	// Si PB0 está presionado, incrementar
	SBIC	PINB, PB0
	INC		BTN_COUNTER

	// Si PB0 está presionado, decrementar
	SBIC	PINB, PB1
	DEC		BTN_COUNTER

	OUT		PORTC, BTN_COUNTER

	POP		R16
    OUT		SREG, R16
	POP		R16  ; Sacar registro random
	RETI

// --------------------------------------------------------------------
// | RUTINAS DE INTERRUPCIÓN CON TIMER0								  |
// --------------------------------------------------------------------
// Cuando ocurre un overflow en TIMER0 solo se incrementarán los contadores
TIMER0_ISR: 
	PUSH	R16  ; Guardar registro random
	IN      R16, SREG   ; Guardar el estado de los flags
	PUSH	R16  ; Guardar registro random
	
	// Incrementar contador 1
	INC		SCOUNTER1
	CPI		SCOUNTER1, 10
	BRLO	END_ISR			; Si el contador de unidades no supera 10, no hacer nada más

	// Si SCOUNTER1 >= 10 reiniciar contador e incrementar contador de decenas
	LDI		SCOUNTER1, 0
	INC		SCOUNTER2

	// Si el contador de decenas supera a 10, reiniciar su valor
	CPI		SCOUNTER2, 10
	BRLO	END_ISR			; Si el contador de unidades no supera 10, no hacer nada más
	LDI		SCOUNTER2, 0
	
	POP		R16
    OUT		SREG, R16
	POP		R16  ; Sacar registro random
	RETI



END_ISR:
	POP		R16
    OUT		SREG, R16
	POP		R16  ; Sacar registro random
	RETI
	