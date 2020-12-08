
#ifndef lib_cbm_kernal_a
#define lib_cbm_kernal_a

; Taken from the web.
; Sorry, I can't give credit because I don't have the URL anymore.
; There are alternative names for some calls.


k_cint		.equ $ff81
k_ioinit	.equ $ff84
k_ramtas	.equ $ff87
k_restor	.equ $ff8a
k_vector	.equ $ff8d
k_setmsg	.equ $ff90
k_secnd		.equ $ff93
k_tksa		.equ $ff96
k_memtop	.equ $ff99
k_membot	.equ $ff9c
k_key		.equ $ff9f
k_settmo	.equ $ffa2
k_iecin		.equ $ffa5
k_acptr			.equ $ffa5
k_iecout	.equ $ffa8
k_ciout			.equ $ffa8
k_untalk	.equ $ffab
k_untlk			.equ $ffab
k_unlisten	.equ $ffae
k_unlsn			.equ $ffae
k_listen	.equ $ffb1
k_listn			.equ $ffb1
k_talk		.equ $ffb4
k_readss	.equ $ffb7
k_setlfs	.equ $ffba
k_setnam	.equ $ffbd	; A is length, X is ptr-low, Y is ptr-high
k_open		.equ $ffc0
k_close		.equ $ffc3
k_close_A		.equ $ffc3
k_chkin		.equ $ffc6
k_chkin_X		.equ $ffc6
k_chkout	.equ $ffc9
k_chkout_X		.equ $ffc9
k_ckout			.equ $ffc9
k_clrchn	.equ $ffcc
k_clrch			.equ $ffcc
k_chrin		.equ $ffcf
k_basin			.equ $ffcf
k_chrout	.equ $ffd2
k_basout		.equ $ffd2
k_bsout			.equ $ffd2
k_load		.equ $ffd5
k_load_AXY		.equ $ffd5	; A means verify, YYXX is desired load address (if channel == 0), returns end+1 in YYXX
k_save		.equ $ffd8
k_save_AXY		.equ $ffd8	; A is zp address of start ptr(!), YYXX is end address (+1)
k_settim	.equ $ffdb
k_rdtim		.equ $ffde
k_stop		.equ $ffe1
k_getin		.equ $ffe4
k_get			.equ $ffe4
k_clall		.equ $ffe7
k_udtim		.equ $ffea
k_scrorg	.equ $ffed
k_plot		.equ $fff0
k_plot_CXY		.equ $fff0	; get/set cursor (to set, clear carry. X/Y are y/x!)
k_iobase	.equ $fff3

#endif
