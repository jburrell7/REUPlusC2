#COMPILE EXE
#DIM ALL

GLOBAL sFileName        AS STRING
GLOBAL eepAdr           AS LONG

GLOBAL exePath          AS STRING

GLOBAL loader           AS STRING*4096
GLOBAL loaderlen        AS LONG

GLOBAL eepData          AS STRING*32768
GLOBAL eepDataLen       AS LONG

GLOBAL jmpAdr           AS WORD

GLOBAL sParam1          AS STRING
GLOBAL sParam2          AS STRING
GLOBAL sParam3          AS STRING



%PARAM_OK               = 0
%PARAM_EEPADR_TOO_BIG   = 1
%PARAM_NOFILENAME       = 2
%PARAM_FILENOTFOUND     = 3
%PARAM_FILETOOBIG       = 4

%LOADER_NOT_FOUND       = 5
%UNKNOWN_PARAM          = 6
%BADJUMPADR             = 7

SUB showEepFile()
LOCAL sHex, sAscii  AS STRING
LOCAL sLine         AS STRING
LOCAL bPtr          AS BYTE PTR
LOCAL I, J          AS LONG

    bPtr = VARPTR(eepData)
    FOR I = 0 TO 7
        sLine   = ""
        sAscii  = ""
        FOR J = 0 TO 15
            sLine = sLine + HEX$(@bPtr, 2) + " "
            IF ((@bPtr < 32) OR (@bPtr > 126)) THEN
                sAscii = sAscii + "."
            ELSE
                sAscii = sAscii + CHR$(@bPtr)
            END IF
            bPtr += 1

        NEXT J
        sHex = sHex + sLine + " : " + sAscii + $CRLF
    NEXT I

    STDOUT sHex
    WAITKEY$



END SUB

SUB showUsage()

    STDOUT "This program concatenates a data file to a"
    STDOUT "  6502 assembler routine the writes the file"
    STDOUT "  data to the REUPlus EEPROM. Because of this"
    STDOUT "  and the maximum memory of the C64,"
    STDOUT "  the maximum size file one can concatenate"
    STDOUT "  will be 32768 bytes and the program will"
    STDOUT "  enforce this limit by refusing to concatenate"
    STDOUT "  a larger file"
    STDOUT $CRLF
    STDOUT "All command line parameters are case insensative as they are"
    STDOUT "  converted to uppercase in the program. This is Windows, eh?"
    STDOUT $CRLF
    STDOUT " This file uses pgmEeprom.bin, so ensure it is in the"
    STDOUT "  same directory as this file."

    STDOUT $CRLF
    STDOUT "-----------------------------------------------------------"
    STDOUT $CRLF

    STDOUT "Usage:"
    STDOUT "concat -n input_file_name -e eeprom_address"
    STDOUT "  input_file_name - self explanatory"
    STDOUT "  eeprom_address - the EEPROM address where the file is to be written"

    STDOUT $CRLF
    STDOUT "Example: concat -n foo -e $001234"
    STDOUT "Will concatenate the file foo and write it to address 0x001234"
    STDOUT "The program willa accept addresses in decimal or hexadecimal"
    STDOUT "  if the hex values are preceded with $ or 0x"

END SUB


FUNCTION processParam(sParam AS STRING) AS LONG
LOCAL sTemp         AS STRING
LOCAL hFile         AS LONG
LOCAL fileLen       AS LONG
LOCAL tmpDwd        AS DWORD

' we know the first character is a -, so
'  look at the second character

' clip off the parmeter
    sTemp = UCASE$(TRIM$(RIGHT$(sParam, LEN(sParam) - 2)))

    SELECT CASE LEFT$(sParam, 1)
    CASE "E"
    ' eeprom address
        IF (LEN(sParam) <> 0) THEN
            sParam = RIGHT$(sParam, LEN(sParam) - 1)
            REPLACE "$" WITH "&H" IN sParam
            REPLACE "0X" WITH "&H" IN sParam
            eepAdr = VAL(sParam)
        END IF

        IF ((eepAdr AND 255) <> 0) THEN
            eepAdr = -1
            STDOUT "EEPROM address not on 256 byte boundary"
            FUNCTION = %PARAM_EEPADR_TOO_BIG
        END IF

        IF (eepAdr > &h7FF00) THEN
            STDOUT "EEPROM address too large"
            FUNCTION = %PARAM_EEPADR_TOO_BIG
            EXIT FUNCTION
        END IF

        FUNCTION = %PARAM_OK

    CASE "N"
        sFileName = sTemp

        IF (LEN(sFileName) = 0) THEN
        ' no file name was provided
            FUNCTION = %PARAM_NOFILENAME
            EXIT FUNCTION
        END IF

        IF (NOT ISFILE(sFileName)) THEN
        ' the file could not be found
            STDOUT "Could not find EEPROM file: " + sFileName
            sFileName = ""
            FUNCTION = %PARAM_FILENOTFOUND
            EXIT FUNCTION
        END IF

        hFile = FREEFILE
        OPEN sFileName FOR BINARY AS hFile
        fileLen = LOF(hFile)
        CLOSE #hFile

        IF (fileLen > 32770) THEN
        ' the file is too long
            STDOUT "EEPROM file is larger than 32770 bytes"
            sFileName = ""
            FUNCTION = %PARAM_FILETOOBIG
            EXIT FUNCTION
        END IF
    CASE "J"
        IF (LEN(sParam) <> 0) THEN
            sParam = RIGHT$(sParam, LEN(sParam) - 1)
            REPLACE "$" WITH "&H" IN sParam
            REPLACE "0X" WITH "&H" IN sParam
            tmpDwd = VAL(sParam)
        END IF

        IF (tmpDwd > 65536) THEN
            jmpAdr = 0
            STDOUT "Jump address too large. Must be less than 65535"
            FUNCTION = %BADJUMPADR
        ELSE
            jmpAdr = tmpDwd AND &H0FFFF
            FUNCTION = %PARAM_OK
        END IF


    CASE ELSE
    ' silently ignore unknown parameters
        FUNCTION = %PARAM_OK
        EXIT FUNCTION
    END SELECT

