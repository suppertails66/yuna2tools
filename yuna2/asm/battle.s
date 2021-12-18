
;.include "sys/pce_arch.s"
;.include "base/macros.s"

.include "include/global.inc"

/*.memorymap
   defaultslot     0
   ; ROM area
   slotsize        $2000
   slot            0       $0000
   slot            1       $2000
   slot            2       $4000
   slot            3       $6000
   slot            4       $8000
   slot            5       $A000
   slot            6       $C000
   slot            7       $E000
.endme */

; could someone please rewrite wla-dx to allow dynamic bank sizes?
; thanks
.memorymap
   defaultslot     0
   
   slotsize        $5000
   slot            0       $4000
.endme

;.rombankmap
;  bankstotal $2
;  
;  banksize $6000
;  banks $1
;  banksize $2000
;  banks $1
;.endro

.rombankmap
  bankstotal $1
  
  banksize $5000
  banks $1
.endro

.emptyfill $FF

.background "battle_10A.bin"

; old getFontChar + supplmental glyphs = 0x1E2 bytes
.unbackground $748D-$4000 $766E-$4000
; old strings for yuna retry messages = 0x27F bytes
.unbackground $8251-$4000 $84CF-$4000
; unused extra space = 0x109 bytes
.unbackground $86F7-$4000 $87FF-$4000
; more unused extra space = 0x32C bytes
.unbackground $8CD4-$4000 $8FFF-$4000
;.unbackground $8EF7+8-$4000 $8FFF-$4000

;===================================
; old routines
;===================================

.define clearLineBufs $5DA8
.define writeSequentialBoxLineTilemap $5EB2
.define clearBox $5ECE
.define clearCompositionBuf $5EF5
;.define printLineBufs $5F13
;.define printChar $5FB0
.define outputVramFFPlane $604D
.define blockCopy $6726
.define waitForAdpcm $6FEA

;===================================
; old memory locations
;===================================

.define printXTemp $21
.define printVramPosLo $D0
.define printVramPosHi $D1
.define stringOpParamValue $2AC6
.define printLineCount $2ACB
.define charBuf $2B3B
.define compositionBuf $2B5B

;===================================
; new hardcoded strings
; (note: at top of this file due to
; containing additional auto-generated
; unbackground statements for old strings)
;===================================

/*.include "include/system_adv_strings_overwrite.inc"

.bank 0 slot 0
.section "system_adv static strings free" free
  .include "include/system_adv_strings.inc"
.ends

.bank 0 slot 0
.section "text compression 1" free
  dteDictionary:
    .incbin "out/script/script_dictionary.bin"
.ends
.define useDteDictionary 1 */

;==============================================================================
; INCLUDED PATCHES
;==============================================================================

/*;.define freeDataBank 3
;.define freeDataSlot 4

;.define ovl_addTo29_offset $80B6
;.define ovl_multTo29_offset $80F1
;.define ovlText_printChar_offset $6950
.define ovlText_fontLoadType fontLoadType_normal
.include "include/adv_ovlText.inc"
.include "overlay/text.s"

.include "include/adv_ovlAdvString.inc"
.include "overlay/adv_string.s"*/

;==============================================================================
; other modifications specific to this executable
;==============================================================================

;==============================================================================
; DEBUG
;==============================================================================

;==============================================================================
; misc
;==============================================================================

;================================
; button press skips adpcm clips
;================================

.bank 0 slot 0
.orga $6FED
.section "adpcm skip 1" overwrite
  jmp doAdpcmSkipCheck1
.ends

.bank 0 slot 0
.section "adpcm skip 2" free
  doAdpcmSkipCheck1:
    ; get joytrg
    lda $222D
    ; check if button 1 triggered this frame
    and #$01
    bne @stopAdpcm
    ; get joy
    lda $2228
    ; check if button 2 pressed
    and #$02
    beq +
    @stopAdpcm:
      jsr AD_STOP
    +:
    
    ; make up work
    jsr AD_STAT
    jmp $6FF0
.ends

;==============================================================================
; text printing
;==============================================================================

;===================================
; additional resources
;===================================

.bank 0 slot 0
.section "printing: font data" free
  fontData:
    .incbin "out/font/font_limited.bin"
.ends

.bank 0 slot 0
.section "printing: font width table" free
  fontWidthTable:
    .incbin "out/font/fontwidth_limited.bin"
.ends

