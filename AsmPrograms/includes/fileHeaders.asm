#ifndef FILEHEADERS

#define FILEHEADERS


;---------------------------------------------------------------
; These switches control the compilation process.
;	ONLY ONE should be uncommented at a time
;
;---------------------------------------------------------------
; These switches generate cartidge files
;
; uncomment if a VICE compatible cartridge file is
;	to be generated
;#define	EXROMVICECART
;
; uncomment if a standard cartridge file is to be
;	generated
;#define	EXROMCART
;
;---------------------------------------------------------------
; This switch generates a binary file intended to be loaded
;	at $0801 and with that load address prepended
;
;#define	ISDISKFILE


I2C_CMD_REG				.equ $DF2A

; I2C commands (bits 2..0)
I2CCMD_NOP				.equ $00
I2CCMD_START			.equ $01
I2CCMD_STOP				.equ $02
I2CCMD_SEND				.equ $03
I2CCMD_RXACK			.equ $04
I2CCMD_RXNAK			.equ $05

; status bit masks
I2CMASK_SCLPIN	    .EQU $08
I2CMASK_SDAPIN		.EQU $10
I2CMASK_ISIDLE		.EQU $20
I2CMASK_ACKBIT		.EQU $40
I2CMASK_SHFTRDY		.EQU $80


I2C_DATRD_REG			.equ $DF2B
I2C_DATWR_REG			.equ $DF2C

eepromPtr			.equ $FB




;------------------------------------------
#ifdef EXROMVICECART

;this is for a 8kB cart!!
	.org $8000 - $50

	.byte "C64 CARTRIDGE   "
	.byte $00,$00 		;header length
	.byte $00,$40 		;header length
	.word $0001 		;version
	.word $0000 		;crt type
	.byte $00 			;exrom line
	.byte $01 			;game line
	.byte $00,$00,$00,$00,$00,$00 ;unused
nameStart:
	.byte "TEST CART"
nameEnd:
	.fill (32-(nameEnd - nameStart), 0
	;chip packets
	.byte "CHIP"
	.byte $00,$00,$20,$10 ;chip length
	.byte $00,$00 ;chip type
	.byte $00,$00 ;bank
	.byte $80,$00 ;adress
	.byte $20,$00 ;length

	.org	$8000

	.word	coldStart					; Cartridge cold-start vector
	.word	warmStart                   ; Cartridge warm-start vector
	.byte	$C3, $C2, $CD, $38, $30		; CBM8O - Autostart key

coldStart:
;	KERNAL RESET ROUTINE
	stx $D016				; Turn on VIC for PAL / NTSC check
	jsr $FDA3				; IOINIT - Init CIA chips
	jsr $FD50				; RANTAM - Clear/test system RAM
	jsr $FD15				; RESTOR - Init KERNAL RAM vectors
	jsr $FF5B				; CINT   - Init VIC and screen editor
	cli						; Re-enable IRQ interrupts

; The following is required only if BASIC is to be used
;	BASIC RESET  Routine
	jsr $E453				; Init BASIC RAM vectors
	jsr $E3BF				; Main BASIC RAM Init routine
	jsr $E422				; Power-up message / NEW command
	ldx #$FB
	txs						; Reduce stack pointer for BASIC

warmStart:

#endif

;----------------------------------------------------------------------
#ifdef EXROMCART

	.org	$8000

	.word	coldStart					; Cartridge cold-start vector
	.word	warmStart                   ; Cartridge warm-start vector
	.byte	$C3, $C2, $CD, $38, $30		; CBM8O - Autostart key

coldStart:
;	KERNAL RESET ROUTINE
	stx $D016				; Turn on VIC for PAL / NTSC check
	jsr $FDA3				; IOINIT - Init CIA chips
	jsr $FD50				; RANTAM - Clear/test system RAM
	jsr $FD15				; RESTOR - Init KERNAL RAM vectors
	jsr $FF5B				; CINT   - Init VIC and screen editor
	cli						; Re-enable IRQ interrupts

#ifdef INITBASIC
; The following is required only if BASIC is to be used
;	BASIC RESET  Routine
	jsr $E453				; Init BASIC RAM vectors
	jsr $E3BF				; Main BASIC RAM Init routine
	jsr $E422				; Power-up message / NEW command
#endif

	ldx #$FB
	txs						; Reduce stack pointer for BASIC

warmStart:

#endif

;----------------------------------------------------------------------
; A RUN header for the file


#ifdef ISDISKFILE
	.org $07FF
	.db $01, $08
	.db $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$32,$00,$00,$00

programEntry:

#endif


#endif
