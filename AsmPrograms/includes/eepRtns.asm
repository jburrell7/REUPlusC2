



;----------------------------------------
; Write a block of data to the EEPROM.
;	This routine assumes that we are writing
;	complete 256 byte blocks and that the write
;	address is on a 256 byte boundary.
;
; We do no verification to ensure that data
;	is not corrupted, so caveat emptor
;
; Inputs:
;	ptr1			address of buffer which has
;						data to be written
;	dvar1			the number of 256 byte blocks
;						to write
;	dvar3:dvar2		the EEPROM write address (24 bits)
;
;

eepWriteBlock:

;
; check so see if the EEPROM write address is
;	an even multiple of 256. exit with an
;	error to prevent toatlly messing up
;	the EEPROM.
;
	lda dvar2
	bne	eepWrError

;
; is the number of blocks to move between
;	$001 and $800 inclusive?

; check for zero blocks to move
	lda	dvar1
	ora	dvar1 + 1
	beq eepWrOK		; silently exit after moving nothing

	sec
	lda dvar1
	sbc #$01
	lda	dvar1+1
	sbc #$08
	bcs	eepWrError


eepWriteBlockLoop1:

#ifdef EEPRTN_PRINTDOT
	jsr	printDot
#endif

#ifdef EEPRTN_WAITKEY
	jsr	waitkey
#endif


	jsr eepMakeSlaveAdr
	jsr i2cSendStart

; send the address at which to write
;
; send the slave address
	lda dvar3 + 1
	jsr i2cSendByte
	bne	eepWrError		; no ACK from the EEPROM

	lda	dvar2 + 1
	jsr i2cSendByte
	bne	eepWrError		; no ACK from the EEPROM

	lda	dvar2
	jsr i2cSendByte
	bne	eepWrError		; no ACK from the EEPROM

; send 256 bytes
	lda	#$00
	sta	tmp1

	jsr	i2cSendNBytes
	jsr i2cSendStop

	lda #$01
	sta	$DF2E

	ldx	#$00
	jsr	eepWriteBlockWaitWr
	bne	eepWrError

;	jsr eepWait15ms

	lda #$00
	sta	$DF2E



; increment the EEPROM page number
	inc dvar2 + 1
	bne	eepWB1
	inc	dvar3
eepWB1:

; increment the buffer pointer 256 bytes
	inc	ptr1 + 1

; decrement the block count and check against zero
	lda	dvar1
	bne	eepWB2
	lda	dvar1 + 1
	beq eepWrOK		; no more blocks left, so exit
	dec dvar1 + 1
eepWB2:
	dec	dvar1
	jmp eepWriteBlockLoop1



eepWrError:
	lda #$FF
eepWrOK:
	rts


eepWait15ms:
	ldx	#$1a
	lda	#$06

;------------------------------------------------------------
;Constant time decrement
;6 cycles
;A = high byte, X = low byte
;Underflow (decrementing to $FFFF) clears the carry
eepWait15msLoop:
	CPX #$01
	DEX
	SBC #$00
	bcs	eepWait15msLoop
	rts





;----------------------------------------
; Wait for a buffer write to complete
; 	The EEPROM may take up to 10ms to
;	complete writing its data buffer to
;	the array but it may complete im
;	much less time. The EEPROM allows
;	a polling operation to be used to
;	determine if the write is complete.
;
;	The polling sends the slave address
;	to the EEPROM and looks for an ACK
;	fom the chip. If the ACK comes back,
;	the write is compete and we can
;	move on. If no ACK is received after
;	a number of retries, we declare an
;	error and return
;
eepWriteBlockWaitWr:
	jsr i2cSendStart
; send the slave address
	lda dvar3 + 1
	jsr i2cSendByte
	beq	eepWriteBlockWaitWr1		; got an ACK from the EEPROM
	dex								; decrement the retry counter
	bne eepWriteBlockWaitWr			; back to try again
	lda	#$FF
	rts
eepWriteBlockWaitWr1:
	jsr	i2cSendStop
	lda	#$00
	rts




;----------------------------------------
; Read a block of data from the EEPROM
;
; Inputs:
;----------------------------------------
; These two variables are in the position
;	required by the i2cGetNBytes subroutine
;
;	ptr1	address of buffer into which
;				data is to be written
;	dvar1	lengeh of data to be read
;				65536 bytes maximum
;----------------------------------------
;
;	dvar3:dvar2		EEPROM read address (24 bits)
;
eepReadBlock:
	jsr i2cSendStart

; form the slave address and send the
;	high 3 bits of the read address
;
	jsr eepMakeSlaveAdr

	jsr i2cSendByte
	bne	eepRdError		; no ACK from the EEPROM

	lda	dvar2 + 1
	jsr i2cSendByte
	bne	eepRdError		; no ACK from the EEPROM

	lda	dvar2
	jsr i2cSendByte
	bne	eepRdError		; no ACK from the EEPROM

	jsr i2cSendStart

	lda	dvar3 + 1		; get the slave address
	ora #$01			; set the read mode bit
	jsr i2cSendByte		; re-send the slave address
	bne	eepRdError		; no ACK from the EEPROM

; read the bytes
	jsr i2cGetNBytes
eepRdError:
	jsr i2cSendStop
	rts


;----------------------------------------
; Make the slave address from the value in
;	the EEPROM address registers
;
;	dvar3:dvar2		EEPROM read address (24 bits)
;
eepMakeSlaveAdr:
;	set up the slave address for future use
	lda dvar3
	and #07
	sta	dvar3
	asl	a
	and #$FE
	ora	#$A0
	sta dvar3 + 1		; save for later
	rts