.bank 0 slot 0
.section "printing: DTE dictionary" free
  dteDictionary:
    .incbin "out/script/script_dictionary.bin"
.ends

;===================================
; printString
;===================================

.bank 0 slot 0
.orga $5C7B
.section "printString 1" SIZE $12D overwrite
  printString:
    lda $F9
    pha 
    lda $F8
    pha 
      jsr clearLineBufs
    pla 
    sta $F8
    pla 
    sta $F9
    @doNextLine:
    lda printLineCount.w
    cmp #$03
    bcs @allLinesFilled
    ; if
      inc printLineCount.w
      ; compare against ORIGINAL, UNINCREMENTED line count
      cmp #$01
      beq @onLine1
        cmp #$02
        beq @onLine2
      @onLine0:
        stz $2ACC.w
        lda #$CC
        sta $22
        lda #$2A
        sta $23
        lda #$CD
        sta $24
        lda #$2A
        sta $25
        lda #$24
        sta $26
        lda #$00
        sta $27
        jsr blockCopy
        clx 
        bra @charProcessing
      @onLine1:
        stz $2AF1.w
        lda #$F1
        sta $22
        lda #$2A
        sta $23
        lda #$F2
        sta $24
        lda #$2A
        sta $25
        lda #$24
        sta $26
        lda #$00
        sta $27
        jsr blockCopy
        ldx #$25
        bra @charProcessing
    ; else if all lines filled?
    @allLinesFilled:
      ; autoscroll?
      jsr EX_VSYNC
      tii $2AF1,$2ACC,$0025
      tii $2B16,$2AF1,$0025
    @onLine2:
      stz $2B16.w
      lda #$16
      sta $22
      lda #$2B
      sta $23
      lda #$17
      sta $24
      lda #$2B
      sta $25
      lda #$24
      sta $26
      lda #$00
      sta $27
      jsr blockCopy
      ldx #$4A
    @charProcessing:
    cly 
    ; loop
    @charProcessingLoop:
      ; fetch char
      lda ($00F8),Y
      sta $2ACC.w,X
      ; terminator?
