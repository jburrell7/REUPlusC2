
;---------------------------------------------------------
; read a sector


disk sector read

sector_address = $2000  ; just an example

        ; open the channel file

        LDA #cname_end-cname
        LDX #<cname
        LDY #>cname
        JSR $FFBD     ; call SETNAM

        LDA #$02      ; file number 2
        LDX $BA       ; last used device number
        BNE .skip
        LDX #$08      ; default to device 8
.skip   LDY #$02      ; secondary address 2
        JSR $FFBA     ; call SETLFS

        JSR $FFC0     ; call OPEN
        BCS .error    ; if carry set, the file could not be opened

        ; open the command channel

        LDA #uname_end-uname
        LDX #<uname
        LDY #>uname
        JSR $FFBD     ; call SETNAM
        LDA #$0F      ; file number 15
        LDX $BA       ; last used device number
        LDY #$0F      ; secondary address 15
        JSR $FFBA     ; call SETLFS

        JSR $FFC0     ; call OPEN (open command channel and send U1 command)
        BCS .error    ; if carry set, the file could not be opened

        ; check drive error channel here to test for
        ; FILE NOT FOUND error etc.

        LDX #$02      ; filenumber 2
        JSR $FFC6     ; call CHKIN (file 2 now used as input)

        LDA #<sector_address
        STA $AE
        LDA #>sector_address
        STA $AF

        LDY #$00
.loop   JSR $FFCF     ; call CHRIN (get a byte from file)
        STA ($AE),Y   ; write byte to memory
        INY
        BNE .loop     ; next byte, end when 256 bytes are read
.close
        LDA #$0F      ; filenumber 15
        JSR $FFC3     ; call CLOSE

        LDA #$02      ; filenumber 2
        JSR $FFC3     ; call CLOSE

        JSR $FFCC     ; call CLRCHN
        RTS
.error
        ; Akkumulator contains BASIC error code

        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)

        ... error handling for open errors ...
        JMP .close    ; even if OPEN failed, the file has to be closed

cname:  .TEXT "#"
cname_end:

uname:  .TEXT "U1 2 0 18 0"
uname_end:




;---------------------------------------------------------
; write a sector



sector_address = $2000  ; just an example

        ; open the channel file

        LDA #cname_end-cname
        LDX #<cname
        LDY #>cname
        JSR $FFBD     ; call SETNAM

        LDA #$02      ; file number 2
        LDX $BA       ; last used device number
        BNE .skip
        LDX #$08      ; default to device 8
.skip   LDY #$02      ; secondary address 2
        JSR $FFBA     ; call SETLFS

        JSR $FFC0     ; call OPEN
        BCS .error    ; if carry set, the file could not be opened

        ; open the command channel

        LDA #bpcmd_end-bpcmd
        LDX #<bpcmd
        LDY #>bpcmd
        JSR $FFBD     ; call SETNAM
        LDA #$0F      ; file number 15
        LDX $BA       ; last used device number
        LDY #$0F      ; secondary address 15
        JSR $FFBA     ; call SETLFS

        JSR $FFC0     ; call OPEN (open command channel and send B-P command)
        BCS .error    ; if carry set, the file could not be opened

        ; check drive error channel here to test for
        ; FILE NOT FOUND error etc.

        LDX #$02      ; filenumber 2
        JSR $FFC9     ; call CHKOUT (file 2 now used as output)

        LDA #<sector_address
        STA $AE
        LDA #>sector_address
        STA $AF

        LDY #$00
.loop   LDA ($AE),Y   ; read byte from memory
        JSR $FFD2     ; call CHROUT (write byte to channel buffer)
        INY
        BNE .loop     ; next byte, end when 256 bytes are read

        LDX #$0F      ; filenumber 15
        JSR $FFC9     ; call CHKOUT (file 15 now used as output)

        LDY #$00
.loop2  LDA bwcmd,Y   ; read byte from command string
        JSR $FFD2     ; call CHROUT (write byte to command channel)
        INY
        CPY #bwcmd_end-bwcmd
        BNE .loop2    ; next byte, end when 256 bytes are read
.close

        JSR $FFCC     ; call CLRCHN

        LDA #$0F      ; filenumber 15
        JSR $FFC3     ; call CLOSE

        LDA #$02      ; filenumber 2
        JSR $FFC3     ; call CLOSE

        JSR $FFCC     ; call CLRCHN
        RTS
.error
        ; Akkumulator contains BASIC error code

        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)

        ... error handling for open errors ...
        JMP .close    ; even if OPEN failed, the file has to be closed

cname:  .TEXT "#"
cname_end:

bpcmd:  .TEXT "B-P 2 0"
bpcmd_end:

bwcmd:  .TEXT "U2 2 0 18 0"
        .BYTE $0D     ; carriage return, required to start command
bwcmd_end:
