;
; Lab3_Interrupciones.asm
;
; Created: 20/02/2025 22:52:46
; Author : Mario Alejandro Betancourt Franco
;

; NOTA: Voy a tirar todo el progreso previo y empezar� el c�digo desde cero.
;       Quiero entender qu� estoy haciendo

// - DIRECTIVAS DEL ENSAMBLADOR -
// Iniciar el c�digo
.cseg		
.org	0x000
	RJMP	START

// Definir la tabla en la memoria FLASH
.org	0x100

START:
	