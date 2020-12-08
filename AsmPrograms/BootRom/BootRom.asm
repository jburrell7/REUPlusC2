
; various constants
#include "../includes/reuPlusDefs.asm"
#include "../includes/kernal.asm"

; make this an EXROM cart
#define EXROMCART
#define INITBASIC
#include "../includes/fileHeaders.asm"

; Download the boot program from the EEPROM

; destination address in C64 memory
	lda 	#$01
	sta 	ptr1
	lda 	#$08
	sta 	ptr1 + 1
; move 16384 bytes
	lda		#$40
	sta		ptr4 + 1
	lda		#$00
	sta		ptr4

;
; The boot program is located at $7C000 in
;	the EEPROM memory space.

; send I2C START
	jsr		i2cSendStart
; send the slave address (write mode)
;	and EEPROM address
	lda		#(($07 << 1) | $A0)
	jsr		i2cSendByte
	bne		errorRtn
	lda		#$C0
	jsr		i2cSendByte
	bne		errorRtn
	lda		#$0
	jsr		i2cSendByte
	bne		errorRtn
; send re-START
	jsr		i2cSendStart
; send the slave address (read mode)
;	and EEPROM address
	lda		#(($07 << 1) | $A1)
	jsr		i2cSendByte
	bne		errorRtn

	jsr		i2cGetNBytes
	jsr		i2cSendStop

; jump to the downloaded program
	jmp		$0801


;--------------------------------------
; This section is run if an error during
;	the EEPROM access is detected. The
;	code issues an I2C STOP command to
;	terminate the transaction and then
;	downloads a stub program that disables
;	the boot ROM and does a cold restart
;	of the C64
;
errorRtn:
; end the I2C transaction
	jsr		i2cSendStop

;
; transfer the reboot routine to $801
;	in the C64 main memory and then
;	jump to it
errRtnTest:
	ldx		#$00
errRtnTestLoop:
	lda		errorRtnExit, x
	sta		$0801, x
	inx
	cpx		#(errorRtnExitEnd - errorRtnExit + 2)
	bne		errRtnTestLoop
	jmp		$0801




errorRtnExit:
	lda		#$80
	sta		ROMSEL_REG
	jmp		(RST_VEC)
errorRtnExitEnd:

#include "../includes/i2cRtnsX.asm"


	.end
