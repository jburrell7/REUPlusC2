#COMPILE EXE
#DIM ALL

GLOBAL g_hBinFile        AS LONG
GLOBAL g_sBinFile        AS STRING

GLOBAL g_hOutFile        AS LONG
GLOBAL g_sOutFile        AS STRING

GLOBAL g_ramSize         AS LONG

GLOBAL g_fileBuf        AS STRING*4096

GLOBAL g_usage          AS LONG


%FILEIS_BIN = 0
%FILEIS_HEX = 1

GLOBAL g_fileType       AS LONG

SUB printUsage()

    STDOUT "This program converts binary or Intel Hex files to"
    STDOUT " a MIF file format with start address 0f 0x0000."
    STDOUT " This is used as input to the FPGA compiler to"
    STDOUT " initiaize the boot ROM."
    STDOUT ""
    STDOUT "Usage: bin2Mif -fFileName -rRamSize [-b|-h]"
    STDOUT " Note: all parameters are case insensitive"
    STDOUT ""
    STDOUT "-f = The name of the file to convert (required)."
    STDOUT "-r = The size of the FPGA ROM (required)."
    STDOUT "      This value must be at least 1 and less than"
    STDOUT "      4097."
    STDOUT "     Decimal or hexadecimal values are accepted"
    STDOUT "     with hexadecimal values being preceded with"
    STDOUT "     a $ or 0x."
    STDOUT " These are optional:"
    STDOUT "-b = The input file is binary (default)."
    STDOUT "-h = The input file is Intel hex format."
    STDOUT "     The program assumes the hex file is valid"
    STDOUT "     and well formatted. Nonsense will be"
    STDOUT "     produced if this is not true."
END SUB

FUNCTION parseParams() AS LONG
LOCAL sCmd              AS STRING
LOCAL whileFlag         AS LONG
LOCAL sTemp             AS STRING
LOCAL paramNr           AS LONG
LOCAL rtnVal            AS LONG


    g_sBinFile  = ""
    g_ramSize   = 0
    g_fileType  = %FILEIS_BIN
    g_usage     = 0

    sCmd = COMMAND$ + "-x"

    whileFlag   = 1
    paramNr     = 1

    WHILE(whileFlag <> 0)
        sTemp = UCASE$(TRIM$(PARSE$(sCmd, "-", -paramNr)))
        IF (LEN(sTemp) <> 0) THEN
            SELECT CASE LEFT$(sTemp, 1)
            CASE "F"
            ' file name
                g_sBinFile = RIGHT$(sTemp, LEN(sTemp) - 1)
                IF (NOT ISFILE(g_sBinFile)) THEN
                    STDOUT "Could not find file:"
                    STDOUT g_sBinFile
                    g_sBinFile = ""
                END IF
            CASE "R"
            ' ram size
                REPLACE "$" WITH "&H" IN sTemp
                REPLACE "0X" WITH "&H" IN sTemp
                g_ramSize = VAL(RIGHT$(sTemp, LEN(sTemp) - 1))
                IF (g_ramSize AND 255) THEN
                    g_ramSize = (g_ramSize AND &H0FF00) + 256
                END IF
            CASE "B"
                g_fileType  = %FILEIS_BIN
            CASE "H"
                g_fileType  = %FILEIS_HEX

            CASE "?"
                g_usage = 1
            END SELECT
        ELSE
            whileFlag = 0
        END IF
        paramNr += 1
    WEND

    rtnVal = 0

    IF (g_usage = 0) THEN
        IF ((LEN(g_sBinFile) = 0)) THEN
            STDOUT "Error in binary file name:"
            STDOUT "> " + g_sBinFile + " <"
            rtnVal = -1
        END IF

        IF ((g_ramSize = 0) OR (g_ramSize > 4096)) THEN
            STDOUT "Error in memory size:"
            STDOUT "> " + STR$(g_ramSize) + " <"
            STDOUT "Memory size MUST be between 1 and 4096 bytes"
            STDOUT "rounded up to the next page"
            rtnVal = -1
        END IF
    END IF


    FUNCTION = rtnVal

END FUNCTION


