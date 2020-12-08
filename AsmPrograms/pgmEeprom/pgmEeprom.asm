#define EEPRTN_PRINTDOT
;#define EEPRTN_WAITKEY



#include "../includes/reuPlusDefs.asm"

#define ISDISKFILE
#include "../includes/fileHeaders.asm"
#include "../includes/fileHeaders.asm"
#include "../includes/kernal.asm"




entry:



; get the location of the appended data
; this is a static address
	lda	#(fileStart & $FF)
	sta	ptr1
	lda	#(fileStart >> 8)
	sta ptr1 + 1

; the number of 256 byte blocks
	lda fileLenL + 1
	sta	dvar1
	lda fileLenL + 2
	sta dvar1 + 1

; the eeprom address
	lda eepAdrL
	sta	dvar2
	lda eepAdrL + 1
	sta	dvar2 + 1
	lda eepAdrH
	sta	dvar3

	jsr	printBanner
	jsr printEepAdr
	jsr printFileLen
	jsr printYN
	jsr	waitkey
	cmp	#'Y'
	beq	doPgm
	cmp #'y'
	beq	doPgm

; user wants to exit
	jsr	printCRLF
	jsr	printPgmEnd
	rts

doPgm:
	jsr printCRLF
	jsr eepWriteBlock
	jsr	printCRLF
	jsr printByebye
	jsr	printPgmEnd
	rts



printBanner:
	lda #(banner & 255)
	ldx	#(banner >> 8)
	jsr	printAsciiz
	rts

printByebye:
	lda #(byebye & 255)
	ldx	#(byebye >> 8)
	jsr	printAsciiz
	rts

printYN:
	lda #(msg3 & 255)
	ldx	#(msg3 >> 8)
	jsr	printAsciiz
	rts


printAsciiz:
	sta	ptr2
	stx	ptr2 + 1
	ldy	#$00
printAsciizLoop:
	lda	(ptr2), y
	beq	printAsciizExit
	jsr	k_chrout
	iny
	bne printAsciizLoop
printAsciizExit:
	rts

waitkey:
	jsr	k_getin
	beq waitkey
	rts

; print the value in A in hex
;	at the current cursor position
printAHex:
	sta	tmp2
	lsr	a
	lsr a
	lsr a
	lsr a
	tax
	lda	hexDigits, x
	jsr	k_chrout
	lda	tmp2
	and #$0F
	tax
	lda	hexDigits, x
	jsr	k_chrout
	rts

printEepAdr:
	lda #(msg1 & 255)
	ldx	#(msg1 >> 8)
	jsr	printAsciiz

	lda	dvar3
	jsr printAHex
	lda	dvar2 + 1
	jsr printAHex
	lda	dvar2
	jsr printAHex
	lda #$0D
	jsr	k_chrout
	rts

printFileLen:
	lda #(msg2 & 255)
	ldx	#(msg2 >> 8)
	jsr	printAsciiz

	lda	dvar1 + 1
	jsr printAHex
	lda	dvar1
	jsr printAHex
	lda #$0D
	jsr	k_chrout
	rts

printDot:
	lda	#'.'
	jsr	k_chrout
	rts

printCRLF:
	lda	#$0D
	jsr	k_chrout
	rts

printPgmEnd:
	lda #(exitStr & 255)
	ldx	#(exitStr >> 8)
	jsr	printAsciiz
	rts



banner:
	.byte "EEPROM PROGRAMER V1.0", $0D, $00
byebye:
	.byte "EEPROM PROGRAMED", $0D, $00


msg1:
	.byte "EEPROM ADDRESS: $", $00
msg2:
	.byte "FILE LENGTH (BLOCKS): $", $00
msg3:
	.byte "CONTINUE (Y/N)", $00
exitStr:
	.byte "PROGRAM END", $0D, $00



hexDigits:
	.byte "0123456789ABCDEF"


#include "../includes/eepRtns.asm"
#include "../includes/i2cRtnsX.asm"

; this provides some safety space to avoid
;	munging either the program or the
;	succeeding variables

	.fill 16, 0
fileLenL:
	.word	$0100
fileLenH:
	.word	$0000

; only 16 of these bits are actually used.
;	the highest byte is ignored and the lowest
;	byte is assumed to be zero and so is
;	also ignored.
eepAdrL
	.word	$0000
eepAdrH
	.word	$0000

; this is where the code to be written to
;	the EEPROM will be concatenated

fileStart:

	.end
