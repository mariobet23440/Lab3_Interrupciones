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

// Registros
.def	COUNTER = R17
.def	OUT_PORTD = R18

// Definir la tabla en la memoria FLASH (Números del 1 al 10 en display de 7 segmentos)
.org	0x100
TABLA:
    .db 0x77, 0x41, 0x3B, 0x6B, 0x4D, 0x6E, 0x7E, 0x43, 0x7F, 0x4F

// Setup
START:
	// Configuración de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

	// Cargar en Z la dirección de la tabla
	LDI		ZL, LOW(TABLA*2)	// Multiplicamos por dos porque usamos la FLASH
	LDI		ZH, HIGH(TABLA*2)

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


	// Inicializar contador
	CLR		COUNTER


MAINLOOP:
	// Guardar la dirección en Z e incrementar si PB0 está presionado
	SBIC	PINB, PB0
	LPM		OUT_PORTD, Z+
	SBIC	PINB, PB0
	INC		COUNTER

	// Sacar en PORTD
	OUT		PORTD, OUT_PORTD

	// Incrementar el contador
	CPI		COUNTER, 10		// Si el contador es menor a 10 regresar a MAINLOOP
	BRNE	MAINLOOP

	// Reiniciar puntero y contador
	LDI		ZL, LOW(TABLA * 2)
	LDI		ZH, HIGH(TABLA * 2)
	LDI		COUNTER, 0

	RJMP	MAINLOOP

