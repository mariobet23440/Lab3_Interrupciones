;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;

/*
CONFIGUACI?N DE TIMER0
Estamos usando TIMER0 como un temporizador en modo NORMAL. 
t_delay = 1 s
f_clk = 1 MHz
n = 8 (Recordemos que es el n?mero de bits del registro del *contador*)

Prescaler >= (t_delay * f_clk) / 2**n = (0.1*10E6)(2POW(8)) = 390
Prescaler >= 390
Escogemos un prescaler de 1024

Calculamos el tiempo m?ximo que puede contar TIMER0
Tmax = (2**n * Prescaler) / f_clk = (2**8 * 1024) / 10E6 = 0.262s = 262 ms 

Determinamos el valor inicial de TIMER0
TCNT0 = 256 - (f_clk * t_deseado) / Prescaler = 256 - (10E6 * 0.100) / 1024 = 158

Con este c?lculo el contador alcanza 100 ms directamente por cada conteo realizado.
*/

; Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000
JMP     START
.org    PCI0addr
JMP     ISR_PCINT0
.org	OVF0addr
JMP		ISR_TIMER0

; Definiciones
.equ BTN_INC = PB1
.equ BTN_DEC = PB0

// Definiciones
.equ PRESCALER = (1<<CS02) | (1<<CS00)				; Prescaler de TIMER0 (En este caso debe ser de 1024)
.equ TIMER_START = 158								; Valor inicial del Timer0 (100 ms)

; Variables (Estos registros NO se tocan en MAINLOOP)
.def COUNTER = R17
.def TIME_COUNTER = R18
.def SEVENSD_OUT = R19

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

    ; Activación de pines de salida en los puertos C y D
    LDI     R16, 0xFF
    OUT     DDRC, R16
	OUT     DDRD, R16
    LDI     R16, 0x00
    OUT     PORTC, R16
	OUT     PORTD, R16
    
    ; Configuración de Interrupciones PC en PORTB
    LDI     R16, (1 << PCIE0)    ; Habilitar interrupciones pin-change en PORTB
    STS     PCICR, R16

    LDI     R16, (1 << PCINT0) | (1 << PCINT1) ; Habilitar interrupciones en PCINT0 y PCINT1
    STS     PCMSK0, R16

	// Configurar Prescaler Principal
	LDI		R16, (1 << CLKPCE)
	STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0x04			// CAMBIAR A 0X04
    STS     CLKPR, R16          // Configurar Prescaler a 1 Mhz

	CALL	INIT_TMR0

    SEI     ; Habilitar Interrupciones    

// ---------------------------
// Rutinas no de interrupción
// ---------------------------
MAINLOOP:
    OUT     PORTC, COUNTER
	CALL	SEVEN_SEGMENT_DISPLAY
	OUT     PORTD, SEVENSD_OUT
    RJMP    MAINLOOP

// Inicializar Timer0
INIT_TMR0:
    LDI     R16, PRESCALER				// Configurar un registro para setear las posiciones de CS01 y CS00
    OUT     TCCR0B, R16					// Setear prescaler del TIMER0 a 64 (CS01 = 1 y CS00 = 0)
    LDI     R16, TIMER_START			// Empezar el conteo con un valor de 100
    OUT     TCNT0, R16					// Cargar valor inicial en TCNT0

    LDI     R16, (1 << TOIE0) ; Habilitar interrupciones en PCINT0 y PCINT1
    STS     TIMSK0, R16
	
	RET

