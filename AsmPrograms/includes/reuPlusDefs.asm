
#ifndef DEFS

#define DEFS

; REU equates
REU_STAT_REG		= $DF00
; status register masks
MSK_INTRPEND	= $80
MSK_EOB		= $40
MSK_VFYERR		= $20
MSK_RAMSIZE	= $10
MSK_CHIPVER	= $0F

REU_CTL_REG			= $DF01
; Command register values
CMD_EXECUTE	= $80
CMD_AUTOLD		= $20
CMD_NOFF00		= $10

TTC64TOREU		= $00
TTREUTOC64		= $01
TTSWAP			= $02
TTVFY			= $03

REU_C64BASEL_REG	= $DF02
REU_C64BASEH_REG	= $DF03
REU_REUBASEL_REG	= $DF04
REU_REUBASEM_REG	= $DF05
REU_REUBASEH_REG	= $DF06
REU_XFRLENL_REG		= $DF07
; all 8 bits written to this register
;	will be used. when read back
;	only bits 2..0 will be returned
;	with bits 7..3 will be '1'.
; read register REU_EXPHI8_REG to get
;	all i bits
REU_XFRLENH_REG		= $DF08
REU_IMSK_REG		= $DF09
; interrupt mask register masks
MSK_INTRENA	= $80
MSK_EOBINTR	= $40
MSK_VFYINTR	= $20
VAL_NOINTR		= $00

REU_ADRCTL_REG		= $DF0A
; address type register values
INCBOTH		= $00
FIXREU		= $40
FIXC64		= $80
FIXBOTH		= $C0

REU_REUBASESB_REG	= $DF0F

REU_ROMLL_REG		= $DF10
REU_ROMLH_REG		= $DF11
REU_ROMHL_REG		= $DF12
REU_ROMHH_REG		= $DF13
REU_MEML_REG		= $DF14
REU_MEMM_REG		= $DF15
REU_MEMH_REG		= $DF16

; reads back all 8 bits written to
;	REU_REUBASEH_REG
REU_EXPHI8_REG		= $DF0E
REU_SUPERBANK_REG	= $DF0F


; Video peripheral registers
VIDSTAT_REG			= $DF20
VIDCHAR_REG			= $DF21

;
; selects which of the 32 banks of
;	16 mailbox registers are
;	selected for access at
;	addresses $DF30..$DF3F
;
MBOXBANK_REG		= $DF26
; controls the operation of the
;	coprocessor
Z80CTL_REG			= $DF27
;
; controls access to the boot ROM
;	and sets the state of EXROM
;	and GAME
;
ROMSEL_REG			= $DF28


I2C_CMDREG			= $DF2A
I2C_CMDNOP				= $00
I2C_CMDSTART			= $01
I2C_CMDSTOP				= $02
I2C_CMDSEND				= $03
I2C_CMDRXACK			= $04
I2C_CMDRXNACK			= $05
; status bits from the command register
I2C_MASK_SFTRDY			= $80
I2C_MASK_ACKBIT 		= $40
I2C_MASK_CMDBITS 		= $07

I2C_DATRDREG		= $DF2B
I2C_DATWRREG		= $DF2C


FPGAREV_REG			= $DF2E
COP_SEL_REG			= $DF2F

; Coprocewssor mailbox registers.
;	These
MBOX0_REG			= $DF30
MBOX1_REG			= $DF31
MBOX2_REG			= $DF32
MBOX3_REG			= $DF33
MBOX4_REG			= $DF34
MBOX5_REG			= $DF35
MBOX6_REG			= $DF36
MBOX7_REG			= $DF37
MBOX8_REG			= $DF38
MBOX9_REG			= $DF39
MBOX10_REG			= $DF3A
MBOX11_REG			= $DF3B
MBOX12_REG			= $DF3C
MBOX13_REG			= $DF3D
MBOX14_REG			= $DF3E
MBOX15_REG			= $DF3F



; 6502 reset vector
RST_VEC				= $FFFC



; these define veriable locations in memory
;	that is relatively safe in BASIC
ptr1	= $FB
ptr2	= ptr1 + 2

ptr3	= $0340
ptr4	= ptr3 + 2

dvar1	.equ ptr4 + 2
dvar2	.equ dvar1 + 2
dvar3	.equ dvar2 + 2
dvar4	.equ dvar3 + 2
dvar5	.equ dvar4 + 2
dvar6	.equ dvar5 + 2
dvar7	.equ dvar6 + 2
dvar8	.equ dvar7 + 2

tmp1	= dvar8 + 2
tmp2	= tmp1 + 1
tmp3	= tmp2 + 1
tmp4	= tmp3 + 1



#endif
