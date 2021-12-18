
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
   
   slotsize        $6000
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
  
  banksize $6000
  banks $1
.endro

.emptyfill $FF

.background "adv_2.bin"

; huvideo playback stuff
;.unbackground $4069-$4000 $40B4-$4000
;.unbackground $4F32-$4000 $4F59-$4000
;.unbackground $4F32-$4000 $4F59-$4000
;.unbackground $4F89-$4000 $4FCF-$4000

; better yet, there's a massive chunk of unused code
; which seems to be an old iteration of the print routines
; that's based on the original system from yuna 1.
; let's just shove all our new stuff in there.
.unbackground $80F5-$4000 $8917-$4000

; old doPrintVramReadbacks
.unbackground $6D14-$4000 $6DEB-$4000

;===================================
; new stuff
;===================================

.define bytesPer1bppPattern 8
.define printNoReadBufferNumPatterns 4
.define printNoReadBufferNumRows 16
.define printNoReadBufferBytesPerRow 2
.define printNoReadBufferByteSize bytesPer1bppPattern*printNoReadBufferNumPatterns

;===================================
; old routines
;===================================

.define getOpArgByIndex $477E
.define saveFreeMPRsAndLoadScriptPages $4D36
.define restoreFreeMPRs $4D4B
.define stdVsyncWait $5B76
;.define printCurrentString $6C37
;.define delayAndSendNextChar $6C6E
; deleted
;.define doPrintVramReadbacks $6D14
.define prepQueuedChar $6EC5
.define convert1bppCharTo4bpp $7108
;.define printLineToStdTextBox $8950

;===================================
; old memory locations
;===================================

.define unindexedBlockPtrLo $2004
.define unindexedBlockPtrHi $2005
.define printSpeed $2683
.define scriptOpParamCount $278E
.define printPatternBuffer $2864
.define printPatternBufferByteSize bytesPerPattern*4
; buffer contains 4 patterns' worth of 1bpp data representing
; the next character to be printed
; (following standard bios font format,
; i.e. 2 bytes = 1 row of 16x16 char data)
.define printCompBuffer $28E4
.define printCompBufferByteSize 32
.define printPtrLo $2912
.define printPtrHi $2913
.define printXLo $2CDE
.define printXHi $2CDF
.define printYLo $2CE0
.define printYHi $2CE1

.define queuedCharCodepointLo $6C31
.define queuedCharCodepointHi $6C32
.define printRowShiftOnLo $6C33
.define printRowShiftOnHi $6C34
.define printParityFlagLo $6C35
.define printParityFlagHi $6C36

.define lineNum $8918
.define lineFlag $8919

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
; DEBUG
;==============================================================================

;===================================
; DEBUG: debug features on by default
;===================================

/*.bank 0 slot 0
.orga $4010
.section "force debug 1" overwrite
  jmp forceDebugOn
.ends

.bank 0 slot 0
.section "force debug 2" free
  forceDebugOn:
    ; debug flag goes from default 0 to 0xFF
    dec $27BB
    
    ; make up work
    stz $2682
    jmp $4013
.ends*/

;===================================
; DEBUG: boot to battle
;===================================

/*.bank 0 slot 0
.orga $4036
.section "force battle 1" overwrite
  ; target battle id
  ; (set bit 7 for debug features
  ; if main debug flag not already on)
  lda #$01
  ; write
  sta $FA
  ; run battle function
  jsr $4E8B
.ends*/

;===================================
; DEBUG: boot to scene
;===================================

/*.bank 0 slot 0
.orga $4036
.section "force scene 1" overwrite
  ; target scene id
  ; 00 = opening theme
  ; 01 = intro
  ; 02 = erika reports to mirage,
  ;      yuri insert song
  ; 03 = erika and yuna on ship?
  ; 04 = credits
  ; 05 = ending
  ; 06 = yuri+el-line megagattai
  lda #$02
  ; write
  sta $FA
  ; run scene function
  jsr $4E57
.ends*/

;===================================
; DEBUG: boot to space duck
;===================================

/*.bank 0 slot 0
.orga $4036
.section "force space duck 1" overwrite
  ; dummy?
  lda #$01
  ; write
  sta $FA
  ; run scene function
  jsr $4ED8
.ends*/

;===================================
; DEBUG: boot to star bowl
;===================================

/*.bank 0 slot 0
.orga $4036
.section "force star bowl 1" overwrite
  ; dummy?
  lda #$01
  ; write
  sta $FA
  ; run scene function
  jsr $4F0C
.ends*/

;==============================================================================
; disable use of CD_BASE
;==============================================================================

.bank 0 slot 0
.orga $40C4
.section "no CD_BASE 1" overwrite
  nop
  nop
  nop
.ends

;==============================================================================
; fix save menu bug
;==============================================================================

; in the original game, if "save" is chosen at a save prompt, but the player
; then cancels the save at the file selection menu by pressing button 1,
; the rcr interrupt is erroneously left disabled.
; the main consequence of this is that if the save prompt is not immediately
; followed by a widescreen "event" scene, the visual window will be completely
; blacked out until one does occur.

.bank 0 slot 0
.orga $4525
.section "save menu fix 1" overwrite
  jmp doSaveMenuFix
.ends

.bank 0 slot 0
.section "save menu fix 2" free
  doSaveMenuFix:
    cmp #$FF
    bne @notCancelled
    
    @cancelled:
      ; turn rcr interrupt on
      jsr $45BA
      ; resume normal logic
      jmp $4564
      
    @notCancelled:
      ; do normal logic
      jmp $4529
    
.ends

;==============================================================================
; allow dialogue wait skipping without debug mode on
;==============================================================================

.bank 0 slot 0
.section "dialogue wait off 1" free
  waitForDialogueAdpcm:
;    stz lastDialogueCancelled.w
    ; if skip was previously queued, force immediate cancellation
