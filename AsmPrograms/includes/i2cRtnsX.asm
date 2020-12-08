
;#include "reuPlusDefs.asm"


; ---------------------------------------------------------------
; Send an I2C START command
;
; Inputs:
;	None
;
; Outputs:
;	None
;
; Registers affected:
;	All
; ---------------------------------------------------------------
i2cSendStart:
;
; initiate the START command
	lda		#I2C_CMDSTART
	sta		I2C_CMDREG

; the I2C FSM will reset the command to
;	I2C_CMDNOP when it is done
L0001:
	lda		I2C_CMDREG
	and		#I2C_MASK_CMDBITS
	cmp		#I2C_CMDNOP
	bne		L0001
	rts


; ---------------------------------------------------------------
; Send an I2C STOP command
;
; Inputs:
;	None
;
; Outputs:
;	None
;
; Registers affected:
;	All
; ---------------------------------------------------------------

i2cSendStop:

; initiate the STOP command
	lda		#I2C_CMDSTOP
	sta		I2C_CMDREG

; the I2C FSM will reset the command to
;	I2C_CMDNOP when it is done
L0002:
	lda		I2C_CMDREG
	and		#I2C_MASK_CMDBITS
	bne		L0002
	rts

; ---------------------------------------------------------------
; Send one byte over the I2C bus. This routine returns the state
;	of the ACK bit
;
; Inputs:
;	A	byte to send
;
; Outputs:
;	A	$00 - ACK received, else ACK not received
;
; Registers affected:
;	All
;
; ---------------------------------------------------------------

i2cSendByte:
	ldx		#I2C_CMDSEND
	stx		I2C_CMDREG

i2cSendByteN:
	sta		I2C_DATWRREG

L0003:
	lda		I2C_CMDREG
	and		#I2C_MASK_SFTRDY
	beq		L0003

	ldx		#$00
	lda		I2C_CMDREG
	and		#I2C_MASK_ACKBIT
	rts


; ---------------------------------------------------------------
; Send N bytes (up to 256) over the I2C bus.
;
; Inputs:
;	tmp1	number of bytes to send
;	ptr1	send buffer address
;
; Outputs:
;	A	$00 - all is OK, else an error occurred during the transfer
;
; Registers affected:
;	All
;	ptr1
;
; ---------------------------------------------------------------
;
i2cSendNBytes:

; set up the I2C controller
	lda		#I2C_CMDSEND
	sta		I2C_CMDREG

; (ptr1), y will now point to the first
; bytes to be transferred
	ldy		#$00

L0004B:
; get a data byte to send
	lda		(ptr1), y
; send it
	jsr 	i2cSendByteN
	bne		L0004A	; there is an error

; next byte
	iny
; update the byte counter
	dec		tmp1
; back around for more bytes.
	bne		L0004B

	lda		#$00
L0004A:
	ldx		#$00
	rts

; ---------------------------------------------------------------
; Receive one byte on the I2C bus and respond with an ACK
;
; Inputs:
;	None
;
; Outputs:
;	A	the byte received
;
; Registers affected
;	All
; ---------------------------------------------------------------
;
i2cGetByteAck:

	ldx		#I2C_CMDRXACK
	stx		I2C_CMDREG

i2cGetByteAckN:
	lda		I2C_DATRDREG
	tax

L0005:
	lda		I2C_CMDREG
	and		#I2C_MASK_SFTRDY
	beq		L0005

	txa
	ldx		#$00
	rts


; ---------------------------------------------------------------
; Receive one byte on the I2C bus and respond with an NACK
;
; Inputs:
;	None
;
; Outputs:
;	A	the byte received
;
; Registers affected
;	All
; ---------------------------------------------------------------

i2cGetByteNack:

	ldx		#I2C_CMDRXNACK
	stx		I2C_CMDREG
	lda		I2C_DATRDREG
	tax

L0005GBN:
	lda		I2C_CMDREG
	and		#I2C_MASK_SFTRDY
	beq		L0005GBN

	txa
	ldx		#$00
	rts


; ---------------------------------------------------------------
; Get N bytes over the I2C bus.
;
; Inputs:
;	ptr1			Pointer to the receive buffer
;	ptr4			The byte count (65536 bytes max)
;
; Outputs:
;	A	$00 - all is OK, else an error occurred during the transfer
;
; Registers affected:
;	All
;	ptr1
;
; ---------------------------------------------------------------
;
i2cGetNBytes:

; set up the I2C controller
	lda		#I2C_CMDRXACK
	sta		I2C_CMDREG

; do a dummy read. this shifts in the first
; actual data byte from the I2C peripheral
	jsr		i2cGetByteAckN

; (ptr1), y will now point to buffer location
; where the read byte will be put
	ldy		#$00

L0006B:
; decrement the byte count and check if it
;	is zero
	lda		ptr4
	bne 	i2cGNBdecbc
	lda		ptr4 + 1
	beq 	exit			; the byte counter is zero, so we are done
	dec		ptr4 + 1
i2cGNBdecbc:
	dec 	ptr4

; read the byte in the I2C FSM receive register
; and get the next
	jsr 	i2cGetByteAckN
	sta		(ptr1), y

; increment the buffer pointer
	inc 	ptr1
	bne		i2cGNBincptr
	inc		ptr1+1
i2cGNBincptr:



; back around for more bytes.
	jmp		L0006B

exit:
; do a dummy read with a NACK to end the transaction
	jsr		i2cGetByteNack
	lda		#$00
	ldx		#$00

	rts