;      cmp #$00
;      beq @end
      ; special op? (including terminator)
      cmp #fontBaseOffset
      bcs @isLiteral
        ; use op jump table
        ; (X is in use so we can't use the shortcut command)
        phx
          asl
          tax
          lda opJumpTable.w,X
          sta @opJumpCmd+1.w
          lda opJumpTable+1.w,X
          sta @opJumpCmd+2.w
        plx
        @opJumpCmd:
        jmp $0000.w
        
      ; backslash?
;      cmp #$5C
;      beq [$5D30]
      ; space?
      ; acts as terminator?
;      cmp #$20
;      beq @lineEnd

      @isLiteral:
      iny 
      inx 
      @lineFullCheck:
      ; forcibly terminate string if a line exceeds 40 bytes?
      cpy #$29
      bne @charProcessingLoop
    @end:
    ; append terminator to current position
    cla 
    sta $2ACC.w,X
    ; do actual printing?
    jsr printLineBufs
    rts 

  ;=====
  ; jump table for string ops
  ;=====
  
  opJumpTable:
    ; 00 = terminator
    .dw printString@end
    ; 01 = \n
    .dw printOpN
    ; 02 = \l
    .dw printOpL
    ; 03 = \s
    .dw printOpS
    ; 04 = \u
    .dw printOpU
    ; 05 = \p
    .dw printOpP
    ; 06 = \w
    .dw printOpW

  ;=====
  ; op 01: newline
  ;=====
  
  printOpN:
    bsr doLinebreak
    jmp printString@doNextLine
  
  doLinebreak:
    ; advance src
/*    tya 
    ina
    clc 
    adc $F8
    sta $F8
    bcc +
      inc $F9
    +:
    dey */
;    jsr advanceStringSrcPtr
    tya
    ina
    clc
    adc $F8
    sta $F8
    bcc +
      inc $F9
    +:
    cly
    
    lda $F9
    pha 
    lda $F8
    pha 
    ; print current line
      jsr printString@end
    pla 
    sta $F8
    pla 
    sta $F9
    rts 

  ;=====
  ; op 02: \l
  ;=====
  
  printOpL:
    ; handler: "\L"
    ; ?
    ; 2-digit param?
;    jsr $5E4F
    jsr fetchStringParamByteSpecial
    ; asdubjhldjgkb
    dey
    bsr doLinebreak
    phy 
    lda $F9
    pha 
    lda $F8
    pha 
      ; ?
      ; print delay?
      jsr $61A7
      ; check param
      lda stringOpParamValue.w
      cmp #$80
      beq +
      ; if returned value is not 0x80 (from "++")
        jsr waitForAdpcm
        lda stringOpParamValue.w
        clc 
        adc $2AC8.w
        sta $2AC8.w
        lda stringOpParamValue+1.w
        adc $2AC9.w
        sta $2AC9.w
        ; this may do something and a frame delay
        jsr $6260
      +:
      jsr clearLineBufs
    pla 
    sta $F8
    pla 
    sta $F9
    ply 
    jmp printString@doNextLine
  
  ; this is called in outside code a lot and i don't feel like
  ; fixing every reference, so the section is split around it
;  clearLineBufs:
;    jsr EX_VSYNC
;    ; clear line buffers
;    stz $2ACC.w
;    tii $2ACC,$2ACD,$006E
;    stz printLineCount.w
;    rts 
    
.ends

.bank 0 slot 0
.orga $5DB9
.section "printString 2" SIZE $F9 overwrite
    
  ; the way the original game handles this is so nonsensical
  ; that i gave up and did it my own way
/*  fetchStringParamByteSpecial:
    stz stringOpParamValue+1.w
    iny
    lda ($F8),Y
    sta stringOpParamValue.w
    
    ; if param exceeds 48, subtract 100
    cmp #$31
    bcc +
      lda #$9C
      clc
      adc stringOpParamValue.w
      sta stringOpParamValue.w
      dec stringOpParamValue+1.w
    +:
    bra advanceStringSrcPtr
    
  fetchStringParamByte:
    stz stringOpParamValue+1.w
    iny
    lda ($F8),Y
    sta stringOpParamValue.w
    ;!!!!! drop through !!!!!
  advanceStringSrcPtr:
    tya 
    ina
    clc 
    adc $F8
    sta $F8
    bcc +
      inc $F9
    +:
;    dey 
    rts */
  fetchStringParamByteSpecial:
    stz stringOpParamValue+1.w
    iny
    lda ($F8),Y
    sta stringOpParamValue.w
    ; if 0x80, ignore below check
    cmp #$80
    beq +
    
    ; if param exceeds 48, subtract 100
    cmp #$31
    bcc +
      lda #$9C
      clc
      adc stringOpParamValue.w
      sta stringOpParamValue.w
      dec stringOpParamValue+1.w
    +:
    bra advanceStringSrcPtrBy2
    
  fetchStringParamByte:
    stz stringOpParamValue+1.w
    iny
    lda ($F8),Y
    sta stringOpParamValue.w
    ;!!!!! drop through !!!!!
  advanceStringSrcPtrBy2:
    inc $F8
    bne +
      inc $F9
    +:
    dey
    ;!!!!! drop through !!!!!
  advanceStringSrcPtr:
    inc $F8
    bne +
      inc $F9
    +:
    rts

  ;=====
  ; op 03: \s
  ;=====
  
  printOpS:
    ; why did they copy this block every single time
    ; instead of just making a subroutine
/*    tya 
    inc 
    clc 
    adc $F8
    sta $F8
    bcc +
      inc $00F9
    +:
    dey */
    bsr advanceStringSrcPtr
    inc $2BBB.w
    jmp printString@lineFullCheck

  ;=====
  ; op 04: \u
  ;=====
  
  printOpU:
/*    tya 
    inc 
    clc 
    adc $F8
    sta $F8
    bcc +
      inc $F9
    +:
    dey */
    bsr advanceStringSrcPtr
    inc $2BBC.w
    jmp printString@lineFullCheck

  ;=====
  ; op 05: \p
  ;=====
  
  printOpP:
    ; handler: "\P"
    ; psg sound effect?
    ; read in two digits for id?
/*    lda $F9
    pha 
    lda $F8
    pha 
      jsr read2DigitParam
      and #$1F
      phy 
        jsr $7811
      ply 
    pla 
    sta $F8
    pla 
    sta $F9
    tya 
    dec 
    clc 
    adc $00F8
    sta $00F8
    bcc [$5E1A]
      inc $00F9
    dey */
    
    jsr fetchStringParamByte
    
    lda $F9
    pha 
    lda $F8
    pha 
      lda stringOpParamValue.w
      and #$1F
      phy 
        jsr $7811
      ply 
    pla 
    sta $F8
    pla 
    sta $F9
    
    jmp printString@lineFullCheck

  ;=====
  ; op 06: \w
  ;=====
  
  printOpW:
    ; handler: "\W"
    ; ???
    ; 2-digit param?
/*    jsr read2DigitParam [$5E8E]
    lda $2AC6
    sta $2BBD
    tya 
    dec 
    clc 
    adc $00F8
    sta $00F8
    bcc [$5E32]
      inc $00F9
    dey */
    jsr fetchStringParamByte
    lda stringOpParamValue.w
    sta $2BBD.w
    jmp printString@lineFullCheck
    
.ends

;===================================
; printLineBufs
;===================================

.bank 0 slot 0
.orga $5F13
.section "printLineBufs 1" SIZE $13A overwrite

  printLineBufs:
/*    lda printLineCount.w
    beq @line0
    cmp #$01
    bne +
    ; 0 or 1 lines: clear box before starting
    @line0:
      jsr clearBox
      ; this happens in printBoxLine regardless
;      jsr clearCompositionBuf
      
      cla
      bsr printBoxLine
    +:
    
    lda printLineCount.w
    cmp #$02
    bcc @noLine1
      lda #$01
      bsr printBoxLine
    @noLine1:
    
    ; why is this done unconditionally??
    lda #$02
    bsr printBoxLine */
    
    ; the original logic above for some reasons redraws line 2
    ; every time line 3 is drawn.
    lda printLineCount.w
    beq @line0
    cmp #$01
    bne +
    ; 0 or 1 lines: clear box before starting
    @line0:
      jsr clearBox
      cla
      bsr printBoxLine
    +:
    
    lda printLineCount.w
    cmp #$02
    ; this is a bcc in the original.
    ; why??
    ; maybe it's related to the box autoscrolling feature...
    ; but that's never actually used
    bne @noLine1
      lda #$01
      bsr printBoxLine
    @noLine1:
    
    ; why is this done unconditionally??
    lda #$02
    bsr printBoxLine
    
    rts 
  
  ; A = line num (0, 1, or 2)
  printBoxLine:
    ; set initial src/dst pos
    asl
    tax
    
    lda printBoxLine_initialVramPosTable.w,X
    sta printVramPosLo
    lda printBoxLine_initialSrcTable.w,X
    sta fetchChar@srcGetCmd+1.w
    
    lda printBoxLine_initialVramPosTable+1.w,X
    sta printVramPosHi
    lda printBoxLine_initialSrcTable+1.w,X
    sta fetchChar@srcGetCmd+2.w
    
    ; clear composition buffer
    jsr clearCompositionBuf
    
    stz printXTemp
    jsr EX_VSYNC
    clx
    @printLoop:
      ; fetch next char
      jsr fetchChar
      ; done if terminator
      beq @done
      
      ; print this character
      phx
        bsr printChar
      plx
      
      ; don't overrun src buffer
      cpx #$24
      bne @printLoop
    @done:
    rts
  
    printBoxLine_initialVramPosTable:
      .dw $75E0
      .dw $7940
      .dw $7CA0
  
    printBoxLine_initialSrcTable:
      .dw $2ACC
      .dw $2AF1
      .dw $2B16
  
  ; A = char id
  printChar:
    ; subtract codepoint base to get font index
    sec
    sbc #fontBaseOffset
    ; save font index
    pha
      ; load raw char data to buffer
      jsr doNewFontLookup
      
      ; right-shift input data by printXTemp
      lda printXTemp
      beq @shiftDone
        clx
        @rowLoop:
          ldy printXTemp
          lda charBuf+0.w,X
          @shiftLoop:
            lsr
            ror charBuf+1.w,X
            dey
            bne @shiftLoop
          sta charBuf+0.w,X
          inx
          inx
          cpx #rawFontCharH*fullFontCharBytesPerLine
          bne @rowLoop
      @shiftDone:
      
      ; composite with next pattern
      jsr compositeNextPattern
      
      ; send to vram
      lda printVramPosLo
      ldx printVramPosHi
      jsr EX_SETWRT
      ; pattern 0 (UL)
      jsr outputVramFFPlane
      tia compositionBuf+($10*0),$0002,$0010
      ; pattern 1 (LL)
      jsr outputVramFFPlane
      tia compositionBuf+($10*1),$0002,$0010
      ; pattern 2 (UR)
      jsr outputVramFFPlane
      tia compositionBuf+($10*2),$0002,$0010
      ; pattern 3 (LR)
      jsr outputVramFFPlane
      tia compositionBuf+($10*3),$0002,$0010
      
    ; restore char id
    pla
    
    ; get char width
    tax
    lda fontWidthTable.w,X
    ; add to printXTemp
    clc
    adc printXTemp
    
    ; check if pattern update needed
    @patternUpdateLoop:
      cmp #patternW
      bcc @patternUpdateDone
      
      pha
        ; copy patterns 2-3 to 0-1
        tii compositionBuf+($10*2),compositionBuf+($10*0),$0020
        ; blank out patterns 2-3
        tai zeroFiller,compositionBuf+($10*2),$0020
        
        ; increment dst pattern
        lda printVramPosLo
        clc
        adc #bytesPerPattern
        sta printVramPosLo
        bcc +
          inc printVramPosHi
        +:
      pla
      
      ; subtract pattern width from x and repeat until less than 8
      sec
      sbc #patternW
      bra @patternUpdateLoop
    @patternUpdateDone:
    sta printXTemp
    
    rts
  
.ends

.bank 0 slot 0
.section "printLineBufs 2" free
  
  fetchChar:
    @srcGetCmd:
    lda $0000.w,X
    ; done if null
    beq @done
      ; handle DTE sequence if any,
      ; returning replacement codepoint as needed
      jsr doDteCheck
      
      pha
        ; increment srcptr if DTE not active
        lda dteActiveFlag.w
        bne @noSrcIncrement
          inx
        @noSrcIncrement:
      pla
    @done:
    rts

  ; A = next raw byte
  ; return A = next actual char to print after accounting for DTE encoding.
  ; dteActiveFlag will be made nonzero if starting a new sequence.
  doDteCheck:
    ; check if a dte sequence
    cmp #code_dteBase
    bcc @done
      ; this is a dte sequence
      sec
      sbc #code_dteBase
      phx
        ; X = DTE char id *2
        ; WARNING: implicitly limits dictionary size to 0x80 entries
        asl
        tax
        
        ; toggle and check DTE flag:
        ; if set after toggle, we're starting the sequence.
        ; if unset after toggle, we're ending it.
        lda dteActiveFlag.w
        eor #$01
        sta dteActiveFlag.w
        bne +
          ; ending sequence: target second char of dictionary entry
          inx
        +:
        
        ; get target char
        lda dteDictionary.w,X
      plx
    @done:
    rts
  
  dteActiveFlag:
    .db $00
  
  ; A = font index
  doNewFontLookup:
    ; subtract codepoint base to get font index
;    sec
;    sbc #fontBaseOffset
    
    ; multiply font index by 10 to get offset into font data
    stz $F9
    ; *2 (save for later)
    ; WARNING: only the low byte is saved;
    ; we are implicitly assuming font indices are capped at 0x7F
    asl
    pha
      rol $F9
      ;*4
      asl
      rol $F9
      ; *8
      asl
      rol $F9
      sta $F8
    pla
    ; add *2 to *8 to get *10
    clc
    adc $F8
    sta $F8
    cla
    adc $F9
    sta $F9
    
    ; add base address of font
    lda #<fontData
    clc
    adc $F8
    sta $F8
    lda #>fontData
    adc $F9
    sta $F9
    
    ; set up dst
    lda #<charBuf
    sta $FA
    lda #>charBuf
    sta $FB
    
    ; copy from src to dst
    cly
    clx
    @copyLoop:
      ; fetch from src
      lda ($F8),Y
      
      sxy
        ; write to dst
        sta ($FA),Y
        iny
        ; write zero byte for right half of pattern
        ; (input data is 8px wide, output is 16px)
        cla
        sta ($FA),Y
        iny
      sxy
      
      ; repeat for all real rows
      iny
      cpy #bytesPerRawFontChar
      bne @copyLoop
    
    ; pad unused lines
    ; FIXME: not needed here?
;    tai zeroFiller,charBuf+(bytesPerRawFontChar*2),fontFillerSize
    
    rts
  
  zeroFiller:
    .dw 0
  
  compositeNextPattern:
    ; src
    lda #<charBuf
    sta $D8
    lda #>charBuf
    sta $D9
    ; dst
    lda #<compositionBuf
    sta $D6
    lda #>compositionBuf
    sta $D7
    
    ; left half
    ldy #$00
    -:
      lda ($D8),Y
      ; we shift the input down a row?
      iny
      ora ($D6),Y
      sta ($D6),Y
      ; second bitplane?
      iny
      sta ($D6),Y
      ; repeat for all the lines we actually use
      cpy #rawFontCharH*fullFontCharBytesPerLine
      bne -
    
    ; target right half
    ; src
    inc $D8
    bne +
      inc $D9
    +:
    ; dst
    lda $D6
    clc
    adc #$20
    sta $D6
    bcc +
      inc $D7
    +:
    
    ; copy right half
    ldy #$00
    -:
      lda ($D8),Y
      ; we shift the input down a row?
      iny
      ora ($D6),Y
      sta ($D6),Y
      ; second bitplane?
      iny
      sta ($D6),Y
      ; repeat for all the lines we actually use
      cpy #rawFontCharH*fullFontCharBytesPerLine
      bne -
    
    rts
  
.ends

;==============================================================================
; replacements for hardcoded strings
;==============================================================================

;===================================
; debug battle retry message
;===================================

.bank 0 slot 0
.orga $481F
.section "battle debug retry 1" overwrite
  lda #<battleDebugRetryStr
  sta $F8
  lda #>battleDebugRetryStr
  sta $F9
.ends

.bank 0 slot 0
.section "battle debug retry 2" free
  battleDebugRetryStr:
    .incbin "out/script/strings/battle/battle-misc-0x2FF9.bin"
.ends

;===================================
; battle restart messages
;===================================

.bank 0 slot 0
.orga $81F1
.section "battle retry 1" overwrite
  ; pointer table to retry strings for each battle (4 per set).
  ; each time a battle is lost and retried, the next successive string
  ; in the group is shown (with the fourth one repeating indefinitely).
  ; though the fourth string is always set to the same as the third one,
  ; so it's basically pointless.

  ; group 0
  .dw battleRetryStr8251
  .dw battleRetryStr8284
  .dw battleRetryStr82C1
  .dw battleRetryStr82C1

  ; group 1
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 2
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 3
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 4
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 5
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 6
  .dw battleRetryStr82E4
  .dw battleRetryStr830F
  .dw battleRetryStr8352
  .dw battleRetryStr8352

  ; group 7
  .dw battleRetryStr838F
  .dw battleRetryStr83C2
  .dw battleRetryStr83E5
  .dw battleRetryStr83E5

  ; group 8
  .dw battleRetryStr838F
  .dw battleRetryStr83C2
  .dw battleRetryStr83E5
  .dw battleRetryStr83E5

  ; group 9
  .dw battleRetryStr838F
  .dw battleRetryStr83C2
  .dw battleRetryStr83E5
  .dw battleRetryStr83E5

  ; group 10
  .dw battleRetryStr841A
  .dw battleRetryStr845F
  .dw battleRetryStr8494
  .dw battleRetryStr8494

  ; group 11
  .dw battleRetryStr841A
  .dw battleRetryStr845F
  .dw battleRetryStr8494
  .dw battleRetryStr8494
.ends

.bank 0 slot 0
.section "battle retry 2" free
  battleRetryStr8251:
    .incbin "out/script/strings/battle/battle-misc-0x4251.bin"
  battleRetryStr8284:
    .incbin "out/script/strings/battle/battle-misc-0x4284.bin"
  battleRetryStr82C1:
    .incbin "out/script/strings/battle/battle-misc-0x42C1.bin"
  battleRetryStr82E4:
    .incbin "out/script/strings/battle/battle-misc-0x42E4.bin"
  battleRetryStr8352:
    .incbin "out/script/strings/battle/battle-misc-0x4352.bin"
  battleRetryStr83C2:
    .incbin "out/script/strings/battle/battle-misc-0x43C2.bin"
  battleRetryStr83E5:
    .incbin "out/script/strings/battle/battle-misc-0x43E5.bin"
  battleRetryStr830F:
    .incbin "out/script/strings/battle/battle-misc-0x430F.bin"
  battleRetryStr838F:
    .incbin "out/script/strings/battle/battle-misc-0x438F.bin"
  battleRetryStr841A:
    .incbin "out/script/strings/battle/battle-misc-0x441A.bin"
  battleRetryStr845F:
    .incbin "out/script/strings/battle/battle-misc-0x445F.bin"
  battleRetryStr8494:
    .incbin "out/script/strings/battle/battle-misc-0x4494.bin"
.ends