;    lda currentLineSkipQueued.w
;    bne @cancel
    -:
      ; HACK: do not allow dark queen adpcm to be skipped,
      ; since our subtitle system doesn't account for that possibility
      lda darkQueenAdpcmPlaying.w
      bne +
        ; check buttons triggered
        lda JOYTRG.w
        ; if button 1 pressed, stop ADPCM
        and #$01
        beq +
        @cancel:
          jsr AD_STOP
  ;        inc lastDialogueCancelled.w
          lda #$01
          sta lastDialogueCancelled.w
          ; drop through to the AD_STAT check
      +:
      
      jsr AD_STAT
      cmp #$00
      beq @done
        jsr stdVsyncWait
        bra -
    @done:
    jmp $4758
    
  waitForThingAdpcm:
    jsr waitForDialogueAdpcm
    ; this is called for non-dialogue material
    stz lastDialogueCancelled.w
    jmp $4758
  
  lastDialogueCancelled:
    .db $00
  
  doPromptWaitSkipCheck:
    ; decide if "heart" wait prompt should be skipped
    lda lastDialogueCancelled.w
    beq +
    @skipWait:
      ; !!! break call !!!
      pla
      pla
      jmp $4B69
    +:
    ; make up work
    jmp stdVsyncWait
  
  endPromptWait:
    stz lastDialogueCancelled.w
    ; zero this in case there is no text between this message
    ; and the next prompt
    stz currentLineSkipQueued.w
    
    ; make up work
    jmp $4BE2
.ends

; op 14
.bank 0 slot 0
.orga $4B21
.section "dialogue wait off 2" overwrite
  jsr waitForDialogueAdpcm
.ends

; op 15
.bank 0 slot 0
.orga $4B32
.section "dialogue wait off 3" overwrite
  jsr waitForDialogueAdpcm
.ends

.bank 0 slot 0
.orga $4B40
.section "dialogue wait off 4" overwrite
  jsr doPromptWaitSkipCheck
.ends

.bank 0 slot 0
.orga $4B54
.section "dialogue wait off 5" overwrite
  jsr doPromptWaitSkipCheck
.ends

.bank 0 slot 0
.orga $4B69
.section "dialogue wait off 6" overwrite
  jsr endPromptWait
.ends

; i was originally only going to allow skipping for regular dialogue,
; but what the hell, let's just do it for all adpcm clips
.bank 0 slot 0
.orga $938D
.section "dialogue wait off 7" overwrite
  jmp waitForThingAdpcm
.ends

;==============================================================================
; use new, expanded scene executable
;==============================================================================

.bank 0 slot 0
.orga $4E67
.section "new scene exe 1" overwrite
  ; src sector num
  lda #(newSceneExeSectorNum>>16)&255
  sta $FC
  lda #(newSceneExeSectorNum>>8)&255
  sta $FD
  lda #newSceneExeSectorNum&255
  sta $FE
.ends

.bank 0 slot 0
.orga $4E7F
.section "new scene exe 2" overwrite
  ; size in sectors
  lda #newSceneExeSectorSize
  sta $00F8
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
    .incbin "out/font/font.bin"
.ends

.bank 0 slot 0
.section "printing: font width table" free
  fontWidthTable:
    .incbin "out/font/fontwidth.bin"
.ends

.bank 0 slot 0
.section "printing: DTE dictionary" free
  dteDictionary:
    .incbin "out/script/script_dictionary.bin"
.ends

;===================================
; printCurrentString
;===================================

.bank 0 slot 0
.orga $6C37
;.section "printCurrentString 1" SIZE $37 overwrite
.section "printCurrentString 1" SIZE $9E overwrite
  printCurrentString:
    stz printSkipParity.w
    @loop:
      ; $F8-F9 = src pointer for current string
      lda printPtrLo.w
      sta $00F8
      lda printPtrHi.w
      sta $00F9
      ; fetch byte
      lda ($00F8)
      ; do nothing if terminator
;      cmp #code_end
      beq @done
      ; do nothing if linebreak
      cmp #code_linebreak
      beq @done
      ; if nonzero
        ; handle DTE sequence if any,
        ; returning replacement codepoint as needed
        jsr doDteCheck
        
        ; wait until it's time for next char to print
        ; (according to current print speed settings),
        ; allow queued character to get prepped at vblank,
        ; and send it to vram
        jsr delayAndSendNextChar
        
        ; increment srcptr if DTE not active
        lda dteActiveFlag.w
        bne @noSrcIncrement
          inc printPtrLo.w
          bne +
            inc printPtrHi.w
          +:
        @noSrcIncrement:
        bra @loop
    @done:
    rts 
  
  printSkipParity:
    .db $00
  
  currentLineSkipQueued:
    .db $00
  
  ; A = next char codepoint
  delayAndSendNextChar:
    pha
      ; do print delay between characters, if on and needed
      lda $2685.w
      beq +
      ; if fast-forward enabled
;      lda currentLineSkipQueued.w
;      bne @doFastParityCheck
        
        lda JOY.w