SUB writeMif()
LOCAL inFileLen         AS LONG
LOCAL pByte             AS BYTE PTR
LOCAL I                 AS LONG

    pByte       = VARPTR(g_fileBuf)

    g_sOutFile  = g_sBinFile + ".mif"
    g_hOutFile = FREEFILE
    OPEN g_sOutFile FOR OUTPUT AS #g_hOutFile

    PRINT #g_hOutFile, "DEPTH =" + STR$(inFileLen) + ";"
    PRINT #g_hOutFile, "WIDTH = 8;"
    PRINT #g_hOutFile, "ADDRESS_RADIX = HEX;"
    PRINT #g_hOutFile, "DATA_RADIX = HEX;"
    PRINT #g_hOutFile, "CONTENT"
    PRINT #g_hOutFile, "BEGIN"

    FOR I = 0 TO g_ramSize - 1
        PRINT #g_hOutFile, HEX$(I, 4) + " : " + HEX$(@pByte, 2) + ";"
        pByte += 1
    NEXT I

    PRINT #g_hOutFile, "END;"

    CLOSE #g_hOutFile


END SUB


FUNCTION readBinFile() AS LONG
LOCAL inFileLen         AS LONG

    g_hBinFile = FREEFILE
    OPEN g_sBinFile FOR BINARY AS #g_hBinFile
    inFileLen = LOF(g_hBinFile)

' truncate the number of bytes read to be no more
'   than the stated FPGA ROM size
    IF (inFileLen > g_ramSize) THEN
        inFileLen = g_ramSize
    END IF
' read the file into the buffer
    GET$ #g_hBinFile, inFileLen, g_fileBuf
    CLOSE #g_hBinFile

    FUNCTION = 0

END FUNCTION



FUNCTION substrHexToDec(sLine AS STRING, startChar AS LONG, strLen AS LONG) AS LONG
LOCAL sTemp         AS STRING

    sTemp = MID$(sLine, startChar, strLen)
    FUNCTION = VAL("&H" + sTemp)

END FUNCTION


'-------------------------------------------------------
' Read an Intel Hex file and convert to binary
'
FUNCTION readHexFile() AS LONG
LOCAL inFileLen         AS LONG
LOCAL sLine, sTemp      AS STRING
LOCAL byteCount         AS LONG
LOCAL nrBytes, recType  AS LONG
LOCAL pByte             AS BYTE PTR
LOCAL hexPtr            AS LONG
LOCAL rptCode           AS LONG
LOCAL bCtr              AS LONG
LOCAL I                 AS LONG


    rptCode = 0
    bCtr    = 1

    g_hBinFile = FREEFILE
    OPEN g_sBinFile FOR INPUT AS #g_hBinFile

    pByte = VARPTR(g_fileBuf)

    WHILE (1 = 1)

        LINE INPUT #g_hBinFile, sLine
        sLine = UCASE$(TRIM$(sLine))

        IF (LEN(sLine) = 0) THEN
        ' no more lines to process
            GOTO fnExit
        END IF

    ' the first character must be a colon
    '   if not, exit with an error
        IF (LEFT$(sLine, 1) <> ":") THEN
            rptCode = -1
            GOTO fnExit
        END IF

        byteCount   = substrHexToDec(sLine, 2, 2)
        recType     = substrHexToDec(sLine, 8, 2)

        IF (recType = 1) THEN
        ' end of file record. we are done
            GOTO fnExit
        END IF

        hexPtr = 10
        FOR I = 1 TO byteCount
            @pByte  = substrHexToDec(sLine, hexPtr, 2)
            pByte   += 1
            hexPtr  += 2

            bCtr    += 1
            IF (bCtr > 4096) THEN
            ' prevent a buffer overflow
                GOTO fnExit
            END IF
        NEXT I
    WEND

fnExit:
    CLOSE #g_hBinFile
    FUNCTION = rptCode

END FUNCTION


FUNCTION PBMAIN () AS LONG
LOCAL rtnVal            AS LONG

    IF (parseParams() = 0) THEN
        IF (g_usage = 1) THEN
            printUsage()
            GOTO pgmExit
        END IF


        IF (g_fileType = %FILEIS_HEX) THEN
            rtnVal = readHexFile()
            IF (rtnVal < 0) THEN
                STDOUT "Error in hex file"
                GOTO pgmExit
            END IF
        ELSE
            readBinFile()
        END IF

        writeMif()
    END IF

pgmExit:
    WAITKEY$


END FUNCTION