END FUNCTION


SUB parseParams(cmdStr AS STRING)
LOCAL sTemp         AS STRING
LOCAL paramNr       AS LONG

    sFileName   = ""
    eepAdr      = -1
    jmpAdr      = 0

    cmdStr = UCASE$(cmdStr) + " - "

    sTemp = "x"

    paramNr = 2
    WHILE (LEN(sTemp) <> 0)
        sTemp = TRIM$(PARSE$(cmdStr, "-", -paramNr))
        processParam(sTemp)
        paramNr += 1
    WEND

    STDOUT "sFileName: " + sFileName
    STDOUT "eepAdr:    " + HEX$(eepAdr, 6)
    STDOUT "jmpAdr:    " + HEX$(jmpAdr, 4)

END SUB


SUB putDword(BYVAL pByte AS BYTE PTR, BYVAL putVal AS DWORD)

    @pByte = putVal AND 255
    pByte  += 1
    SHIFT RIGHT putVal, 8

    @pByte = putVal AND 255
    pByte  += 1
    SHIFT RIGHT putVal, 8

    @pByte = putVal AND 255
    pByte  += 1
    SHIFT RIGHT putVal, 8

    @pByte = putVal AND 255
    pByte  += 1

END SUB


FUNCTION concatenateFiles() AS LONG
LOCAL sLoader       AS STRING
LOCAL hFile         AS LONG
LOCAL pByte         AS BYTE PTR
LOCAL sOutFile      AS STRING

    sLoader = EXE.PATH$ + "pgmEeprom.bin"

    IF (NOT ISFILE(sLoader)) THEN
        STDOUT "Could not find the loader file <pgmEeprom.bin> in the"
        STDOUT "executable file directory. Aborting program."
        FUNCTION = %LOADER_NOT_FOUND
        EXIT FUNCTION
    END IF

' get the loader
    hFile = FREEFILE
    OPEN sLoader FOR BINARY AS #hFile
    loaderLen = LOF(hFile)
    GET$ #hFile, loaderLen, loader
    CLOSE #hFile
' get the C64 executable
    hFile = FREEFILE
    OPEN sFileName FOR BINARY AS hFile
' skip the first two bytes of the file as
' they are the load address which can
' be discarded
    eepDataLen = LOF(hFile) - 2

' bypass the first two bytes
    GET$ #hFile, 2, eepData
    GET$ #hFile, eepDataLen, eepData
    CLOSE #hFile

' there are two double word parameters in the last four bytes
'   of the C64 loader program that must be modified.
' they are:
'   the length of the eeprom file rounded up to the next
'       whole 256 bbyte page
'
'   The EEPROM address where the file is to be loaded.
'
' both parameters are standard little endian double words
'
'
' set up a pointer to allow the required modifications
'

' adjust for even pages, rounding up if required.
    IF ((eepDataLen AND 255) <> 0) THEN
        eepDataLen = (eepDataLen + 256) AND &HFFFFFF00
    END IF


' point to the file length
    pByte = VARPTR(loader) + loaderLen - 8

    putDword(pByte, eepDataLen)
    pByte += 4
    putDword(pByte, eepAdr)

' if a jump parameter was passed, overwrite the
'   first three bytes of the eeprom file with a
'   jmp xxxx instruction

STDOUT "concatenateFiles:jmpAdr: " + HEX$(jmpAdr, 4)
    pByte = VARPTR(eepData)
    IF (jmpAdr <> 0) THEN
        pByte = VARPTR(eepData)
        @pByte = &H4C
        pByte += 1

        @pByte = (jmpAdr AND 255)
        pByte += 1
        @pByte = (jmpAdr \ 256)
    END IF

    sFileName = sFileName + "."
    sOutFile = PARSE$(sFileName, ".", 1) + ".prg"

    hFile = FREEFILE
    OPEN sOutFile FOR BINARY AS #hFile
    PUT$ #hFile, LEFT$(loader, loaderLen)
    PUT$ #hFile, LEFT$(eepData, eepDataLen)
    CLOSE #hFile


    STDOUT "Output file: " + sOutFile

END FUNCTION


FUNCTION PBMAIN () AS LONG
LOCAL errCode       AS LONG
LOCAL sCommand      AS STRING


    sCommand = COMMAND$

    STDOUT sCommand

' debug
'    sCommand = "-n bootStub -e $001200"

    parseParams(sCommand)

    IF ((LEN(sFileName) = 0) OR (eepAdr < 0)) THEN
        STDOUT "Bad parameter. Exiting program"
    ELSE
    ' the file name and eeprom address exist and are
    '   valid, so process the files
        concatenateFiles()
        STDOUT "Program done"
    END IF


    WAITKEY$


END FUNCTION