;        and #$01
        ; check for button 2 instead of 1 for fast-forward.
        ; there are several reasons i'm doing this:
        ; - it's more convenient overall than having to alternate between
        ;   pressing and holding button 1
        ; - it fixes an awkward issue where it's almost impossible
        ;   to avoid fast-forwarding unvoiced lines (because without the
        ;   delay from loading the new adpcm file, the game goes into the new
        ;   line right away and starts treating the button press that confirmed
        ;   the prompt as the fast-forward)
        ; - consistency with the previous game
        and #$02
        beq +
        ; if skip button pressed
        @doFastParityCheck:
          ; update and check wait parity
          lda printSkipParity.w
          eor #$01
          sta printSkipParity.w
          ; if parity became zero, skip wait;
          ; otherwise, do it
          ; (this caps fast-forward speed to a max of 2 chars per frame,
          ; which, combined with the removal of VRAM readbacks,
          ; is enough not to lag scenes or cause display artifacts)
          beq @waitDone
          bra @doWait
      +:
      ; if print speed zero (no delay), act same as if
      ; fast-forwarding, i.e. 2 chars per frame
      lda printSpeed.w
      ; double speed
      lsr
      beq @doFastParityCheck
      ; take one extra frame off of that.
      ; this matches up the timing of some lines better than
      ; just doubling.
      ; mafoo talked me into this one
      ; (after i said i wouldn't do it, of course)
      dea
      beq @doFastParityCheck
;      bne @charDelayLoop
;      ++:
;      bra @doWait
;      bra @doFastParityCheck
        @charDelayLoop:
          cmp #$01
          beq @doWait
            pha 
;              jsr doPrintSkipQueueCheck
;              bcc ++
;                pla
;                bra @doWait
;              ++:
              
              ; among other things, this waits for vsync
              jsr stdVsyncWait
            pla 
            dea
            bne @charDelayLoop
      @doWait:
      
;      jsr doPrintSkipQueueCheck
      
      ; wait until vsync so animations can advance
      jsr stdVsyncWait
      
      @waitDone:
    ; retrieve codepoint
    pla
    tay
    
    ; convert to font index
    sec
    sbc #fontBaseOffset
    ; look up width
    tax
    lda fontWidthTable.w,X
    ; add width to former parity flag (now subx)
    clc
    adc printParityFlagLo.w
    pha
      ; if > 8, set double-width transfer flag
      cmp #$08+1
      bcs +
        cla
      +:
      sta nextCharPrintIsDoubleWidth.w
      
      tya
      jsr doMovedPrintPrep
    
    ; retrieve next subx
    pla
    
    @subxCalcLoop:
      ; do nothing if next subx < 8
      cmp #$08
      bcc @subxCalcLoopDone
        ; advance X 1 tile
        inc printXLo.w
        bne +
          inc printXHi.w
        +:
        
        ; shift noread buffer left a pattern
        pha
          jsr shiftNoReadBufferLeft
        pla
        
        ; subx = low 3 bits of width result
  ;      and #$07
        ; subtract 8px and loop until result < 8
        ; (some characters have a width of 9px, so we can't assume
        ; a maximum of one increment despite the input glyphs only
        ; being 8px wide)
        sec
        sbc #$08
        bra @subxCalcLoop
    @subxCalcLoopDone:
    sta printParityFlagLo.w
    
    rts
  
  nextCharPrintIsDoubleWidth:
    .db $00
.ends

.bank 0 slot 0
.section "printCurrentString 2" free
  doMovedPrintPrep:
    ; prep next char
;      jsr doNewCharPrep
    sta queuedCharCodepointLo.w
    jsr prepQueuedChar
    
    ; disable timer interrupt
    ; (what's going on in there that could conflict with this?)
    lda #$04
    sta $1402.w
      ; look up target address in tilemap?
      jsr $6CD5
      ; do vram readbacks to $2864+
      ; (we're now buffering this in memory so we don't have to waste time
      ; doing a bunch of expensive vram readbacks)
;      jsr doPrintVramReadbacks
      ; set up old readback area with hardcoded pattern of background color
      ; (which is not color 0, hence the need for this)
      jsr setUpVramPrintBgColor
    ; reenable all interrupts
    lda #$00
    sta $1402.w
    
    ; convert 1bpp char data to 4bpp,
    ; storing result to $2864+ (merged with earlier vram readbacks?)
    jsr convert1bppCharTo4bpp
    ; do vram writes
    jsr $6DEC
    rts
  
/*  doPrintSkipQueueCheck:
    lda JOYTRG.w
    and #$01
    beq +
      inc currentLineSkipQueued.w
      sec
      rts
    +:
      clc
      rts */

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
.ends

.bank 0 slot 0
.section "printCurrentString 3" free
  printNoReadBuffer:
    printNoReadBufferUL:
      .ds bytesPer1bppPattern,$00
    printNoReadBufferUR:
      .ds bytesPer1bppPattern,$00
    printNoReadBufferLL:
      .ds bytesPer1bppPattern,$00
    printNoReadBufferLR:
      .ds bytesPer1bppPattern,$00
  
  ; OR contents of noread buf with comp buf and vice versa
  ; (both buffers are updated)
  composeNoReadBuffer:
    clx
    -:
      lda printCompBuffer.w,X
      ora printNoReadBuffer.w,X
      sta printCompBuffer.w,X
      sta printNoReadBuffer.w,X
      inx
;      inx
      cpx #printNoReadBufferByteSize
      bne -
    rts
  
  ; shift contents of noread buffer left a pattern,
  ; filling the right side with null bytes
  shiftNoReadBufferLeft:
    clx
    -:
      lda printNoReadBuffer+1.w,X
      sta printNoReadBuffer+0.w,X
      stz printNoReadBuffer+1.w,X
      inx
      inx
      cpx #printNoReadBufferByteSize
      bne -
    rts
  
  clearNoReadBuffer:
    tai zeroFiller,printNoReadBuffer,printNoReadBufferByteSize
    rts
  
  setUpVramPrintBgColor:
    .rept 4 INDEX count
      tii vramBgPattern,printPatternBuffer+(count*bytesPerPattern),bytesPerPattern
    .endr
    rts
  
  vramBgPattern:
    .rept 8
      .dw $FF00
    .endr
    .rept 8
      .dw $FFFF
    .endr
.ends

;===================================
; prepQueuedChar
;===================================

.bank 0 slot 0
.orga $5D1E
.section "no vsync prepQueuedChar 1" overwrite
  jmp $5D2F
.ends

.bank 0 slot 0
.orga $6ED7
.section "prepQueuedChar 1" overwrite
  jmp doNewFontLookup
;  jsr doNewFontLookup
;  jmp $6EF5
.ends

.bank 0 slot 0
.orga $6F33
.section "prepQueuedChar 2" overwrite
  ; old parity flag is now the right-shift amount;
  ; use it instead of a fixed value
;  ldy #$04
  tay
  nop
.ends

.bank 0 slot 0
.orga $6F46
.section "prepQueuedChar 3" overwrite
  jmp finishPrepQueuedChar
.ends

.bank 0 slot 0
.section "prepQueuedChar 4" free
  finishPrepQueuedChar:
    ; compose contents of noread buf with comp buf
    jsr composeNoReadBuffer
    
    ; make up work
    pla
    sta $FE
    jmp $6F49
.ends

.bank 0 slot 0
.orga $71CB
.section "no print pattern OR 1" overwrite
  ; do not OR with vram readback data, since we are no longer
  ; doing vram readbacks
;  ora ($FA)
  ; actually, we still need to set up the correct background color,
  ; so never mind
;  nop
;  nop
  
  ora ($FA)
.ends

;====
; INTERRUPT-SAFE BLOCK
;====


; what, really? only MPR2/3 are guaranteed here?
; well, whatever, let's just overwrite the supplmental glyph area
;.bank 0 slot 0
;.section "prepQueuedChar 3" free
.bank 0 slot 0
.orga $6FA8
.section "prepQueuedChar 5" SIZE $160 overwrite
  doDarkQueenSubDrawCheck:
    ; make up work
    sta $0000.w
    
    lda darkQueenAdpcmPlaying.w
    beq @done
      ; load needed banks
      tma #$10
      pha
      tma #$20
      pha
      tma #$40
      pha
        lda #$82
        tam #$10
        ina
        tam #$20
        ina
        tam #$40
        jsr doDarkQueenSubDrawCheck_out
      pla
      tam #$40
      pla
      tam #$20
      pla
      tam #$10
    @done:
    jmp $76CA
    
  ; NOTE: this is no longer called from vsync
  ; (it never needed to be in the first place),
  ; so it doesn't actually need to go in this block any more.
  ; but we don't need the space for anything else, so i'm leaving it.
  doNewFontLookup:
    ; uggggggggh
/*    tma #$10
    pha
    tma #$20
    pha
    tma #$40
    pha
      lda #$82
      tam #$10
      ina
      tam #$20
      ina
      tam #$40*/
  
      ; make up work
      ; get codepoint ("low byte", which is now the only byte)
      lda queuedCharCodepointLo.w
          
      ; subtract codepoint base to get font index
      sec
      sbc #fontBaseOffset
      
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
      lda #<printCompBuffer
      sta $FA
      lda #>printCompBuffer
      sta $FB
      
      ; copy from src to dst
      cly
      clx
      ; HACK: we happen to know we need MPR4 = $82 for the font here
  ;    tma #$10
  ;    pha
  ;      lda #$82
  ;      tam #$10
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
  ;    pla
  ;    tam #$10
      
  ;    @fontTransferCmd:
  ;    tii $0000,printCompBuffer,bytesPerRawFontChar
      
      ; pad unused lines
      ; (needed due to row shift that's done later)
      tai zeroFiller,printCompBuffer+(bytesPerRawFontChar*2),fontFillerSize
/*    pla
    tam #$40
    pla
    tam #$20
    pla
    tam #$10*/
    
    jmp $6EF5
  
  zeroFiller:
    .dw 0
  
;  newFontLookupTemp:
;    .dw 0
  
  doDarkQueenSyncCheck:
    lda darkQueenAdpcmPlaying.w
    beq @done
      ; decrement timer
      lda darkQueenAdpcmTimer+0.w
      bne +
        dec darkQueenAdpcmTimer+1.w
      +:
      dec darkQueenAdpcmTimer+0.w
      
      lda darkQueenAdpcmTimer+0.w
      ora darkQueenAdpcmTimer+1.w
      bne @done
      
      ; timer zero: do next event
      
      inc darkQueenMessageState.w
      lda darkQueenMessageState.w
      cmp #numDqMesStates
      beq @endSequence
        ; reload timer with next value
        asl
        tax
        lda dqMesTimerDelay+0.w,X
        sta darkQueenAdpcmTimer+0.w
        lda dqMesTimerDelay+1.w,X
        sta darkQueenAdpcmTimer+1.w
        bra @done
      @endSequence:
      ; turn off
;      jsr dqMes_turnSubsOff
      stz darkQueenAdpcmPlaying.w
    @done:
    ; make up work
    ply
    plx
    pla
    rts
  
  ; NOTE: it's probably obvious to anyone else, but all these resources
  ; that are accessed by doDarkQueenSyncCheck have to be in this interrupt-
  ; safe block. otherwise, they may get placed somewhere in memory that isn't
  ; guaranteed to be loaded during the vsync interrupt, resulting in
  ; doDarkQueenSyncCheck checking garbage variables (and setting them,
  ; if the garbage it reads has the necessary values).
  ; i make a note of this solely because i initially neglected to do this
  ; and only discovered the problem much later when a random sound effect
  ; started sporadically glitching out.
  ; be careful when you're working with interrupts!
  dqMesTimerDelay:
    .dw dqMes_sub0StartDelay
    .dw dqMes_sub1StartDelay
;    .dw dqMes_sub1EndDelay
    .dw dqMes_sub2StartDelay
    .dw dqMes_sub3StartDelay
    .dw dqMes_sub3EndDelay
  
  darkQueenMessageOn:
    .db $00
  darkQueenMessageState:
    .db $00
  darkQueenAdpcmPlaying:
    .db $00
  darkQueenAdpcmTimer:
    .dw $0000
.ends

;===================================
; script op 16 = print box
;===================================

.bank 0 slot 0
.orga $891A
.section "op16 1" SIZE $2A overwrite
  ; original routine: prints one line of text for each input argument
/*  lda scriptOpParamCount
  tax 
  ; A = target parameter number (1-based)
  lda #$01
  -:
    pha 
    phx 
      ; returns $FA = offset from start of block to target string?
      sta $00F8
      jsr getOpArgByIndex
      ; add to unindexed block base to get pointer to target string
      clc 
      lda $00FA
      adc $2004
      sta $00FA
      lda $00FB
      adc $2005
      sta $00FB
      ; print
      jsr printLineToStdTextBox
    plx 
    pla 
    inc 
    dex 
    bne -
  stz $00F8
  stz $00F9
  rts */
  
  scriptOp16:
    lda scriptOpParamCount
    tax 
    ; A = target parameter number (1-based)
    lda #$01
    ; get pointer to first arg = string pointer
    ; returns $FA = offset from start of block to target string
    sta $00F8
    jsr getOpArgByIndex
    
    ; add to unindexed block base to get pointer to target string
    clc 
    lda $00FA
    adc unindexedBlockPtrLo
    sta $00FA
    lda $00FB
    adc unindexedBlockPtrHi
    sta $00FB
    
    ; the standard print routine will now take care of linebreaks,
    ; so just call it once instead of in a loop
    jsr printLineToStdTextBox
    
    ; return zero = success
    stz $00F8
    stz $00F9
    rts 
.ends

/*.bank 0 slot 0
.section "op16 2" free
  
.ends*/

;===================================
; printLineToStdTextBox
;===================================

.bank 0 slot 0
.orga $8950
.section "printLineToStdTextBox 1" SIZE $66 overwrite
  printLineToStdTextBox:
    jsr saveFreeMPRsAndLoadScriptPages
    stz currentLineSkipQueued.w
      @loop:
        ; if lineFlag is set, preincrement lineNum and clear lineFlag
        lda lineFlag.w
        beq +
          inc lineNum.w
          stz lineFlag.w
        +:
        ; check line num for overflow?
        lda lineNum.w
        cmp #$04
        bcc +
          ; i'd imagine this scrolls the box up a line, but haven't checked.
          ; does this ever actually happen in the game, or is it a
          ; "just in case" like the automatic box break from the last game?
          jsr $89B6
          ; decrement line num
          dec lineNum.w
        +:
        
        ; some stuff moved out of this routine to make room
        jsr doStdTextBoxPrintInit
        
        ; do the actual printing
        jsr printCurrentString
        
        ; increment line num?
        ; how does this interact with the preincrement based on lineFlag [$8919]
        ; that occurs at the start of the routine?
        stz lineFlag.w
        inc lineNum.w
      
        ; printCurrentString returns $F8 = pointer to character at which
        ; it terminated printing.
        ; check if this is a linebreak;
        ; if so, continue with the next line.
        ; otherwise, assume it's the string terminator and stop printing.
        lda ($F8)
        cmp #code_linebreak
        bne @done
        
        ; increment past terminator
        inc $F8
        bne +
          inc $F9
        +:
        ; copy to $FA for next iteration
        lda $F8
;        sta printPtrLo.w
        sta $FA
        lda $F9
;        sta printPtrHi.w
        sta $FB
        
        bra @loop
      
    @done:
;    jsr restoreFreeMPRs
;    rts 
    jmp restoreFreeMPRs
.ends

.bank 0 slot 0
.section "printLineToStdTextBox 2" free
  doStdTextBoxPrintInit:
    lda #$20
    sta printYLo.w
    lda #$00
    sta printYHi.w
    ; reset target X to 0x22?
    lda #$22
    sta printXLo.w
    lda #$00
    sta printXHi.w
    ; Y? = (linenum * 2) + 0x33?
    clc 
    lda lineNum.w
    adc lineNum.w
    adc #$33
    sta printYLo.w
    ; reset char parity
    lda #$00
    sta printParityFlagLo.w
    lda #$00
    sta printParityFlagHi.w
    ; enable vertical row shift so text is more centered in box
    ; (note: i'm pretty sure nothing ever disables this, so it might as
    ; well have just been defaulted to on and left there)
    lda #$01
    sta printRowShiftOnLo.w
    lda #$00
    sta printRowShiftOnHi.w
    ; set printPtrLo to standard string srcptr
    lda $00FA
    sta printPtrLo.w
    lda $00FB
    sta printPtrHi.w
    
    ; clear noread buffer
    jsr clearNoReadBuffer
    
    rts
.ends

;===================================
; setUpForMenuOptionPrint:
; correct initial position for
; right-column options
;===================================

.bank 0 slot 0
.orga $8CDF
.section "setUpForMenuOptionPrint 1" overwrite
;  lda #$01

  ; original game puts this 4 pixels left of exact position needed
  ; for center of box due to its 12px width granularity.
  ; we have no such compunctions, so we position it where it logically
  ; belongs.
  ; except that screws with the existing allocation of tiles to the tilemap,
  ; so let's just not worry about it.
;  lda #$04
  ; we've now adjusted things so we have the full width of the box available,
  ; so we're instead moving the right column one pattern right
  lda #$00
  sta printParityFlagLo.w
.ends

.bank 0 slot 0
.orga $8CD5
.section "setUpForMenuOptionPrint 2" overwrite
  ; starting tile x-position of right options column
  lda #$2F+1
.ends

.bank 0 slot 0
.orga $8CF1
.section "setUpForMenuOptionPrint 3" overwrite
  jsr doMenuOptionPrintExtraSetup
.ends

.bank 0 slot 0
.orga $8CF1
.section "setUpForMenuOptionPrint 4" free
  doMenuOptionPrintExtraSetup:
    jsr clearNoReadBuffer
    
    ; make up work
    stz printYLo.w
    rts
.ends

;===================================
; recolorMenuOption:
; recolor entire width of option/box
; instead of omitting rightmost pattern
;===================================

.bank 0 slot 0
.orga $8ED9
.section "recolorMenuOption 1" overwrite
  ; number of tiles for full width
  ldx #$1B+1
.ends

.bank 0 slot 0
.orga $8EE2
.section "recolorMenuOption 2" overwrite
  ; number of tiles for half width
  ldx #$0D+1
.ends

;==============================================================================
; when printing, don't send two patterns in width if only one is needed
;==============================================================================

.bank 0 slot 0
.orga $6E02
.section "half-width print transfers 1" overwrite
  jmp doPrintHalfWidthCheckUpper
.ends

.bank 0 slot 0
.section "half-width print transfers 2" free
  doPrintHalfWidthCheckUpper:
    ; make up work
    jsr $6E7B
    
    ; check if half-width
    lda nextCharPrintIsDoubleWidth.w
    beq @noRightTransfer
      jmp $6E05
    @noRightTransfer:
      jmp $6E26
.ends

.bank 0 slot 0
.orga $6E4D
.section "half-width print transfers 3" overwrite
  jmp doPrintHalfWidthCheckLower
.ends

.bank 0 slot 0
.section "half-width print transfers 4" free
  doPrintHalfWidthCheckLower:
    ; make up work
    jsr $6E7B
    
    ; check if half-width
    lda nextCharPrintIsDoubleWidth.w
    beq @noRightTransfer
      jmp $6E50
    @noRightTransfer:
      jmp $6E7A
.ends

;==============================================================================
; send print patterns as block transfers
;==============================================================================

; this is just a speedup.
; the original game uses an extraordinarily slow byte-by-byte copy.
; it's so slow, in fact, that when we try to print two characters per frame
; to keep the translation on the same pace as the original game,
; we sometimes get visible artifacting as the game very slowly updates vram
; on a part of the screen that's currently being drawn.
; there appears to be no reason not to just use a block transfer here...
; though i'm not sure why they wasted so much time and effort setting up
; the byte-by-byte copy routine if it wasn't even needed...

.bank 0 slot 0
.orga $6EA7
.section "print pattern block transfer 1" SIZE $1E overwrite
  lda $290E.w
  sta doPrintPatternBlockTransfer@transferOp+1.w
  lda $290F.w
  sta doPrintPatternBlockTransfer@transferOp+2.w
  
  jmp doPrintPatternBlockTransfer
.ends

.bank 0 slot 0
.section "print pattern block transfer 2" free
  doPrintPatternBlockTransfer:
    @transferOp:
    tia $0000,$0002,bytesPerPattern
    rts
.ends

;==============================================================================
; allow use of rightmost pattern column of text box
;==============================================================================

;.define boxLine2StartVramAddr $7160
.define boxLine2StartVramAddr $6E00+($1C*2*bytesPerPattern/2)
.define boxPatternsPerTileRow $1B+1

.bank 0 slot 0
.orga $6CDB
.section "extra box col 1" overwrite
  ; number of patterns per row (looking up target address)
  ldx #$1B+1
.ends

/*.bank 0 slot 0
.orga $6D5E
.section "extra box col 2" overwrite
  ; number of patterns per row (vram readbacks L)
  adc #$1B+1
.ends

.bank 0 slot 0
.orga $6D88
.section "extra box col 3" overwrite
  ; number of patterns per row (vram readbacks R)
  adc #$1C+1
.ends */

.bank 0 slot 0
.orga $6E36
.section "extra box col 4" overwrite
  ; number of patterns per row (writing to vram L)
  adc #$1B+1
.ends

.bank 0 slot 0
.orga $6E60
.section "extra box col 5" overwrite
  ; number of patterns per row (writing to vram R)
  adc #$1C+1
.ends

.bank 0 slot 0
.orga $8A02
.section "extra box col 6" overwrite
  ; number of patterns to overwrite when clearing box vram
  ldx #$D8+8
.ends

.bank 0 slot 0
.orga $89BE
.section "extra box col 7" overwrite
  ; base vram address of second line of box
  ; (more autoscrolling)
  lda #<boxLine2StartVramAddr
  ldx #>boxLine2StartVramAddr
.ends

.bank 0 slot 0
.orga $89CC
.section "extra box col 8" overwrite
  ; number of tiles to copy for first 6 pattern rows of box
  ; (more autoscrolling)
;  ldy #$A2
  ldy #boxPatternsPerTileRow*6
.ends

.bank 0 slot 0
.orga $89E2
.section "extra box col 9" overwrite
  ; number of patterns in final line of text (not final tile row)
  ; (for some autoscrolling thing i hope is never used)
  ldy #$36+2
.ends

;==============================================================================
; replace hardcoded strings
;==============================================================================

;===================================
; no save data error
;===================================

.bank 0 slot 0
.orga $8F8D
.section "fix save data error 1" overwrite
  ; pointer to error message
  lda #<noSaveDataErrorMsg
  sta $FA
  lda #>noSaveDataErrorMsg
  sta $FB
.ends

.bank 0 slot 0
.section "fix save data error 2" free
  noSaveDataErrorMsg:
    .incbin "out/script/strings/main/adv-0x4F9F.bin"
.ends

;===================================
; backup memory errors
;===================================

.bank 0 slot 0
.orga $9982
.section "backup memory error 1" overwrite
  ; pointer to error message
  lda #<backupMemoryErrorMsg1
  sta $FA
  lda #>backupMemoryErrorMsg1
  sta $FB
  jmp printLineToStdTextBox
.ends

.bank 0 slot 0
.orga $99B2
.section "backup memory error 2" overwrite
  ; pointer to error message
  lda #<backupMemoryErrorMsg2
  sta $FA
  lda #>backupMemoryErrorMsg2
  sta $FB
  jmp printLineToStdTextBox
.ends

.bank 0 slot 0
.section "backup memory error 3" free
  backupMemoryErrorMsg1:
    .incbin "out/script/strings/main/adv-0x59DF.bin"
  backupMemoryErrorMsg2:
    .incbin "out/script/strings/main/adv-0x59F6.bin"
.ends

;===================================
; save/don't save prompt
;===================================

.bank 0 slot 0
.orga $44DE
.section "save prompt 1" overwrite
  ; pointer to error message
  lda #<savePromptMsg1
  sta $FA
  lda #>savePromptMsg1
  sta $FB
.ends

.bank 0 slot 0
.orga $44F5
.section "save prompt 2" overwrite
  ; pointer to error message
  lda #<savePromptMsg2
  sta $FA
  lda #>savePromptMsg2
  sta $FB
.ends

.bank 0 slot 0
.section "save prompt 3" free
  savePromptMsg1:
    .incbin "out/script/strings/main/adv-0x56F.bin"
  savePromptMsg2:
    .incbin "out/script/strings/main/adv-0x57A.bin"
.ends

;===================================
; debug menu "prompt"
;===================================

.bank 0 slot 0
.orga $96DA
.section "debug prompt 1" overwrite
  ; pointer to error message
  lda #<debugPromptMsg
  sta $FA
  lda #>debugPromptMsg
  sta $FB
.ends

.bank 0 slot 0
.section "debug prompt 2" free
  debugPromptMsg:
    .incbin "out/script/strings/main/adv-0x5718.bin"
.ends

;===================================
; save file names
;===================================

.bank 0 slot 0
.orga $8FF4
.section "save file name 1" overwrite
  clc
  lda $F8
  ; HACK: convert raw chapter number to digit and write to the position
  ; in the string where it belongs
  adc #fontDigitBaseOffset
  sta saveFileName_load+16.w
  jmp $9006
.ends

.bank 0 slot 0
.orga $9012
.section "save file name 2" overwrite
  clc
  lda $F8
  ; HACK: convert raw file number to digit and write to the position
  ; in the string where it belongs
  ; (+1 here so the file numbers are 1-based instead of 0-based)
  adc #fontDigitBaseOffset+1
  sta saveFileName_load+5.w
  jmp $9024
.ends

.bank 0 slot 0
.orga $904A
.section "save file name 3" overwrite
  clc
  lda $F8
  ; HACK: convert raw file number to digit and write to the position
  ; in the string where it belongs
  ; (+1 here so the file numbers are 1-based instead of 0-based)
  adc #fontDigitBaseOffset+1
  sta saveFileName_save+5.w
  jmp $905C
.ends

.bank 0 slot 0
.orga $902C
.section "save file name 4" overwrite
    lda #<saveFileName_load
    sta $00FA
    lda #>saveFileName_load
    sta $00FB
.ends

.bank 0 slot 0
.orga $9064
.section "save file name 5" overwrite
    lda #<saveFileName_save
    sta $00FA
    lda #>saveFileName_save
    sta $00FB
.ends

.bank 0 slot 0
.section "save file name 6" free
  saveFileName_load:
    .incbin "out/script/strings/main/adv-0x50AF.bin"
  saveFileName_save:
    .incbin "out/script/strings/main/adv-0x50C0.bin"
.ends

;==============================================================================
; dark queen ending message subtitles
;==============================================================================

;===================================
; load subtitle graphics when
; ENP.GRP is loaded
;===================================

.define numDqMesStates 5

; frame interval between each event in the subtitle sequence
.define dqMes_sub0StartDelay 2.631*60
.define dqMes_sub1StartDelay 2.374*60
.define dqMes_sub2StartDelay 6.376*60
.define dqMes_sub3StartDelay 3.483*60
.define dqMes_sub3EndDelay 5.088*60
;.define dqMes_sub1EndDelay 5.130*60
;.define dqMes_sub2StartDelay 6.367*60
;.define dqMes_sub2EndDelay 7.145*60

.define my_CD_READ $9B30

.define enpGrpFileSectorHi $01
.define enpGrpFileSectorMid $3D
.define enpGrpFileSectorLo $5A

.define darkQueenMsgSubtitleGrpSectorHi $00
.define darkQueenMsgSubtitleGrpSectorMid $2E
.define darkQueenMsgSubtitleGrpSectorLo $B2
.define darkQueenMsgSubtitleGrpSectorSize 8
.define darkQueenMsgSubtitleGrpDstPage $70

.define darkQueenTotalGrpDataSize $4000
.define darkQueenMsgByteSize $1000
.define darkQueenMsgPatternSize darkQueenMsgByteSize/bytesPerSpritePattern
.define darkQueenSubtitleSpriteCount 16
; 16 sprites, 8 bytes per entry
.define darkQueenSubtitleTotalSatSize darkQueenSubtitleSpriteCount*8

.define subtitleBaseVramTile $180
.define subtitleBaseVramAddr (subtitleBaseVramTile*bytesPerSpritePattern)/2
.define subtitleBaseY 192
.define subtitleBaseX 0

.define subtitlePalNum 10
.define subtitlePalOffset subtitlePalNum*16

.define subtitle0BasePat $E0
.define subtitle1BasePat $160
.define subtitle2BasePat $180
.define subtitle3BasePat $1C0

.define subtitle0VramAddr subtitle0BasePat*bytesPerSpritePattern/2
.define subtitle1VramAddr subtitle1BasePat*bytesPerSpritePattern/2
.define subtitle2VramAddr subtitle2BasePat*bytesPerSpritePattern/2
.define subtitle3VramAddr subtitle3BasePat*bytesPerSpritePattern/2

.bank 0 slot 0
.orga $7512
.section "dark queen end message 1" overwrite
  jsr doDarkQueenMessageCheck
.ends

.bank 0 slot 0
.section "dark queen end message 2" free
  doDarkQueenMessageCheck:
    ; check if the file we are about to load is ENP.GRP
    lda _CL
    cmp #enpGrpFileSectorHi
    bne @noMatch
    lda _CH
    cmp #enpGrpFileSectorMid
    bne @noMatch
    lda _DL
    cmp #enpGrpFileSectorLo
    beq @match
    @noMatch:
      jmp my_CD_READ
    @match:
    
    ; load file as normal
    jsr my_CD_READ
    
    ; flag message as occurring
    inc darkQueenMessageOn.w
    
    ; now load subtitles
    ; target = MPR6
    lda #06
    sta _DH
    lda #darkQueenMsgSubtitleGrpDstPage
    sta _BL
    lda #darkQueenMsgSubtitleGrpSectorHi
    sta _CL
    lda #darkQueenMsgSubtitleGrpSectorMid
    sta _CH
    lda #darkQueenMsgSubtitleGrpSectorLo
    sta _DL
    lda #darkQueenMsgSubtitleGrpSectorSize
    sta _AL
    jmp my_CD_READ
  
.ends

;===================================
; load subtitle graphics
;===================================

.bank 0 slot 0
.orga $58CC
.section "dark queen end message 3" overwrite
  jsr doDarkQueenGrpToVramCheck
.ends

.bank 0 slot 0
.section "dark queen end message 4" free
  subtitlePalette:
    .incbin "out/rsrc_raw/pal/subtitles.pal"
  
  doDarkQueenGrpToVramCheck:
    ; make up work
    jsr $57C8
    
    ; check if prepping dark queen message
    lda darkQueenMessageOn.w
    beq +
;      stz darkQueenMessageOn.w
      
      ; load subtitle sprites to vram
      tma #$20
      pha
      tma #$40
      pha
        lda #darkQueenMsgSubtitleGrpDstPage
        tam #$20
        ina
        tam #$40
        
;        lda #$00
;        ldx #$60
;        jsr EX_SETWRT
;        tia $A000,$0002,darkQueenTotalGrpDataSize
        
        lda #<subtitle0VramAddr
        ldx #>subtitle0VramAddr
        jsr EX_SETWRT
        tia $A000+(darkQueenMsgByteSize*0),$0002,darkQueenMsgByteSize
        
        lda #<subtitle1VramAddr
        ldx #>subtitle1VramAddr
        jsr EX_SETWRT
        tia $A000+(darkQueenMsgByteSize*1),$0002,darkQueenMsgByteSize
        
        lda #<subtitle2VramAddr
        ldx #>subtitle2VramAddr
        jsr EX_SETWRT
        tia $A000+(darkQueenMsgByteSize*2),$0002,darkQueenMsgByteSize
        
        lda #<subtitle3VramAddr
        ldx #>subtitle3VramAddr
        jsr EX_SETWRT
        tia $A000+(darkQueenMsgByteSize*3),$0002,darkQueenMsgByteSize
        
        ; palette
        sei
          lda #subtitlePalOffset
          sta vce_ctaLo.w
          ; target sprite palettes
          lda #$01
          sta vce_ctaHi.w
          ; copy colors to vce
          tia subtitlePalette,vce_ctwLo,bytesPerPaletteLine
        cli
      pla
      tam #$40
      pla
      tam #$20
    +:
    rts
.ends

;===================================
; set up subtitle sequence when
; dark queen adpcm triggered
;===================================

.bank 0 slot 0
.orga $9376
.section "dark queen end message 5" overwrite
  jmp doDarkQueenAdpcmCheck
.ends

.bank 0 slot 0
.section "dark queen end message 6" free
  doDarkQueenAdpcmCheck:
    lda darkQueenMessageOn.w
    beq +
      stz darkQueenMessageOn.w
      
      ; set up timer to first event
      lda #<dqMes_sub0StartDelay
      sta darkQueenAdpcmTimer+0.w
      lda #>dqMes_sub0StartDelay
      sta darkQueenAdpcmTimer+1.w
      
      inc darkQueenAdpcmPlaying.w
    +:
    jmp $4758
.ends

;===================================
; add extra subtitle handling logic
; to sync vector
;===================================

.bank 0 slot 0
.orga $5D55
.section "dark queen end message 7" overwrite
  jmp doDarkQueenSyncCheck
.ends

;===================================
; draw subtitle sprites when needed
;===================================

.bank 0 slot 0
.orga $76C7
.section "dark queen end message 9" overwrite
  jmp doDarkQueenSubDrawCheck
.ends

;.define subResetX subtitleBaseX+spriteAttrBaseX-(spritePatternW*2)
.define subResetX subtitleBaseX+spriteAttrBaseX
.define subLine2StartY subtitleBaseY+spriteAttrBaseY+spritePatternH

.bank 0 slot 0
.section "dark queen end message 10" free
  ; NOT the main routine for this -- see doDarkQueenSubDrawCheck for that.
  ; that has to go in the interrupt-safe block
  ; (otherwise, loading dungeons will crash the game).
  doDarkQueenSubDrawCheck_out:
    ; make up work
;    sta $0000.w
    
;    lda darkQueenAdpcmPlaying.w
;    beq @done
      ; check current state
      lda darkQueenMessageState.w
      ; do nothing if zero (first subtitle not yet started)
      beq @done
      ; do nothing if last subtitle ended
      cmp #numDqMesStates
      bcs @done

      ; reset work data from base data
      tii subtitleBaseData,subtitleWorkData,8
      
      ; look up base pattern
      dea
      asl
      tax
      lda basePatternTable+0.w,X
      sta subtitleWorkData+4.w
      lda basePatternTable+1.w,X
      sta subtitleWorkData+5.w
      
      ldx #darkQueenSubtitleSpriteCount
      -:
        tia subtitleWorkData,$0002,8
        
        ; increment count of sprites drawn
        inc $2980.w
        
        ; update x-pos
        lda subtitleWorkData+2.w
        clc
        adc #spritePatternW*2
        sta subtitleWorkData+2.w
        cla
        adc subtitleWorkData+3.w
        sta subtitleWorkData+3.w
      
        cpx #$08+1
        bne @notLineChange
          ; reset x-pos
          lda #<subResetX
          sta subtitleWorkData+2.w
          lda #>subResetX
          sta subtitleWorkData+3.w
          
          ; update y-pos
          lda #<subLine2StartY
          sta subtitleWorkData+0.w
          lda #>subLine2StartY
          sta subtitleWorkData+1.w
        @notLineChange:
        
        ; increment pattern
        ; (by 4 = 2 patterns, shifted one bit left)
        lda #4
        clc
        adc subtitleWorkData+4.w
        sta subtitleWorkData+4.w
        cla
        adc subtitleWorkData+5.w
        sta subtitleWorkData+5.w
        
        dex
        bne -
      
      ; add size to count of sprites already drawn
;      lda $2980.w
;      adc #darkQueenSubtitleSpriteCount
;      sta $2980.w
    @done:
    rts
;    jmp $76CA
  
  subtitleBaseData:
    ; y
    .dw subtitleBaseY+spriteAttrBaseY
    ; x
    .dw subtitleBaseX+spriteAttrBaseX
    ; pattern index
    .dw (subtitleBaseVramTile)<<1
    ; flags (single-height, double-width, high-priority) + palette
    .dw $0180|subtitlePalNum
  
  subtitleWorkData:
    .dw $0000
    .dw $0000
    .dw $0000
    .dw $0000
  
  basePatternTable:
    .dw subtitle0BasePat<<1
    .dw subtitle1BasePat<<1
    .dw subtitle2BasePat<<1
    .dw subtitle3BasePat<<1
.ends