// Display de 7 segmentos
/*
En esta parte revisamos el valor del contador del puerto haciendo un compare con el valor que se va a mostrar en 
el display de 7 segmentos. Si el compare activa la bandera Z el programa regresará a MAINLOOP
*/
SEVEN_SEGMENT_DISPLAY:
	CLR		SEVENSD_OUT	
	
	// Revisar si el contador es 0	
	LDI		SEVENSD_OUT, SEVENSD0
	CPI		TIME_COUNTER, 0
	BREQ	END

	// Revisar si el contador es 1	
	LDI		SEVENSD_OUT, SEVENSD1
	CPI		TIME_COUNTER, 1
	BREQ	END

	// Revisar si el contador es 2	
	LDI		SEVENSD_OUT, SEVENSD2
	CPI		TIME_COUNTER, 2
	BREQ	END

	// Revisar si el contador es 3	
	LDI		SEVENSD_OUT, SEVENSD3
	CPI		TIME_COUNTER, 3
	BREQ	END

	// Revisar si el contador es 4
	LDI		SEVENSD_OUT, SEVENSD4
	CPI		TIME_COUNTER, 4
	BREQ	END

	// Revisar si el contador es 5	
	LDI		SEVENSD_OUT, SEVENSD5
	CPI		TIME_COUNTER, 5
	BREQ	END

	// Revisar si el contador es 6	
	LDI		SEVENSD_OUT, SEVENSD6
	CPI		TIME_COUNTER, 6
	BREQ	END

	// Revisar si el contador es 0	
	LDI		SEVENSD_OUT, SEVENSD7
	CPI		TIME_COUNTER, 7
	BREQ	END

	// Revisar si el contador es 8	
	LDI		SEVENSD_OUT, SEVENSD8
	CPI		TIME_COUNTER, 8
	BREQ	END

	// Revisar si el contador es 9	
	LDI		SEVENSD_OUT, SEVENSD9
	CPI		TIME_COUNTER, 9
	BREQ	END

	// Revisar si el contador es A	
	LDI		SEVENSD_OUT, SEVENSDA
	CPI		TIME_COUNTER, 10
	BREQ	END

	// Revisar si el contador es B	
	LDI		SEVENSD_OUT, SEVENSDB
	CPI		TIME_COUNTER, 11
	BREQ	END

	// Revisar si el contador es 12	
	LDI		SEVENSD_OUT, SEVENSDC
	CPI		TIME_COUNTER, 12
	BREQ	END

	// Revisar si el contador es 13	
	LDI		SEVENSD_OUT, SEVENSDD
	CPI		TIME_COUNTER, 13
	BREQ	END

	// Revisar si el contador es 14	
	LDI		SEVENSD_OUT, SEVENSDE
	CPI		TIME_COUNTER, 14
	BREQ	END

	// Revisar si el contador es 15	
	LDI		SEVENSD_OUT, SEVENSDF
	CPI		TIME_COUNTER, 15
	BREQ	END

	RET


END:
	RET

UPDATE_SSD:
	CALL	SEVEN_SEGMENT_DISPLAY
// ---------------------------
// Rutinas de interrupción
// ---------------------------
; Rutina de Interrupción PCINT0
ISR_PCINT0:
    PUSH    R16              ; Guardar el contenido de R16 en la pila
    IN      R16, PINB        ; Leer el estado del puerto B

    SBRS    R16, BTN_INC     ; Si PB1 está en LOW, incrementar
    INC		COUNTER

    SBRS    R16, BTN_DEC     ; Si PB0 está en LOW, decrementar
    DEC		COUNTER

	ANDI	COUNTER, 0X0F
	CALL	ISR_END

; Rutina de Interrupción TIMER0
ISR_TIMER0:
    IN		R16, SREG
	PUSH    R16              ; Guardar el contenido de R16 en la pila
    IN      R16, PINB        ; Leer el estado del puerto B

    SBRS    R16, BTN_INC     ; Si PB1 está en LOW, incrementar
    INC     TIME_COUNTER

    SBRS    R16, BTN_DEC     ; Si PB0 está en LOW, decrementar
    DEC		TIME_COUNTER

	ANDI	TIME_COUNTER, 0X0F
	CALL	ISR_END

ISR_END:
    POP     R16              ; Recuperar R16 antes de salir
    OUT		SREG, R16
	RETI                     ; Salir de la interrupción


//