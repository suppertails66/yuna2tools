
;.include "sys/pce_arch.s"
;.include "base/macros.s"

.include "include/global.inc"
.include "include/scene_common.inc"

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
   
;   slotsize        $2800
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
  
;  banksize $2800
  banksize $6000
  banks $1
.endro

.emptyfill $FF

.background "scene_main_32.bin"

;.unbackground $5A15+8-$4000 $5FFF-$4000
;.unbackground $64D4+8-$4000 $67FF-$4000

.define reservedAreaSize $100

; clock palette + graphics for unused loading animation,
; plus end-of-sector filler = $A0B bytes
;.unbackground $55F5-$4000 $5FFF-$4000
.unbackground $55F5+reservedAreaSize-$4000 $5FFF-$4000
; end-of-sector filler = $32C bytes
.unbackground $64D4-$4000 $67FF-$4000
; expansion
;.unbackground $6800-$4000 $9FFF-$4000
; reserve last 0x1000 bytes for subtitles
.unbackground $6800-$4000 $8FFF-$4000

;===================================
; routines
;===================================

.define my_CD_READ $6000

;===================================
; memory
;===================================

.define stdSatPtrAddrLo $2214
.define stdSatPtrAddrHi $2215

.define stdRcrStateVal $280B
.define cropUpperY $280D
.define cropLowerY $280E

.define currentSpriteYLo $28C1
.define currentSpriteYHi $28C2
.define currentSpriteXLo $28C3
.define currentSpriteXHi $28C4
.define currentSpritePatternLo $28C5
.define currentSpritePatternHi $28C6
.define currentSpriteFlagsLo $28C7
.define currentSpriteFlagsHi $28C8

;===================================
; constants
;===================================

.define spriteCropCutoffTriggerUpperTop 8
.define spriteCropCutoffTriggerUpperBottom spriteCropCutoffTriggerUpperTop+32
.define spriteCropCutoffTriggerLowerBottom 224
.define spriteCropCutoffTriggerLowerTop spriteCropCutoffTriggerLowerBottom-32

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

;================================
; skip all scenes
;================================

; initial value
/*.bank 0 slot 0
.orga $406A
.section "debug scene skip 1" overwrite
  nop
  nop
  nop
.ends*/

;==============================================================================
; misc
;==============================================================================

;================================
; HACK: "fix" medanfen emulation errors 
;================================

; mednafen apparently does not handle "out of range" rcr interrupt
; values properly. when setting crop parameters, the game occasionally
; uses a lower bound of line 0xFF to mean "no lower crop".
; however, due to mednafen's incorrect handling, this ends up blacking out
; the entire frame.
; we can work around this simply by writing 0xF0 instead
; (which is used elsewhere and has the same effect without being out of the
; correctly emulated range)

.define mednafenCropFixLineNum $F0

; initial value
.bank 0 slot 0
.orga $4036
.section "mednafen crop fix 1" overwrite
  lda #mednafenCropFixLineNum
  sta cropLowerY
  nop
.ends

; ?
.bank 0 slot 0
.orga $4CDC
.section "mednafen crop fix 2" overwrite
  lda #mednafenCropFixLineNum
  sta cropLowerY
  nop
.ends

; forcibly do not allow scripts to set a lower bound below
; the value that works in mednafen

.bank 0 slot 0
.orga $5213
.section "mednafen crop fix 3" overwrite
  jmp forceLowerCropInRange
.ends

.bank 0 slot 0
.section "mednafen crop fix 4" free
  forceLowerCropInRange:
    cmp #mednafenCropFixLineNum
    bcc +
      lda #mednafenCropFixLineNum
    +:
    ; make up work
    sta cropLowerY
    jmp $5216
.ends

/*.bank 0 slot 0
.orga $520D
.section "mednafen crop fix 5" overwrite
  jmp forceUpperCropInRange
.ends

.bank 0 slot 0
.section "mednafen crop fix 6" free
  forceUpperCropInRange:
    lda #01
    ; make up work
    sta cropUpperY
    jmp $5210
.ends */

;================================
; don't load unused clock animation whenever a loading transition occurs
; (we've overwritten it with new stuff anyway)
;================================

; initial value
.bank 0 slot 0
.orga $4FB3
.section "no clock anim 1" overwrite
  jmp $4FD0
.ends

;==============================================================================
; ensure fade effects do not interfere with subtitles
;==============================================================================

;================================
; fade effect does a block transfer of nominal palette to true in memory.
; since this is uninterruptable, it can interfere with raster interrupt timing,
; so we're breaking it down into smaller chunks.
;================================

.bank 0 slot 0
.orga $470E
.section "fade palette transfer split 1" overwrite
  jmp splitFadePalTransfer
.ends

.bank 0 slot 0
.section "fade palette transfer split 2" free
  splitFadePalTransfer:
    .rept 8 INDEX count
;      tii $3800,$3C00,$0400
      tii $3800+($80*count),$3C00+($80*count),$0080
    .endr
    
    jmp $4715
  
  splitFadeInFromBlackPalTransfer:
;    tii $3C00,$3C01,$03FF
    .rept 7 INDEX count
      tii $3C00+($80*count),$3C01+($80*count),$0080
    .endr
    tii $3C00+($80*7),$3C01+($80*7),$007F
    
    ; ensure override palette remains intact
    jsr transferOverridePaletteToPalMem
    
    jmp $458A
  
  splitFadeInFromWhitePalTransfer:
;    tii $3C00,$3C02,$03FE
    .rept 7 INDEX count
      tii $3C00+($80*count),$3C02+($80*count),$0080
    .endr
    tii $3C00+($80*7),$3C01+($80*7),$007E
    
    ; ensure override palette remains intact
    jsr transferOverridePaletteToPalMem
    
    jmp $4576
.ends

.bank 0 slot 0
.orga $4583
.section "fade palette transfer split 3" overwrite
  jmp splitFadeInFromBlackPalTransfer
.ends

.bank 0 slot 0
.orga $456F
.section "fade palette transfer split 4" overwrite
  jmp splitFadeInFromWhitePalTransfer
.ends

;================================
; subtitle palette does not get faded
;================================

.bank 0 slot 0
.orga $473C
.section "fade no sub palette 1" overwrite
  jmp noSubPaletteFade1
.ends

.bank 0 slot 0
.section "fade no sub palette 2" free
  noSubPaletteFade1:
    ; make up work
    lda $1C
    sta $D4
    lda $1D
    sta $D5
    
    jsr removeSubPaletteFromPalUpdateBitfield
    
    jmp $4744
  
  noSubPaletteFadeIn1:
    ; make up work
    lda $1C
    sta $D4
    lda $1D
    sta $D5
    
    jsr removeSubPaletteFromPalUpdateBitfield
    
    jmp $45D1
  
  removeSubPaletteFromPalUpdateBitfield:
    lda currentSubtitlePaletteIndex.w
    ; bit 7 of index set = disabled
    bmi @done
      ; $1C-1D are a bitfield indicating which palettes are affected
      ; by the fadeout effect (bit ordering = low to high, i.e.
      ; if bit 0 set, palette 0 is affected).
      ; we want to clear the subtitle palette's bit.
      ; (now targets the copy at $D4-D5 because the game actually has
      ; a specific check for whether all palettes were faded out by
      ; querying $1C-1D, and if they were not, the background is not disabled.
      ; this leads to problems with sprite pop-in when the screen is restored,
      ; and we want to avoid that.)
      
      ; set up default target byte
      pha
        lda #$D4
        sta @getOp+1.w
        sta @setOp+1.w
      pla
      
      ; if target index >= 8, target high byte
      cmp #$08
      bcc +
        inc @getOp+1.w
        inc @setOp+1.w
        and #$07
      +:
      
      ; clear the bit which corresponds to this value
      phx
        tax
        
        ; fetch target bitfield
        @getOp:
        lda $00
        ; mask off target bit
        and indexToBitMask.w,X
        ; save
        @setOp:
        sta $00
      plx
      
    @done:
    rts
  
  indexToBitMask:
    .rept 8 INDEX count
      .db (1<<count)~$FF
    .endr
.ends

.bank 0 slot 0
.orga $45C9
.section "fade no sub palette fade in 1" overwrite
  jmp noSubPaletteFadeIn1
.ends

;==============================================================================
; load subtitle data before starting scene
;==============================================================================

.define scene00Patch1SectorLo $8C
.define scene00Patch1SectorMid $81
.define scene00Patch1SectorHi $01
.define scene00Patch1SectorCount 2

.bank 0 slot 0
.orga $4045
.section "load subtitles 1" overwrite
  jsr loadSubtitles
.ends

.bank 0 slot 0
.section "load subtitles 2" free
  loadSubtitles:
    ; check target scene ID
    ; if zero, do nothing; subtitles are already loaded
    lda $00
    beq +
      @loadLoop:
      lda $00
        ; decrement ID and multiply by 2 to get offset from base sector
        dea
        asl
        clc
        adc #subtitleDataBaseSectorLo
        sta _DL
        cla
        adc #subtitleDataBaseSectorMid
        sta _CH
        cla
        adc #subtitleDataBaseSectorHi
        sta _CL
        
        ; type = local
        lda #$01
        sta _DH
        
        ; length
        lda #subtitleDataSectorCount
        sta _AL
        
        ; dst
        lda #<subtitleDataLoadAddr
        sta _BL
        lda #>subtitleDataLoadAddr
        sta _BH
        
;        jsr CD_READ
;        cmp #$00
;        bne @loadLoop
        
        jsr my_CD_READ
    +:
    
    ; load any additional resources as needed
    lda $00
    bne +
      ; scene 00 patch 1
      lda #scene00Patch1SectorLo
      sta _DL
      cla
      adc #scene00Patch1SectorMid
      sta _CH
      cla
      adc #scene00Patch1SectorHi
      sta _CL
      
      ; type = mpr6
      lda #$06
      sta _DH
      
      ; length
      lda #scene00Patch1SectorCount
      sta _AL
      
      ; dst bank num
      lda #$7F
      sta _BL
        
      jsr my_CD_READ
    +:
    
    ; make up work
    jmp $4C52
.ends

;==============================================================================
; misc fixes
;==============================================================================

;===================================
; wrong order of $F7 + vram select reg fixes
;===================================

.bank 0 slot 0
.orga $54B0
.section "bad vram reg save order 1" overwrite
  sta $F7
  sta $0000.w
.ends

.bank 0 slot 0
.orga $54CC
.section "bad vram reg save order 2" overwrite
  sta $F7
  sta $0000.w
.ends

;==============================================================================
; automatic sprite forcing when rcr off
;==============================================================================

.bank 0 slot 0
.section "rcr off sprite force 1" free
  doRcrOffSpriteForce1:
/*    lda rcrOffSpriteForcingOn.w
    beq @done
      ; set sprite flag
      lda $F3
      ora #$40
      sta $F3
    @done:*/
    
/*    lda rcrOffSpriteForcingOn.w
    beq @done
      ; save sprite flag for future restoration
      lda $F3
      and #$40
      sta lastBlackoutSpriteFlag.w
      
      ; set sprite flag
      lda $F3
      ora #$40
      sta $F3
    @done:
    
    ; make up work
    jmp EX_RCROFF
    jmp $4F1E */
    
    ; oops, this code originally happened second but it turns out
    ; it needs to happen first so the sprite flag will get applied
    ; if EX_RCROFF is called, so now we have to do a stupid push/pop
    ; on the input value we're going to be checking
    pha
      lda rcrOffSpriteForcingOn.w
      beq @done
        ; save sprite flag for future restoration
        lda $F3
        and #$40
        sta lastBlackoutSpriteFlag.w
        
        ; set sprite flag
        lda $F3
        ora #$40
        sta $F3
      @done:
    pla
    
    ; make up work
    ; (checking if all palettes were faded, and turning off
    ; rcr interrupt and background if so)
    ina
    bne +
      jsr EX_RCROFF
      jsr EX_BGOFF
    +:
    
    jmp $4F27
  
  doStandardRcrOnSpriteForce:
/*    lda rcrOffSpriteForcingOn.w
    beq @done
      ; clear sprite flag
      lda $F3
      and #($40~$FF)
      sta $F3
    @done: */
    
    ; make up work (drawFrame)
    jsr $42C9
    
    lda rcrOffSpriteForcingOn.w
    beq @done
      ; FIXME: should this be 2 or 3??
      lda #$03
      sta screenRestoreCounter.w
    @done:
    
    ; make up work
    ; do not attempt to turn rcr on if already on.
    ; EX_RCRON instantly refreshes the video control register from $20F3
    ; when called.
    ; this routine may be called in the middle of active display,
    ; with an active rcr handler having deliberately changed the CR
    ; from its nominal value in $20F3; if we call EX_RCRON here,
    ; that will be reverted, possibly causing display errors.
    lda $F3
    and #$04
    bne +
      jsr EX_RCRON
    +:
    jsr EX_BGON
    rts
    
  doRcrOnSpriteForce1:
    bsr doStandardRcrOnSpriteForce
    jmp $4F08
  
  doRcrOnSpriteForce2:
    bsr doStandardRcrOnSpriteForce
    jmp $4F31
  
  rcrOffSpriteForcingOn:
    .db $01
.ends

.bank 0 slot 0
;.orga $4F21
.orga $4F1E
.section "rcr off sprite force 2" overwrite
  ; when fading out?
;  jsr doRcrOffSpriteForce1
  jmp doRcrOffSpriteForce1
.ends

.bank 0 slot 0
.orga $4EFF
.section "rcr on sprite force 3" overwrite
  jmp doRcrOnSpriteForce1
.ends

; FIXME?
.bank 0 slot 0
.orga $4F28
.section "rcr on sprite force 4" overwrite
  jmp doRcrOnSpriteForce2
.ends



;==============================================================================
; sync counter
;==============================================================================

; increment sync counter when a cd track starts playing
.bank 0 slot 0
.orga $4ECB
.section "sync counter 1" overwrite
  jmp doCdSyncCounter
.ends

.bank 0 slot 0
.section "sync counter 2" free
  doCdSyncCounter:
    ; make up work
    jsr CD_PLAY
    ; increment sync counter
;    jmp incrementSyncCounter
    ; !!!!! drop through !!!!!
  incrementSyncCounter:
    ; TODO: would a $F5 reset/set work better here than CPU interrupt disable?
    sei
      nop
      lda syncFrameCounter+0.w
      sta syncFrameCounterAtLastAdpcmSync+0.w
      lda syncFrameCounter+1.w
      sta syncFrameCounterAtLastAdpcmSync+1.w
    
      ; we actually want this value plus one, since we know that
      ; syncFrameCounter will be incremented at the next sync period
      ; and that incremented value is what the scripts check against
      inc syncFrameCounterAtLastAdpcmSync+0.w
      bne +
        inc syncFrameCounterAtLastAdpcmSync+1.w
      +:
      
      inc adpcmSyncCounter.w
    cli
    rts
    
.ends

;==============================================================================
; EX_SATCLR fixes
;==============================================================================

.bank 0 slot 0
.section "clear non-subtitle sat 1" free
  clearNonSubSprites:
    lda #$00
    sta $F7
    sta $0000.w
    
    ; clear all sprites if subtitles not on
    lda subtitleDisplayOn.w
    beq +
      lda currentSubtitleSpriteAttributeQueueSize.w
    +:
    pha
      ; convert to word size for address computation
      lsr
      sta @subSprSizeOp+1.w
      
      ; set dst
      lda stdSatPtrAddrLo.w
      clc
      @subSprSizeOp:
      adc #$00
      sta $0002.w
      lda stdSatPtrAddrHi.w
      adc #$00
      sta $0003.w
      
      lda #$02
      sta $F7
      sta $0000.w
      
;      lda currentSubtitleSpriteAttributeQueueSize.w
;      eor #$FF
;      ina
      ; compute size
;      lda @subSprSizeOp+1.w
    pla
    beq +
      sta @clearToSatCmd+5.w
      @clearToSatCmd:
      tia zeroPlanes,$0002,$0000
    +:
    eor #$FF
    ina
    bne +
      ; two 0x100-byte transfers
      ina
      stz @clearToSatCmd2+5.w
      stz @clearToSatCmd3+5.w
      sta @clearToSatCmd2+6.w
      sta @clearToSatCmd3+6.w
      bra ++
    +:
      ; high byte 0, low byte is target amount
      stz @clearToSatCmd2+6.w
      stz @clearToSatCmd3+6.w
      sta @clearToSatCmd2+5.w
      sta @clearToSatCmd3+5.w
    ++:
    @clearToSatCmd2:
    tia zeroPlanes,$0002,$0000
    @clearToSatCmd3:
    tia zeroPlanes,$0002,$0000
      
    rts
.ends

.macro doSatClrJsrFix
  .orga \1
  .section "sat clr jsr fix \@" overwrite
    jsr clearNonSubSprites
  .ends
.endm

.macro doSatClrJmpFix
  .orga \1
  .section "sat clr jmp fix \@" overwrite
    jmp clearNonSubSprites
  .ends
.endm

  doSatClrJsrFix $5043
  doSatClrJsrFix $508E
  doSatClrJsrFix $50DF
  doSatClrJsrFix $51E9
  doSatClrJsrFix $5203
  doSatClrJsrFix $55CA

;==============================================================================
; old bootloader code
;==============================================================================

.define rcrState_topSubOn 0
.define rcrState_topSubOff 1
.define rcrState_startCrop 2
.define rcrState_endCrop 3
.define rcrState_bottomSubOn 4
.define rcrState_bottomSubOff 5

;===================================
; jump table + interface
;===================================

.bank 0 slot 0
.section "scene common interface 1" free
  
  ;===================================
  ; font
  ;===================================
  
  font:
    .incbin "out/font/font_scene.bin"
  fontWidthTable:
    .incbin "out/font/fontwidth_scene.bin"
  
  ; lookup table for font.
  ; this isn't necessary (it's just encoding a multiplication by 10)
  ; but saves having to manually compute it and deal with saving
  ; math registers in the sync interrupt handler
  fontLut:
    .rept numSceneFontChars INDEX count
      .dw font+(count*bytesPerSceneFontChar)
    .endr
.ends

.bank 0 slot 0
.orga $55F5
.section "scene common interface 2" SIZE reservedAreaSize overwrite
  
  ;===================================
  ; extra code
  ;===================================
  
  setUpStdBanks:
;    tma #$08
;    sta restoreOldBanks@slot3+1.w
    tma #$10
    sta restoreOldBanks@slot4+1.w
    tma #$20
    sta restoreOldBanks@slot5+1.w
    
;    lda #ovlBoot_extraPagesBase
    ; FIXME?
    lda #$84
;    tam #$08
;    ina
    tam #$10
    ina
    tam #$20
    
    rts
  
  restoreOldBanks:
    @slot3:
;    lda #$00
;    tam #$08
    @slot4:
    lda #$00
    tam #$10
    @slot5:
    lda #$00
    tam #$20
    
    rts
  
  doNewRcrDispatch:
    lda stdRcrStateVal.w
    asl
    tax
    jmp (newRcrDispatchTable,X)
  
  newRcrDispatchTable:
    ; state 0 = starting top subtitle on area
    .dw rcrHandler_topSubOn
    ; state 1 = ending top subtitle on area
    .dw rcrHandler_topSubOff
    ; state 2 = starting crop area
    .dw $424F
    ; state 3 = ending crop area
    .dw rcrHandler_cropEnd
    ; state 4 = starting bottom subtitle on area
    .dw rcrHandler_bottomSubOn
    ; state 5 = ending bottom subtitle on area
    .dw $4286
  
  rcrHandler_topSubOn:
    ; sprites on
    st0 #$05
    lda $F3
    ora #$40
    sta $0002.w
    
    st0 #$06
    ; if crop upper <= end of subtitle area, skip state 1
    lda cropUpperY.w
    cmp #spriteCropCutoffTriggerUpperBottom+1
    bcs @needSubStates
      ; set next rcr to crop start
      sta $14
      lda #rcrState_startCrop
      sta stdRcrStateVal.w
      jmp $4299
    @needSubStates:
      ; set next rcr to subtitle end
      lda #spriteCropCutoffTriggerUpperBottom
      sta $14
      ; advance to next state
      inc stdRcrStateVal.w
      jmp $4299
  
  rcrHandler_topSubOff:
    ; sprites off
    st0 #$05
    lda $F3
    and #$40~$FF
    sta $0002.w
    
    ; set next rcr to crop start
    st0 #$06
    lda cropUpperY.w
    sta $14
    
    ; advance to next state
    inc stdRcrStateVal.w
    jmp $4299
  
  rcrHandler_cropEnd:
    ; do normal behavior if subtitles not on
    lda subtitleDisplayOn.w
    beq @needSubStates
    
    ; if lower crop start is within subtitle area
    lda cropLowerY.w
    cmp #spriteCropCutoffTriggerLowerTop
    bcc @needSubStates
    cmp #spriteCropCutoffTriggerLowerBottom
    bcs @needSubStates
      st0 #$05
      lda $F3
      ; disable background
      and #$7F
      ; ensure sprites continue to be enabled
      ; ($F3 will not normally contain the sprite-on flag, which is
      ; manually set in the rcr interrupt)
      ora #$40
      sta $0002.w
      
      ; set next rcr to subtitle end area
      st0 #$06
      lda #spriteCropCutoffTriggerLowerBottom
      sta $14
      
      lda #rcrState_bottomSubOff
      sta stdRcrStateVal.w
      ; finish up normally
      jmp $4299
    @needSubStates:
  
    ; disable background + sprites
    st0 #$05
    lda $F3
    and #$3F
    sta $0002.w
    
    lda subtitleDisplayOn.w
    beq @done
    ; if crop end >= subtitle end area,
    ; we're done
    lda cropLowerY.w
    cmp #spriteCropCutoffTriggerLowerBottom
    bcc +
    @done:
      stz stdRcrStateVal.w
      jmp $4292
    +:
    
    ; otherwise, crop end is < subtitle start area.
    ; schedule subtitle area on event
;    lda #rcrState_bottomSubOn
;    sta stdRcrStateVal.w
    inc stdRcrStateVal.w
    st0 #$06
    lda #spriteCropCutoffTriggerLowerTop
    sta $14
    ; finish up normally
    jmp $4299
  
  rcrHandler_bottomSubOn:
    ; sprites on
    st0 #$05
    lda $F3
    ora #$40
    ; bg off
    and #$80~$FF
    sta $0002.w
    
    ; schedule off event
    inc stdRcrStateVal.w
    st0 #$06
    lda #spriteCropCutoffTriggerLowerBottom
    sta $14
    ; finish up normally
    jmp $4299
  
  doNewRcrEndInit:
    ; final rcr for frame: decide next state
    
    ; do normal cropping if subtitles not on
    lda subtitleDisplayOn.w
    bne +
    @doNormalCrop:
      lda cropUpperY.w
      bra @noSubStates
    +:
    
    ; if subtitles are on, but current subtitle has no top-group content,
    ; do normal cropping here.
    ; active line count will be >= 3 if there is top-group content.
    lda currentSubtitleActiveLineCount.w
    cmp #3
    bcc @doNormalCrop
    
    ; if upper crop start <= top subtitle area, skip top subtitle states
    lda cropUpperY.w
    cmp #spriteCropCutoffTriggerUpperTop+1
    bcs @needSubStates
    @noSubStates:
      ; set next rcr to crop start
      sta $14
      lda #rcrState_startCrop
      sta stdRcrStateVal.w
      ; finish up normally
      jmp $4299
    @needSubStates:
      ; next state = 0
      ; (already set)
;      stz stdRcrStateVal.w
      ; set next rcr to top subtitle area start
      lda #spriteCropCutoffTriggerUpperTop
      sta $14
      ; finish up normally
      jmp $4299
  
/*  doNewRcrCropStartEndInit:
    ; if lower crop start >= subtitle start area,
    ; skip bottomSubOn.
    ; schedule endCrop as normal.
    ; endCrop checks if in bottom sub area and handles appropriately.
    lda cropLowerY.w
    cmp #spriteCropCutoffTriggerLowerTop
    bcc @needSubStates
      ; set next rcr to crop end
      sta $14
;      lda #rcrState_endCrop
;      sta stdRcrStateVal.w
      inc stdRcrStateVal.w
      ; finish up normally
      jmp $4299
    @needSubStates:
    
      ; finish up normally
      jmp $4299 */
  
;  rcrVramRegFix:
;    ; make up work
;    sta $0003.w
;    
;    ; attempt to restore saved target video reg
;    lda $F7
;    sta $0000.w
;    rts
.ends

;.bank 0 slot 0
;.orga $42AD
;.section "rcr vram reg fix 1" overwrite
;  jmp rcrVramRegFix
;.ends

;==============================================================================
; sprite generation injection
;==============================================================================

.bank 0 slot 0
.orga $487E
.section "sprite generation 1" overwrite
  jmp newSpriteGenStart
.ends

;.bank 0 slot 0
;.section "sprite generation 2" free
;.ends

.bank 0 slot 0
.orga $433B
.section "sprite generation 3" overwrite
  jsr doNewSpriteEval
.ends

.bank 0 slot 0
.section "sprite generation 4" free
  doNewSpriteEval:
    bbr0 $05,+
      ; sprite refresh on: do usual behavior
      jmp $4345
    +:
    ; if sprite refresh off, evaluate subtitle sprites only
    jmp newSpriteGenStart
.ends

; raw colors
.define basePalMem $3800
.define baseSprPalMem $3A00
; colors after applying fade effects, etc.
.define realPalMem $3C00
.define realSprPalMem $3E00
.define palMemSpacing $400

.bank 0 slot 0
.section "sprite generation 5" free
  newSpriteGenStart:
    ; HACK: force SAT to the normal location.
    ; this would do nothing in the original game,
    ; but we're using alternate SAT locations during blackout
    ; periods so we can switch the subtitles without disrupting
    ; MAWR (which the game is using during blackouts to load
    ; new graphics, and can't be interfered with).
    ; doing this ensures that we switch back to the normal table
    ; once the blackout ends and standard sprite rendering resumes.
    ; this also forces a SATB transfer at the end of the frame,
    ; but that should be fine
    lda #$13
    sta $F7
    sta $0000.w
    lda stdSatPtrAddrLo.w
    sta $0002.w
    lda stdSatPtrAddrHi.w
    sta $0003.w
    
    ; ensure auto satb dma enabled
    lda #$0F
    sta $F7
    sta $0000.w
    st1 #$10
    st2 #$00
    
    lda #$00
    ; note: these two instructions were erroneously interchanged
    ; in the original code, which would have led to problems if
    ; an interrupt occurred between them. however, they got lucky
    ; and it apparently never happens.
    ; with our alterations, however, it's now a possibility,
    ; so we have to be more careful.
    sta $F7
    sta $0000.w
    ; number of initial sprite slots to skip
    lda $72
    
    ; add number of sprites in active subtitle
;    clc
;    adc currentSubtitleSpriteAttributeQueueSize.w
;    sta $28C9.w
;    jmp $488A

    sta $28C9.w
    asl
    asl
    clc
    adc $2214.w
    sta $0002.w
    cla
    adc $2215.w
    sta $0003.w
    
    lda #$02
    sta $F7
    sta $0000.w

    lda subtitleDisplayOn.w
    beq +
      ;=====
      ; write subtitle sprite attributes to start of SAT
      ;=====
      
      ; set write address
;      st0 #$00
;      st1 #<satVramAddr
;      st2 #>satVramAddr
      
      ; start write
;      st0 #$02
      
/*      lda currentSubtitleSpriteAttributeQueuePtr+0.w
      sta @transferToSatCmd+1.w
      lda currentSubtitleSpriteAttributeQueuePtr+1.w
      sta @transferToSatCmd+2.w
      
      lda currentSubtitleSpriteAttributeQueueSize.w
      sta @transferToSatCmd+5.w
      ; offset current slot num by count of sprites written
      ; (this value is used to avoid overflowing the sprite table)
      lsr
      lsr
      lsr
      clc
      adc $28C9.w
      sta $28C9.w
      
      ; TODO: possible optimization: write the queue pointer here directly
      ; if it's never needed elsewhere
      @transferToSatCmd:
      tia $0000,$0002,$0000 */
      
      ; so the code above is fine from an efficiency standpoint.
      ; however, the fact that block transfers are uninterruptable leads
      ; to a problem: doing too large a block transfer can cause a line
      ; interrupt to fire "late" or get missed, leading to unpredictable effects.
      ; in mednafen, at least, the old code caused the first scene of the intro
      ; to "jitter" up and down a pixel constantly while scrolling.
      ; so here's a slower but safer version.
      ; the same issue likely applies in other places block transfers are used.
      lda currentSubtitleSpriteAttributeQueuePtr+0.w
      sta @transferToSatCmd+1.w
      lda currentSubtitleSpriteAttributeQueuePtr+1.w
      sta @transferToSatCmd+2.w
      
      lda currentSubtitleSpriteAttributeQueueSize.w
      lsr
      lsr
      lsr
      tax
      @spriteLoop:
        @transferToSatCmd:
        tia $0000,$0002,$0008
          
        lda @transferToSatCmd+1.w
        clc
        adc #8
        sta @transferToSatCmd+1.w
        cla
        adc @transferToSatCmd+2.w
        sta @transferToSatCmd+2.w
        
        inc $28C9.w
        dex
        bne @spriteLoop
      
/*      phy
        lda currentSubtitleSpriteAttributeQueuePtr+0.w
        sta @transferToSatCmd1+1.w
        sta @transferToSatCmd2+1.w
        lda currentSubtitleSpriteAttributeQueuePtr+1.w
        sta @transferToSatCmd1+2.w
        sta @transferToSatCmd2+2.w
        
        lda currentSubtitleSpriteAttributeQueueSize.w
        lsr
        lsr
        lsr
        tay
        clx
        @spriteLoop:
          phy
            ldy #4
            -:
              @transferToSatCmd1:
              lda $0000.w,X
              sta $0002.w
              inx
              
              @transferToSatCmd2:
              lda $0000.w,X
              sta $0003.w
              inx
              
              dey
              bne -
            
            inc $28C9.w
          ply
          dey
          bne @spriteLoop
      ply */
    +:
    
    ; do sprite flood if applicable
    @doSpriteFlood:
    phx
    phy
      clx
      @loop:
        lda spriteFloodCount.w,X
        beq @loopEnd
        
        ; Y = sprite count
        tay
        ; add to total sprite count
        clc
        adc $28C9.w
        sta $28C9.w
        
        ; get target Y
        lda spriteFloodY.w,X
        clc
        adc #<spriteAttrBaseY
        sta spriteFloodBuffer+0.w
        cla
        adc #>spriteAttrBaseY
        sta spriteFloodBuffer+1.w
        
        @subLoop:
          ; send sprite
          tia spriteFloodBuffer,$0002,8
          dey
          bne @subLoop
        
        @loopEnd:
        inx
        cpx #2
        bne @loop
    ply
    plx
    
    ; if fixed sprite area is on, blank out sprites through end of area
    lda highPrioritySpriteObjGenerationOffset.w
    beq @noExtraBlanks
      ; numAreaSprites - currentNumSprites
      sec
      sbc $28C9.w
      ; do nothing if we've already written that many sprites or more
      beq @noExtraBlanks
      bmi @noExtraBlanks
      
/*;        pha
;          clc
;          adc $28C9.w
;          sta $28C9.w
;        pla
      ; this calculation assumes no more than 31 sprites in the area
      asl
      asl
      asl
      sta @clearToSatCmd+5.w
      
      @clearToSatCmd:
      tia zeroPlanes,$0002,$0000 */
      
      ; the raster timing issue described above also applies here;
      ; break up transfers into individual sprites instead of doing
      ; the whole thing at once to keep everything working right
      tax
      -:
        tia zeroPlanes,$0002,$0008
        dex
        bne -
      
      ; set dst sprite index to new position
      lda highPrioritySpriteObjGenerationOffset.w
      sta $28C9.w
    @noExtraBlanks:
    
    bbr0 $05,+
      ; sprite refresh on: do usual behavior
      jmp $48A1
    +:
    ; sprite refresh off:
    ; do not evaluate normal sprites
    ; FIXME: this will cause issues if the subtitles need to change
    ; while regular sprite refresh is off; probably can use the
    ; old sprite offset ops to make sure there's room for any needed
    ; subtitle sprites in front of the regular sprites (though it will
    ; be necessary to clear out any unused sprites between the end of the
    ; subtitle area and the start of the regular sprite area)
;    jmp $48AD
    rts
  
  transferOverridePalette:
    ; set override palette
    ; dstaddr
    lda currentSubtitlePaletteIndex.w
    ; bit 7 of index set = disabled
    bmi ++
      ; could optimize this by precomputing the shift,
      ; but i don't think it'll come to that
      asl
      asl
      asl
      asl
      ; target from color 1
      ora #$01
      sta vce_ctaLo.w
      
      pha
        ; set up high bytes
        lda #>baseSprPalMem
        sta @palMemTransferOp1+4.w
        lda #>realSprPalMem
        sta @palMemTransferOp2+4.w
      pla
      asl
      
      ; copy to memory
      ; HACK: the copies of the palette in memory are at $3800 and $3C00.
      ; we know the lower byte will be the same for both transfers
;      clc
;      adc #<baseSprPalMem
      sta @palMemTransferOp1+3.w
      sta @palMemTransferOp2+3.w
      bcc +
        inc @palMemTransferOp1+4.w.w
        inc @palMemTransferOp2+4.w.w
      +:
      
      @palMemTransferOp1:
      tii paletteOverrideColors,$0000,(paletteOverrideColorsEnd-paletteOverrideColors)
      @palMemTransferOp2:
      tii paletteOverrideColors,$0000,(paletteOverrideColorsEnd-paletteOverrideColors)
      
      ; target sprite palettes
      lda #$01
      sta vce_ctaHi.w
      ; copy colors to vce
      tia paletteOverrideColors,vce_ctwLo,(paletteOverrideColorsEnd-paletteOverrideColors)
    ++:
    
    rts
  
  transferOverridePaletteToPalMem:
    lda currentSubtitlePaletteIndex.w
    ; bit 7 of index set = disabled
    bmi ++
      ; could optimize this by precomputing the shift,
      ; but i don't think it'll come to that
      asl
      asl
      asl
      asl
      ; target from color 1
      ora #$01
      
      pha
        ; set up high bytes
        lda #>baseSprPalMem
        sta @palMemTransferOp1+4.w
        lda #>realSprPalMem
        sta @palMemTransferOp2+4.w
      pla
      asl
      
      sta @palMemTransferOp1+3.w
      sta @palMemTransferOp2+3.w
      bcc +
        inc @palMemTransferOp1+4.w.w
        inc @palMemTransferOp2+4.w.w
      +:
      
      @palMemTransferOp1:
      tii paletteOverrideColors,$0000,(paletteOverrideColorsEnd-paletteOverrideColors)
      @palMemTransferOp2:
      tii paletteOverrideColors,$0000,(paletteOverrideColorsEnd-paletteOverrideColors)
    ++:
    rts
.ends

;==============================================================================
; sprite crop minimization
;==============================================================================

.bank 0 slot 0
.orga $48F2
.section "sprite crop minimize 1" overwrite
  jmp doSpriteCropMinimize
.ends

.bank 0 slot 0
.section "sprite crop minimize 2" free
  spriteCropMinimize_on:
    .db $00

  doSpriteCropMinimize_doneNoSend:
    jmp $48FC
  
  doSpriteCropMinimize:
    ; FIXME: is it correct to ignore if subtitles not on?
;    lda subtitleDisplayOn.w
;    beq @noCrop
    
    lda spriteCropMinimize_on.w
    beq @noCrop
  
    ; ignore if crop is not in a range that could interfere with subtitles anyway
    lda cropUpperY.w
    cmp #spriteCropCutoffTriggerUpperTop+1
    bcs +
      lda cropLowerY.w
      cmp #spriteCropCutoffTriggerLowerBottom
      bcc +
        @noCrop:
        jmp @doneNoChange
    +:
  
    ; get sprite width
    lda currentSpriteFlagsHi.w
    pha
      and #$01
      sta currentSpriteWidthRaw.w
    pla
    pha
      ; get sprite height
      and #$30
;      pha
;        ; force height to 3 if 2 (both are 4 sprites tall)
;        and #$20
;      pla
      cmp #$20
      bne +
        lda #$30
      +:
      sta currentSpriteHeightPx.w
      
      ; turn into true bottom y-pos
      clc
      adc #spritePatternH
      clc
      adc currentSpriteYLo.w
      sta currentSpriteLowerY+0.w
      cla
      adc currentSpriteYHi.w
      sta currentSpriteLowerY+1.w
    pla
    ; get sprite y-flip
    and #$80
    sta currentSpriteYFlip.w
    
    ; ignore if bottom Y < 0
    lda currentSpriteLowerY+1.w
    ; FIXME: depending on exact crop parameters used, we might be able to
    ; get away with ignoring the case of bottom Y >= 256...
    ; doubt it, though
;    bne doSpriteCropMinimize_doneNoSend
    bmi doSpriteCropMinimize_doneNoSend
    ; is sprite's bottom above the crop?
    ; if so, don't send
    lda currentSpriteLowerY+0.w
    cmp cropUpperY.w
    bcc doSpriteCropMinimize_doneNoSend
    beq doSpriteCropMinimize_doneNoSend
    
    ; ignore if top Y < 0 or >= 256
    ; FIXME: isn't top Y < 0 potentially a perfectly valid case?
;    lda currentSpriteYHi.w
;    bne doSpriteCropMinimize_doneNoSend
    ; ignore if top Y >= 256
    lda currentSpriteYHi.w
    beq +
    bpl doSpriteCropMinimize_doneNoSend
    ; allow checks when negative only if a small number
    ; that might plausibly intersect the crop area
    cmp #$FF
    beq ++
    and #$FF
    bmi doSpriteCropMinimize_doneNoSend
    +:
      ; is sprite's top below the crop?
      ; if so, don't send
      lda currentSpriteYLo.w
      cmp cropLowerY.w
      bcs doSpriteCropMinimize_doneNoSend
    ++:
    
    ; we now know the sprite is at least partially visible
    
    ; FIXME: skip this if top subtitles not on?
    
    ; handle case where top Y < 0
    lda currentSpriteYHi.w
    bne @topLoop
    ; do nothing here if sprite top >= crop top
    lda currentSpriteYLo.w
    cmp cropUpperY.w
    bcs @topLoopDone
    ; remove sprites from top until no longer possible
    @topLoop:
      ; special handling for 64-px-high sprites:
      ; must have 32 pixels to spare rather than 16
      lda currentSpriteHeightPx.w
      cmp #$20
      lda #spritePatternH
      bcc +
        asl
      +:
      sta @topCheckOp+1.w
      
      ; if (cropUpper - spriteUpper) >= 16, we can remove a sprite
      lda cropUpperY.w
      sec
      sbc currentSpriteYLo.w
      @topCheckOp:
      cmp #$00
      bcc @topLoopDone
      @doTopReduction:
        jsr removeCurrentSpriteTop
        bra @topLoop
    @topLoopDone:
    
    ; do nothing here if sprite bottom <= crop bottom
    ; handle case where bottom Y >= 256
    lda currentSpriteLowerY+1.w
    bne @bottomLoop
    lda currentSpriteLowerY.w
    cmp cropLowerY.w
    bcc @bottomLoopDone
    beq @bottomLoopDone
    ; remove sprites from bottom until no longer possible
    @bottomLoop:
      ; always remove sprite if bottom >= 256
      lda currentSpriteLowerY+1.w
      bne @doBottomReduction
      
      ; if (spriteLower - cropLower) >= 16, we can remove a sprite
      lda currentSpriteLowerY.w
      sec
      sbc cropLowerY.w
      cmp #spritePatternH
      bcc @bottomLoopDone
      @doBottomReduction:
        jsr removeCurrentSpriteBottom
        bra @bottomLoop
    @bottomLoopDone:
    
    @done:
    ; apply updated height field
    lda currentSpriteFlagsHi.w
    and #$30~$FF
    ora currentSpriteHeightPx.w
    sta currentSpriteFlagsHi.w
    
    @doneNoChange:
    ; apply base y-offset
    lda currentSpriteYLo.w
    clc 
    adc #$40
    sta currentSpriteYLo.w
    bcc +
      inc currentSpriteYHi.w
    +:
    ; send sprite to sat
    tia $28C1,$0002,$0008
    jmp $48F9
  
  removeCurrentSpriteBottom:
    lda currentSpriteYFlip.w
    beq +
      jsr removeCurrentSpriteTop@main
      ; undo increase in y-position
      lda currentSpriteYLo.w
      sec
      sbc #spritePatternH
      sta currentSpriteYLo.w
      lda currentSpriteYHi.w
      sbc #0
      sta currentSpriteYHi.w
      
      bra @end
    +:
    
    @main:
    
    ; offset pattern by -1 pattern if single-width,
    ; -2 patterns if double
/*    lda currentSpriteWidthRaw.w
    ina
    clc
    adc currentSpritePatternLo.w
    sta currentSpritePatternLo.w
    bne +
      inc currentSpritePatternHi.w
    +:*/
/*    lda currentSpriteWidthRaw.w
    beq +
      dec currentSpritePatternLo.w
      cmp #$FF
      bne +
        dec currentSpritePatternHi.w
    +:
    dec currentSpritePatternLo.w
    cmp #$FF
    bne +
      dec currentSpritePatternHi.w
    +: */
    
    ; okay, so this doesn't actually "work", per se.
    ; i completely forgot that there is no 48px sprite height mode,
    ; only 16/32/64.
    ; effectively, this only guarantees that overdraw will be limited to 32px
    ; below the crop instead of the desired 16px.
    ; but in practice, the game's normal "theatrical" cropping gives us that much
    ; space to work with on the bottom anyway, so it should be good enough for
    ; what we need to do.
    
    ; reduce height by pattern height
    lda currentSpriteHeightPx.w
    sec
    sbc #spritePatternH
    sta currentSpriteHeightPx.w
    
    @end:
    ; reduce lower y by pattern height
    lda currentSpriteLowerY+0.w
    sec
    sbc #spritePatternH
    sta currentSpriteLowerY+0.w
    lda currentSpriteLowerY+1.w
    sbc #0
    sta currentSpriteLowerY+1.w
    
    rts
  
  removeCurrentSpriteTop:
    lda currentSpriteYFlip.w
    beq +
      jsr removeCurrentSpriteBottom@main
      ; undo decrease in lower y-pos
      lda currentSpriteLowerY+0.w
      clc
      adc #spritePatternH
      sta currentSpriteLowerY+0.w
      lda currentSpriteLowerY+1.w
      adc #0
      sta currentSpriteLowerY+1.w
    
      ; increase y-position by pattern height
      bra @end
    +:
    
    @main:
    
    ; offset pattern by 1 pattern if single-width,
    ; 2 patterns if double
/*    lda currentSpriteWidthRaw.w
    beq +
      inc currentSpritePatternLo.w
      bne +
        inc currentSpritePatternHi.w
    +:
    inc currentSpritePatternLo.w
    bne +
      inc currentSpritePatternHi.w
    +:  */
    ; needs to be *2 since low bit is CG mode bit
/*    lda currentSpriteWidthRaw.w
    ina
    asl
    clc
    adc currentSpritePatternLo.w
    sta currentSpritePatternLo.w
    bcc +
      inc currentSpritePatternHi.w
    +:*/
    ; FIXME: wait, this is unconditional??
    lda #$04
    clc
    adc currentSpritePatternLo.w
    sta currentSpritePatternLo.w
    bcc +
      inc currentSpritePatternHi.w
    +:
    
    ; reduce height by pattern height
    lda currentSpriteHeightPx.w
    sec
    sbc #spritePatternH
    sta currentSpriteHeightPx.w
    
    @end:
    
    ; increase y-position by pattern height
    lda currentSpriteYLo.w
    clc
    adc #spritePatternH
    sta currentSpriteYLo.w
    bcc +
      inc currentSpriteYHi.w
    +:
    
    ; if height is "48", run a second iteration, because there is no 48-pixel-high
    ; sprite mode
    lda currentSpriteHeightPx.w
    cmp #$20
    beq removeCurrentSpriteTop
    
;    lda currentSpriteYHi.w
;    adc #0
;    sta currentSpriteYHi.w
    
    rts
  
  currentSpriteWidthRaw:
    .db $00
  currentSpriteYFlip:
    .db $00
  currentSpriteHeightPx:
    .db $00
  currentSpriteLowerY:
    .dw $00
.ends

; don't add sprite base y-offset
.bank 0 slot 0
.orga $4927
.section "sprite crop minimize 3" overwrite
  jmp $4935
.ends

;==============================================================================
; new rcr handler logic
;==============================================================================

.bank 0 slot 0
.orga $424A
.section "new rcr logic 1" overwrite
  jmp doNewRcrDispatch
.ends

.bank 0 slot 0
.orga $4294
.section "new rcr logic 2" overwrite
  jmp doNewRcrEndInit
.ends

;.bank 0 slot 0
;.orga $427E
;.section "new rcr logic 2" overwrite
;  jmp doNewRcrCropStartEndInit
;.ends



;.bank 0 slot 0
;.section "new rcr logic 2" free
;.ends

;==============================================================================
; avoid sprite blackout during transitions
;==============================================================================

.bank 0 slot 0
.orga $4F54
.section "sprite blackout 1" overwrite
;  jsr startBlackout
  jmp startBlackout
.ends

.bank 0 slot 0
.section "sprite blackout 2" free
  startBlackout:
    ; save sprite flag for future restoration
    lda $F3
    and #$40
    sta lastBlackoutSpriteFlag.w
    
    ; FIXME: force sprites on
    ; this "sticks" after the blackout period ends,
    ; so additional measures are needed
    ; (probably will just reset this on the script side with the andOr op
    ; in cases where it matters)
    smb6 $F3
    ; disable auto satb dma
;    st0 #$0F
    lda #$0F
    sta $F7
    sta $0000.w
    st1 #$00
    st2 #$00
    
    ; turn off background only
;    jmp EX_BGOFF
    
    ; turn off background only
    jsr EX_BGOFF
    
    ; black out palettes
    stz $3C00.w
    tii $3C00,$3C01,$03FF
    stz $0402.w
    stz $0403.w
    tia $3C00,$0404,$0400
    ; but make sure override palettes remain intact if applicable
    ; FIXME: we really shouldn't do this during active display
    lda subtitleDisplayOn.w
    beq +
      jsr transferOverridePalette
    +:
    
    ; clear non-subtitle sprites from sat
    ; FIXME: needed?
;    lda subtitleDisplayOn.w
;    beq +
      jsr clearNonSubSprites
;    +:

    ; force satb dma so old sprites are cleared
    lda #$13
    sta $F7
    sta $0000.w
    lda stdSatPtrAddrLo.w
    sta $0002.w
    lda stdSatPtrAddrHi.w
    sta $0003.w
    
    jmp $4F6E
.ends

.bank 0 slot 0
.orga $4F3C
.section "sprite restore 1" overwrite
  jmp doSpriteRestoreExtra
.ends

.bank 0 slot 0
.section "sprite restore 2" free
  doSpriteRestoreExtra:
    ; flag restore as needed
    ; FIXME: this represents the number of frames to wait before
    ; actually turning the background back on.
    ; this is necessary because we keep the sprites on during blackouts
    ; whereas the original game does not, and for whatever reason,
    ; restoring the screen from bg+sprites off takes one extra frame
    ; versus if only bg is off; without compensating, the sprites
    ; will pop in two frames later than the background, which is rather jarring.
    ; so to match originaly behavior, this should be 2.
    ; however, even in the original game, the sprites still pop in a frame
    ; after the background in most cases;
    ; by using a value of 3 here, we ensure everything appears simultaneously.
    ; is there any reason not to do this?
    lda #$03
    sta screenRestoreCounter.w
    
    ; restore sprite flag to whatever it was at blackout start
;    lda $F3
;    and #($40~$FF)
;    ora lastBlackoutSpriteFlag.w
;    sta $F3
    
    ; make up work (restore palette)
    tii $3800,$3C00,$0400
    ; but force any override palettes back to desired state
;    jsr transferOverridePaletteToPalMem
    
    smb1 $0005
    ; drawFrame
    jsr $42C9
    rmb1 $0005
    jsr EX_RCRON
;    jsr EX_BGON
    rts
  
  screenRestoreCounter:
    .db $00
  
;  spriteRestoreCounter:
;    .db $00
  
  lastBlackoutSpriteFlag:
    .db $00
.ends

;==============================================================================
; the main event!
;==============================================================================

.define syncVector $418E

.define newZpFreeReg $29
.define newZpScriptReg $2B

.bank 0 slot 0
.orga syncVector+($41B5-$418E)
.section "sync handler injection 1" overwrite
  ; ensure the banks containing our code are loaded
  jsr setUpStdBanks
  ; run the new code
  jmp newSyncLogic
.ends

.bank 0 slot 0
.section "new sync handler logic 2" free
  ; frame counter, incremented every vsync.
  ; used to time script events
  syncFrameCounter:
    .dw $00
  ; DEBUG: same as above, but never gets reset.
  ; used to check timing
  globalSyncFrameCounter:
    .dw $00
  ; incremented every time an ADPCM clip is triggered.
  ; used to sync up timing
  adpcmSyncCounter:
    .db $00
  ; the value of syncFrameCounter the last time that
  ; adpcmSyncCounter was incremented
  syncFrameCounterAtLastAdpcmSync:
    .dw $0000
  
  oldPaletteTransferFlag:
    .db $00
  
  .ifdef enable_sceneAutoBusySkip
    lowPrioritySpriteObjDrawnThisFrame:
      .db $00
    highPrioritySpriteObjDrawnThisFrame:
      .db $00
    skipLowPriorityObjDrawFrames:
      .db $00
    skipHighPriorityObjDrawFrames:
      .db $00
  .endif
  
  ; TODO
  lowPrioritySpriteObjGenerationOffset:
    .db $00
  ; any high-priority sprite objects the game generates will be offset
  ; from their normal position in the SAT by this many attribute entries
  highPrioritySpriteObjGenerationOffset:
    .db $00
  
  ; array of counts for sprite flood mode
  ; if nonzero, this many double-width, single-height sprites are forced to appear
  ; at a non-visible position on the corresponding line. these have lower priority
  ; than the subtitles but higher priority than any game-generated content.
  ; this can be used to crop out parts of the screen where scanline-based cropping
  ; is impossible (e.g. because the subtitles need to appear in that area).
  spriteFloodCount:
    .db $00,$00
  ; array of y-positions for sprite flood mode
  spriteFloodY:
    .db $08,$18
  ; buffer for sprite in flood mode
  spriteFloodBuffer:
    ; y (set dynamically)
    .dw $0000
    ; x
    .dw $0000
    ; pattern index
    .dw $1FE<<1
    ; flags (single-height, double-width, high-priority) + palette
    .dw $0180|0
  
  ; these are written every frame,
  ; starting at color index 1 of the target palette.
  ; colors 1 and 3 are the font color,
  ; color 2 is the drop shadow color
  paletteOverrideColors:
;    .dw defaultSubColor
;    .dw defaultSubShadowColor
;    .dw defaultSubColor
    ; if bit 1 is set, color is font.
    ; otherwise, it's shadow
    .dw defaultSubColor
    .rept 7
      .dw defaultSubShadowColor
      .dw defaultSubColor
    .endr
    
    ; font = light blue
;    .dw $01C7
    ; shadow = black
;    .dw $0000
    ; font
;    .dw $01C7
  paletteOverrideColorsEnd:
  
  maxScriptActionsPerIteration:
    .db default_maxScriptActionsPerIteration
  maxSpriteAttrTransfersPerIteration:
    .db default_maxSpriteAttrTransfersPerIteration
  maxSpriteGrpTransfersPerIteration:
    .db default_maxSpriteGrpTransfersPerIteration
  subtitleSpriteForcingOn:
;    .db $FF
    .db $00
  
  newSyncLogic:
    ; make up work
    inc $07
    lda $2802.w
    cmp $07
    jsr $41BC
    
/*    ; ???
    lda screenRestoreCounter.w
    beq +
      dec screenRestoreCounter.w
      bne +
        jsr EX_BGON
        
        ; restore sprite flag to whatever it was at blackout start
        lda $F3
        and #($40~$FF)
        ora lastBlackoutSpriteFlag.w
        sta $F3
    +: */
    
/*    ; ???
    lda screenRestoreCounter.w
    beq @restoreDone
      dec screenRestoreCounter.w
      bne +
        jsr EX_BGON
        bra @restoreDone
      +:
      
      ; we want this to occur when the counter is 1,
      ; but we are comparing against the unincremented value
      cmp #$02
      bne @restoreDone
        ; restore sprite flag to whatever it was at blackout start
        lda $F3
        and #($40~$FF)
        ora lastBlackoutSpriteFlag.w
        sta $F3
    @restoreDone: */
    
    ; ???
    lda screenRestoreCounter.w
    beq +
      dec screenRestoreCounter.w
      bne ++
        jsr EX_BGON
        bra @restoreSpriteFlag
      ++:
      
      ; reset sprite flag immediately if subtitles are off;
      ; otherwise, it happens on the frame the background is turned on.
      ; this prevents subtitles from flickering when the blackout ends
      ; while preventing sprites from not getting cropped properly
      ; in the same period
      lda subtitleDisplayOn.w
      bne +
      @restoreSpriteFlag:
        ; restore sprite flag to whatever it was at blackout start
        lda $F3
        and #($40~$FF)
        ora lastBlackoutSpriteFlag.w
        sta $F3
    +:
    
/*    lda spriteRestoreCounter.w
    beq +
      dec spriteRestoreCounter.w
      beq @restoreSpriteFlag
;      bne ++
;        bra @restoreSpriteFlag
;      ++:
    +:*/
    
    ; increment frame counter
    inc syncFrameCounter+0.w
    bne +
      inc syncFrameCounter+1.w
    +:
    ; DEBUG
    inc globalSyncFrameCounter+0.w
    bne +
      inc globalSyncFrameCounter+1.w
    +:
    
    ; we happen to know that at this point,
    ; X will equal the old state of the paletteTransferRequest flag.
    ; if a palette transfer occurred, we do NOT want to run our
    ; additional logic (as it reduces the available time beyond what
    ; may be safe), so we save it for future reference
;    txa
    ; these trigger some sort of palette effects that similarly
    ; consume time
    ; (TODO: these may or may not require additional attention depending
    ; on what they actually do)
;    ora $63
;    ora $66
;    sta oldPaletteTransferFlag.w
    ; well, i guess we're throwing caution to the winds...
    
    ; make up work
;    jsr syncMakeup1
;    jsr syncMakeup2
    
    ; check if asynchronous subtitle clear has occurred
    lda queuedSubsOffIsOn.w
    beq +
      lda queuedSubsOffTime+0.w
      sec
      sbc syncFrameCounter.w
      lda queuedSubsOffTime+1.w
      sbc syncFrameCounter+1.w
      bcs ++
        ; turn subtitles off
        jsr turnSubsOff
        stz queuedSubsOffIsOn.w
      ++:
    +:
    
    ; display subs if on
    lda subtitleDisplayOn.w
    beq +
      ;=====
      ; write subtitle sprite attributes to start of SAT
      ;=====
      
      ; set write address
/*      st0 #$00
      st1 #<satVramAddr
      st2 #>satVramAddr
      
      ; start write
      st0 #$02
      
      lda currentSubtitleSpriteAttributeQueuePtr+0.w
      sta @transferToSatCmd+1.w
      lda currentSubtitleSpriteAttributeQueuePtr+1.w
      sta @transferToSatCmd+2.w
      
      lda currentSubtitleSpriteAttributeQueueSize.w
      sta @transferToSatCmd+5.w
      
      ; TODO: possible optimization: write the queue pointer here directly
      ; if it's never needed elsewhere
      @transferToSatCmd:
      tia $0000,$0002,$0000 */
      
      ; TODO: is this necessary?
      ; the real problem with flickering, etc. may simply be
      ; the sprites getting turned off (and then immediately on
      ; again by us)
      ; if non-subtitle sprite table clear requested, handle that
      ; FIXME
/*      lda triggerNonSubtitleSpriteClear.w
      beq ++
        ; blank everything EXCEPT the subtitle sprites from the SAT.
        ; the address is already primed (we just wrote all the
        ; subtitle sprites, and we're clearing out everything else
        ; to the end of the SAT)
        
        ; set size of the area to blank
        lda currentSubtitleSpriteAttributeQueueSize.w
        lsr
        eor #$FF
        ina
        sta @clearFromSatCmd+5.w
        
        ; we split this up into two transfers because zeroPlanes
        ; is only 256 bytes long.
        ; the total amount to clear is guaranteed to be >= 256
        ; (we assume a max of 31 subtitle sprites),
        ; so it works out fine
        tia zeroPlanes,$0002,$0100
        @clearFromSatCmd:
        tia zeroPlanes,$0002,$0000
        
        ; clear trigger flag
        stz triggerNonSubtitleSpriteClear.w
      ++: */
      
      ; initiate sat->satb dma
      ; (no longer needed: this game uses the automatic refresh mode)
;      st0 #$13
;      st1 #<satVramAddr
;      st2 #>satVramAddr
      
      ; force sprite display on
      lda subtitleSpriteForcingOn.w
      beq ++
        smb6 $F3
      ++:
      
      ;=====
      ; override palette for subtitles
      ;=====
      
      ; FIXME: remove?
      ; set override palette
      ; dstaddr
  ;    lda #$81
      lda currentSubtitlePaletteIndex.w
      ; bit 7 of index set = disabled
      bmi ++
;        jsr transferOverridePalette
        ; could optimize this by precomputing the shift,
        ; but i don't think it'll come to that
        asl
        asl
        asl
        asl
        ; target from color 1
        ora #$01
        sta vce_ctaLo.w
        ; target sprite palettes
        lda #$01
        sta vce_ctaHi.w
        ; copy colors to vce
        tia paletteOverrideColors,vce_ctwLo,(paletteOverrideColorsEnd-paletteOverrideColors)
      ++:
    +:
    
/*    lda #$FF
    sta vce_ctwLo.w
    sta vce_ctwHi.w
    cla
    sta vce_ctwLo.w
    sta vce_ctwHi.w
    lda #$FF
    sta vce_ctwLo.w
    sta vce_ctwHi.w */
    
;    lda oldPaletteTransferFlag.w
;    bne @done
    .ifdef enable_sceneAutoBusySkip
      lda skipLowPriorityObjDrawFrames.w
      beq +
        lda lowPrioritySpriteObjDrawnThisFrame.w
        bne @done
      +:
      lda skipHighPriorityObjDrawFrames.w
      beq +
        lda highPrioritySpriteObjDrawnThisFrame.w
        bne @done
      +:
    .endif
    
      lda newZpFreeReg
      pha
      lda newZpFreeReg+1
      pha
        
        ;=====
        ; if attribute transfer active
        ;=====
        
        lda subtitleAttributeTransferOn.w
        beq +
          lda maxSpriteAttrTransfersPerIteration.w
          sta remainingScriptActions.w
          -:
            jsr doNextSpriteAttrTransfer
            dec remainingScriptActions.w
            bne -
  ;        jsr doNextSpriteAttrTransfer
          jmp @actionsDone
        +:
        
        ;=====
        ; if graphics transfer active
        ;=====
        
        lda subtitleGraphicsTransferOn.w
        beq +
          lda maxSpriteGrpTransfersPerIteration.w
          
          ; the outlining algorithm is costly.
          ; if a palette transfer occurred on the same frame,
          ; only send one pattern to try to ensure we
          ; don't induce lag.
;          ldx oldPaletteTransferFlag.w
;          beq ++
;            lda #1
;          ++:
          
          sta remainingScriptActions.w
          -:
            jsr doNextSpriteGrpTransfer
            dec remainingScriptActions.w
            bne -
          jmp @actionsDone
        +:
        
        ;=====
        ; run script
        ;=====
        
        lda newZpScriptReg
        pha
        lda newZpScriptReg+1
        pha
          lda subtitleScriptPtr.w
          sta newZpScriptReg
          lda subtitleScriptPtr+1.w
          sta newZpScriptReg+1
          
          lda maxScriptActionsPerIteration.w
          sta remainingScriptActions.w
          -:
            jsr runScript
            dec remainingScriptActions.w
            bne -
          
          lda newZpScriptReg
          sta subtitleScriptPtr.w
          lda newZpScriptReg+1
          sta subtitleScriptPtr+1.w
        pla
        sta newZpScriptReg+1
        pla
        sta newZpScriptReg
        
      @actionsDone:
      pla
      sta newZpFreeReg+1
      pla
      sta newZpFreeReg
    @done:
    
    .ifdef enable_sceneAutoBusySkip
      stz lowPrioritySpriteObjDrawnThisFrame.w
      stz highPrioritySpriteObjDrawnThisFrame.w
    .endif
    
    jmp restoreOldBanks
  
  remainingScriptActions:
    .db $00
  
  doNextSpriteAttrTransfer:
    lda subtitleAttributeTransferCurrentStatePtr+0.w
    sta newZpFreeReg+0
    lda subtitleAttributeTransferCurrentStatePtr+1.w
    sta newZpFreeReg+1
    
    ; $FF in the line num indicates init needed
    lda subtitleAttributeTransferLineNum.w
    bmi @startNextLine
    ldy #SubtitleCompBufferLineState.patternTransfersLeft
    lda (newZpFreeReg),Y
    bne @lineNotDone
    @startNextLineFull:
      ; advance to next line
      lda subtitleAttributeTransferLineNum.w
    @startNextLine:
      ina
      cmp activeLineCount.w
      bne @notAllDone
        ; everything is done: turn transfer flag off
        stz subtitleAttributeTransferOn.w
        
        ; reset queue fields for graphics transfer
        jsr resetAllStateQueueFields
        
        ; prep drop shadow buffer for use
        tai blockClearWord,dropShadowBufferB,(dropShadowBufferBEnd-dropShadowBufferB)
        tai blockClearWord,charShiftBufferB,(charShiftBufferBEnd-charShiftBufferB)
        
        ; prevent further transfers
        lda #$01
        sta remainingScriptActions.w
        rts
      @notAllDone:
      sta subtitleAttributeTransferLineNum.w
      ; advance to next state
      lda newZpFreeReg+0
      clc
      adc #_sizeof_SubtitleCompBufferLineState
      sta subtitleAttributeTransferCurrentStatePtr+0.w
      sta newZpFreeReg+0
      cla
      adc newZpFreeReg+1
      sta subtitleAttributeTransferCurrentStatePtr+1.w
      sta newZpFreeReg+1
      
      ; check if next line actually has content and do nothing if not
      ldy #SubtitleCompBufferLineState.patternTransfersLeft
      lda (newZpFreeReg),Y
      bne +
        rts
      +:
      
      ; set up base x-pos from line width
      ldy #SubtitleCompBufferLineState.pixelW
      lda (newZpFreeReg),Y
      ; centering offset = (256 - width) / 2
      eor #$FF
      ina
      lsr
      sta subtitleDisplayQueueCurrentX.w
      
      ; initialize y-position based on line/group number
      ; if on first line of group
      lda subtitleAttributeTransferLineNum.w
      ; HACK: assume 2 lines per group
      lsr
      bcs @notFirstLineOfGroup
        tax
        lda group1RealLineCount.w,X
        ; multiply line count by 8, then subtract from base Y
        ; to center around target y-offset
        asl
        asl
        asl
        sec
        ; note: subtitleBaseY is now a 2-entry array for group1/group2
        sbc subtitleBaseY.w,X
        eor #$FF
        ina
        sta subtitleDisplayQueueCurrentY.w
        bra @yDone
      @notFirstLineOfGroup:
        ; move to next y-pos
        lda subtitleDisplayQueueCurrentY.w
        clc
        adc #spritePatternH
        sta subtitleDisplayQueueCurrentY.w
      @yDone:
      
      ; round dstptr up to the next even pattern number
      ; (so we can make use of double-width sprites)
/*      lda subtitleAttributeTransferVramPutPos+0.w
      and #$01
;      tst #$01,subtitleGraphicsTransferVramPutPos+0.w
      beq +
        inc subtitleAttributeTransferVramPutPos+0.w
        bne +
          inc subtitleAttributeTransferVramPutPos+1.w
      +: */
    @lineNotDone:
    
    ; determine output sprite width
;    ldy #SubtitleCompBufferLineState.patternTransfersLeft
;    lda (newZpFreeReg),Y
    ; if no patterns left (can only happen if a blank line),
    ; do nothing; next iteration will advance to next line
;    bne +
;      rts
;    +:
    
    ; determine output sprite width
    ; note: Y needs to be loaded here (it's used below and
    ; we don't want to branch over it)
    ldy #SubtitleCompBufferLineState.patternTransfersLeft
    ; if at a non-even pattern, one pattern wide
    lda subtitleAttributeTransferVramPutPos+0.w
    and #$01
    bne +
    ; otherwise, two patterns wide unless only one pattern left
;    ldy #SubtitleCompBufferLineState.patternTransfersLeft
    lda (newZpFreeReg),Y
    cmp #$01
    beq +
      lda #$02
    +:
    
    sta @spriteWidth.w
    tax
      ; update patternTransfersLeft
      lda (newZpFreeReg),Y
      sec
      sbc @spriteWidth.w
      sta (newZpFreeReg),Y
    ; restore number of patterns being transferred
    txa
    ; update currentPtr to next position
    ; multiply pattern count by size of plane (32)
    asl
    asl
    asl
    asl
    pha
      asl
      ; add to currentPtr
      ldy #SubtitleCompBufferLineState.currentPtr
      clc
      adc (newZpFreeReg),Y
      sta (newZpFreeReg),Y
      iny
      cla
      adc (newZpFreeReg),Y
      sta (newZpFreeReg),Y
      
      ; set up x-pos
      lda subtitleDisplayQueueCurrentX.w
      sta @xSetCmd+1.w
    pla
    ; add (patternCount*16) to x-pos
    clc
    adc subtitleDisplayQueueCurrentX.w
    sta subtitleDisplayQueueCurrentX.w
    
    ; set up attribute dstptr and advance attribute putpos
    lda subtitleDisplayBackQueuePutPos+0.w
    sta newZpFreeReg+0
    clc
    adc #<_sizeof_SpriteAttribute
    sta subtitleDisplayBackQueuePutPos+0.w
    lda subtitleDisplayBackQueuePutPos+1.w
    sta newZpFreeReg+1
    adc #>_sizeof_SpriteAttribute
    sta subtitleDisplayBackQueuePutPos+1.w
    
    cly
    
    ; Y
    lda subtitleDisplayQueueCurrentY.w
    clc
    adc #spriteAttrBaseY
    sta (newZpFreeReg),Y
    iny
    cla
    adc #$00
    sta (newZpFreeReg),Y
    iny
    
    ; X
    ; self-modifying
    @xSetCmd:
    lda #$00
    clc
    ; offset 1 pixel to the left because after generating the outline,
    ; the subtitles will take up 2 more pixels on the right
    adc #spriteAttrBaseX-1
    sta (newZpFreeReg),Y
    iny
    cla
    adc #$00
    sta (newZpFreeReg),Y
    iny
    
    ; pattern
    lda subtitleAttributeTransferVramPutPos+0.w
    asl
    sta (newZpFreeReg),Y
    iny
    lda subtitleAttributeTransferVramPutPos+1.w
    rol
    sta (newZpFreeReg),Y
    iny
    
    ; flags
    ; low byte
    ; apply palette
    ; (note: top bit set = high priority)
;    lda #$88
    lda #$80
    ora currentSubtitlePaletteIndex.w
    sta (newZpFreeReg),Y
    iny
    ; high byte
    ldx #$01
    lda @spriteWidth.w
    cmp #$01
    bne +
      ldx #$00
    +:
    txa
    sta (newZpFreeReg),Y
;    iny
    
    ; increment size of back queue
    lda subtitleDisplayQueueParity.w
    tax
    inc subtitleDisplayQueueSizeArray.w,X
    
    ; advance putpos to next pattern
    lda @spriteWidth.w
    clc
    adc subtitleAttributeTransferVramPutPos+0.w
    sta subtitleAttributeTransferVramPutPos+0.w
    cla
    adc subtitleAttributeTransferVramPutPos+1.w
    sta subtitleAttributeTransferVramPutPos+1.w
    
    rts
    
    @spriteWidth:
    .db $00
  
  doNextSpriteGrpTransfer:
    lda subtitleGraphicsTransferCurrentStatePtr+0.w
    sta newZpFreeReg+0
    lda subtitleGraphicsTransferCurrentStatePtr+1.w
    sta newZpFreeReg+1
    
    ; $FF in the line num indicates init needed
    lda subtitleGraphicsTransferLineNum.w
    bmi @startNextLine
    ldy #SubtitleCompBufferLineState.patternTransfersLeft
    lda (newZpFreeReg),Y
    bne @lineNotDone
      ; advance to next line
      lda subtitleGraphicsTransferLineNum.w
    @startNextLine:
      ina
      cmp activeLineCount.w
      bne @notAllDone
        ; everything is done: turn transfer flag off
        stz subtitleGraphicsTransferOn.w
        
        ; reset queue fields for graphics transfer
;        jsr resetAllStateQueueFields
        
        ; prevent further transfers
        lda #$01
        sta remainingScriptActions.w
        rts
      @notAllDone:
      sta subtitleGraphicsTransferLineNum.w
      ; advance to next state
      lda newZpFreeReg+0
      clc
      adc #_sizeof_SubtitleCompBufferLineState
      sta subtitleGraphicsTransferCurrentStatePtr+0.w
      sta newZpFreeReg+0
      cla
      adc newZpFreeReg+1
      sta subtitleGraphicsTransferCurrentStatePtr+1.w
      sta newZpFreeReg+1
      
      ; check if next line actually has content and do nothing if not
      ldy #SubtitleCompBufferLineState.patternTransfersLeft
      lda (newZpFreeReg),Y
      bne +
        rts
      +:
      
      ; set up base x-pos from line width
      ldy #SubtitleCompBufferLineState.pixelW
      lda (newZpFreeReg),Y
      ; centering offset = (256 - width) / 2
      eor #$FF
      ina
      lsr
      sta subtitleDisplayQueueCurrentX.w
      
      ; move to next y-pos
/*      lda subtitleDisplayQueueCurrentY.w
      clc
      adc #spritePatternH
      sta subtitleDisplayQueueCurrentY.w*/
      
      ; round dstptr up to the next even pattern number
      ; (so we can make use of double-width sprites)
/*      lda subtitleGraphicsTransferVramPutPos+0.w
      and #$01
;      tst #$01,subtitleGraphicsTransferVramPutPos+0.w
      beq +
        inc subtitleGraphicsTransferVramPutPos+0.w
        bne +
          inc subtitleGraphicsTransferVramPutPos+1.w
      +: */
    @lineNotDone:
  
    ;=====
    ; do vram write
    ;=====
    
    lda subtitleGraphicsTransferVramPutPos+0.w
    sta @vramDstLowerCmd+1.w
    lda subtitleGraphicsTransferVramPutPos+1.w
    ; multiply tilenum by 64 to get vram address
    .rept 6
      asl @vramDstLowerCmd+1.w
      rol
    .endr
    sta @vramDstUpperCmd+1.w
    
    inc subtitleGraphicsTransferVramPutPos+0.w
    bne +
      inc subtitleGraphicsTransferVramPutPos+1.w
    +:
    
    ; set vram dst
    st0 #$00
    @vramDstLowerCmd:
    ; self-modifying
    st1 #$00
    @vramDstUpperCmd:
    ; self-modifying
    st2 #$00
    
    ; start write
    st0 #$02
    
    ; do pattern conversion
;    ldx @spriteWidth.w
;    -:
      ; set src and advance to next pattern
      ldy #SubtitleCompBufferLineState.currentPtr
      lda (newZpFreeReg),Y
      sta @spritePlaneTransferCmd+1.w
      clc
      adc #<bytesPerSpritePatternPlane
      sta (newZpFreeReg),Y
      iny
      lda (newZpFreeReg),Y
      sta @spritePlaneTransferCmd+2.w
      adc #>bytesPerSpritePatternPlane
      sta (newZpFreeReg),Y
      
      ; no shadow
;      @spritePlaneTransferCmd:
;      tia $0000,$0002,bytesPerSpritePatternPlane
;      ; fill remaining planes with zero
;      tia zeroPlanes,$0002,bytesPerSpritePatternPlane*3
      
      ; generate drop shadow on row directly beneath sprite.
      ; simple, efficient, doesn't look good enough
/*      ldx #$02
      -:
        @spritePlaneTransferCmd:
        tia $0000,$0002,bytesPerSpritePatternPlane
        tia zeroPlanes,$0002,2
        dex
        bne -
      tia zeroPlanes,$0002,(bytesPerSpritePatternPlane*2)-2 */
      
/*      clx 
      -:
        @spritePlaneTransferCmd:
        lda $0000.w,X
        sta dropShadowBufferA.w,X
        inx
        cpx #bytesPerSpritePatternPlane
        bne - */
      
;      @spritePlaneTransferCmd:
;      tii $0000,dropShadowBufferA,bytesPerSpritePatternPlane
;      
;      ; copy first plane
;      tia dropShadowBufferA,$0002,bytesPerSpritePatternPlane
      
      ; shadow one pixel down and to the right
/*      ; right-shift (only lines that actually contain content)
      ldx #(numSubtitleFontCharTopPaddingLines*2)
      -:
        lda dropShadowBufferA+1.w,X
        lsr
;        ora dropShadowBufferA+1.w,X
        ora dropShadowBufferB+1.w,X
        sta dropShadowBufferA+1.w,X
        
        ror dropShadowBufferA+0.w,X
        cla
        ror
        sta dropShadowBufferB+1.w,X
        
        inx
        inx
        cpx #(bytesPerSpritePatternPlane-(numSubtitleFontCharBottomPaddingLines*2))
        bne - */
      
      ; shadow down and down-right
/*      ; right-shift (only lines that actually contain content)
      ldx #(numSubtitleFontCharTopPaddingLines*2)
      -:
        lda dropShadowBufferA+1.w,X
        lsr
        ora dropShadowBufferA+1.w,X
        ora dropShadowBufferB+1.w,X
        sta dropShadowBufferA+1.w,X
        
        lda dropShadowBufferA+0.w,X
        ror
        ora dropShadowBufferA+0.w,X
        sta dropShadowBufferA+0.w,X
        cla
        ror
        sta dropShadowBufferB+1.w,X
        
        inx
        inx
        cpx #(bytesPerSpritePatternPlane-(numSubtitleFontCharBottomPaddingLines*2))
        bne - */
      
      ; shadow down, right, and down-right
      ; right-shift (only lines that actually contain content)
/*      ldx #(numSubtitleFontCharTopPaddingLines*2)
      -:
        lda dropShadowBufferA+1.w,X
        lsr
        ora dropShadowBufferA+1.w,X
        ora dropShadowBufferB+1.w,X
        sta dropShadowBufferA+1.w,X
        ora dropShadowBufferA-1.w,X
        sta dropShadowBufferA-1.w,X
        
        lda dropShadowBufferA+0.w,X
        ror
        ora dropShadowBufferA+0.w,X
        sta dropShadowBufferA+0.w,X
        ora dropShadowBufferA-2.w,X
        sta dropShadowBufferA-2.w,X
        cla
        ror
        sta dropShadowBufferB+1.w,X
;        sta dropShadowBufferB-1.w,X
        
        inx
        inx
        cpx #(bytesPerSpritePatternPlane-(numSubtitleFontCharBottomPaddingLines*2))
        bne - */
      
/*      @spritePlaneTransferCmd:
      tii $0000,dropShadowBufferA,bytesPerSpritePatternPlane
      
      ; copy first plane
      tia dropShadowBufferA,$0002,bytesPerSpritePatternPlane
      
      ; D-DR-R with unrolled loop
      .rept linesPerRawSceneFontChar INDEX count
        lda dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        lsr
        ora dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA-1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA-1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        
        lda dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ror
        ora dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA-2+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA-2+((numSubtitleFontCharTopPaddingLines+count)*2).w
        cla
        ror
        sta dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
      .endr */
      
      ; JUST OUTLINE EVERYTHING BECAUSE I WILL NEVER BE SATISFIED OTHERWISE
      
      @spritePlaneTransferCmd:
      tii $0000,charShiftBufferA,bytesPerSpritePatternPlane
      tii charShiftBufferA,dropShadowBufferA,bytesPerSpritePatternPlane
      
      .rept linesPerRawSceneFontChar INDEX count
        lda charShiftBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        lsr
        ora charShiftBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta charShiftBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        
        lda charShiftBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ror
        sta charShiftBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        
        cla
        ror
        sta charShiftBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
      .endr
      
      ; copy first plane
      tia charShiftBufferA,$0002,bytesPerSpritePatternPlane
      
      .rept linesPerRawSceneFontChar INDEX count
        lda charShiftBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        lsr
;        ora charShiftBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
;        sta charShiftBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
;        ora dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        
        lda charShiftBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ror
;        sta charShiftBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ora dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferA+0+((numSubtitleFontCharTopPaddingLines+count)*2).w
        
        lda dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        ror
;        sta charShiftBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
        sta dropShadowBufferB+1+((numSubtitleFontCharTopPaddingLines+count)*2).w
      .endr
      
      ; copy remaining planes
;      tia dropShadowBufferA-2,$0002,(bytesPerSpritePatternPlane*3)
      tia dropShadowBufferA-2,$0002,bytesPerSpritePatternPlane
      tia dropShadowBufferA+0,$0002,bytesPerSpritePatternPlane
      tia dropShadowBufferA+2,$0002,bytesPerSpritePatternPlane
      
;      dex
;      bne -
  
    ;=====
    ; update fields
    ;=====
    
    ; decrement patterns remaining counter
    ldy #SubtitleCompBufferLineState.patternTransfersLeft
    lda (newZpFreeReg),Y
    dea
    sta (newZpFreeReg),Y
    
    ; advance currentPtr to next pattern
/*    ldy #SubtitleCompBufferLineState.currentPtr
    lda (newZpFreeReg),Y
    clc
    adc #bytesPerSpritePatternPlane
    sta (newZpFreeReg),Y
    iny
    cla
    adc (newZpFreeReg),Y
    sta (newZpFreeReg),Y */
    
    rts
    
  
  ; pre-padding to allow for single transfer of last 3 planes
  dropShadowBufferAPrePad:
    .dw $0000
  dropShadowBufferA:
    .ds bytesPerSpritePatternPlane,$00
  dropShadowBufferAEnd:
  ; speed up transfer of null planes
  zeroPlanes:
;    .ds bytesPerSpritePatternPlane*3,$00
;    .ds bytesPerSpritePatternPlane*2,$00
    ; actually, this is useful for clearing out VRAM,
    ; so let's just make it a full 256 bytes
    .ds 256,$00
  
  dropShadowBufferB:
    .ds bytesPerSpritePatternPlane,$00
  dropShadowBufferBEnd:
  
  charShiftBufferA:
    .ds bytesPerSpritePatternPlane,$00
  charShiftBufferAEnd:
  charShiftBufferB:
    .ds bytesPerSpritePatternPlane,$00
  charShiftBufferBEnd:
  
  runScript:
    cly
    
    lda (newZpScriptReg),Y
    cmp #sceneFontCharsBase
    bcc @isOpcode
    
    @isLiteral:
      jsr printSubtitleChar
      lda #$01
      jmp addToScriptPtr
    @isOpcode:
      cmp #sceneOp_terminator
;      beq @done
      bne +
        ; terminator: prevent further actions
        lda #$01
        sta remainingScriptActions.w
        bra @done
      +:
    
      @doGenericSceneOp:
      asl
      tax
/*      lda subtitleOpJumpTable+0.w,X
      sta @sceneOpJumpCmd+1.w
      lda subtitleOpJumpTable+1.w,X
      sta @sceneOpJumpCmd+2.w
      @sceneOpJumpCmd:
      jmp $0000 */
      ; lol i forgot this addressing mode existed for jmp
      jmp (subtitleOpJumpTable,X)
      
;      cmp #sceneOp_waitForFrame
;      bne @doGenericSceneOp
      
      ;=====
      ; wait until target framenum
      ;=====
      
/*      iny
      lda (newZpScriptReg),Y
      cmp syncFrameCounter.w
      bne @endCurrentIteration
      iny
      lda (newZpScriptReg),Y
      cmp syncFrameCounter+1.w */
    
    @done:
    rts
  
  subtitleOpJumpTable:
    ; 00 = terminator (special-cased)
    .dw $0000
    ; 01 = sceneOp_waitForFrame
    .dw sceneOp_waitForFrame_handler
    ; 02 = sceneOp_br
    .dw sceneOp_br_handler
    ; 03 = sceneOp_resetCompBuffers
    .dw sceneOp_resetCompBuffers_handler
    ; 04
    .dw sceneOp_prepAndSendGrp_handler
    ; 05
    .dw sceneOp_swapAndShowBuf_handler
    ; 06
    .dw sceneOp_subsOff_handler
    ; 07
    .dw sceneOp_finishCurrentLine_handler
    ; 08
    .dw sceneOp_setPalette_handler
    ; 09
    .dw sceneOp_setHighPrioritySprObjOffset_handler
    ; 0A
    .dw sceneOp_setLowPrioritySprObjOffset_handler
    ; 0B
;    .dw sceneOp_resetSyncTimer_handler
;    .dw sceneOp_subtractFromSyncTimer_handler
    .dw sceneOp_writeVramFromSlot_handler
    ; 0C
    .dw sceneOp_writePalette_handler
    ; 0D
    .dw sceneOp_writeVram_handler
    ; 0E
    .dw sceneOp_waitForAdpcm_handler
    ; 0F
    .dw sceneOp_queueSubsOff_hander
    ; 10
    .dw sceneOp_writeMem_hander
    ; 11
    .dw sceneOp_andOr_hander
    ; 12
    .dw sceneOp_showWithAltSat_handler
    ; 13
    .dw sceneOp_writeBackQueueToAltSat_handler
    ; 14
    .dw sceneOp_swapBuf_handler
    ; 15
    .dw sceneOp_prepSpriteAttr_handler
    ; 16
    .dw sceneOp_setSpriteFlood_handler
  
  sceneOp_waitForFrame_handler:
    iny
    lda (newZpScriptReg),Y
    sec
    sbc syncFrameCounter.w
    iny
    lda (newZpScriptReg),Y
    sbc syncFrameCounter+1.w
    bcs @endCurrentIteration
      tya
      ina
      jmp addToScriptPtr
    @endCurrentIteration:
    lda #$01
    sta remainingScriptActions.w
    rts
  
  sceneOp_br_handler:
    jsr finishCurrentSubtitleBufferLine
    
    lda #$01
    jmp addToScriptPtr
  
  sceneOp_resetCompBuffers_handler:
    jsr resetSubtitleCompBuffers
    
    ; HACK: enable sprite crop minimize when this is turned on
    ; (so it's off in scenes that don't use subtitles at all)
    lda #$FF
    sta spriteCropMinimize_on.w
    
    lda #$01
    jmp addToScriptPtr
  
  sceneOp_prepSpriteAttr_handler:
    ; do normal prep setup...
    bsr sceneOp_prepAndSendGrp_handler
    ; ...but prevent the graphics from being sent
    stz subtitleGraphicsTransferOn.w
    rts
  
  sceneOp_prepAndSendGrp_handler:
    ; reset sprite attribute putpos
/*    lda #<activeSubtitleSpriteAttributeQueue
    sta activeSubtitleSpriteAttributeQueuePutPos+0.w
    lda #>activeSubtitleSpriteAttributeQueue
    sta activeSubtitleSpriteAttributeQueuePutPos+1.w
    ; reset queue size
    stz activeSubtitleSpriteAttributeQueueSize.w */
    
    lda subtitleDisplayQueueParity.w
;    ina
;    and #$01
;    sta subtitleDisplayQueueParity.w
    ; reset back queue's size
    pha
      tax
      stz subtitleDisplayQueueSizeArray.w,X
    pla
    ; reset write pos for back queue
    asl
    tax
    lda subtitleDisplayQueuePointerArray+0.w,X
    sta subtitleDisplayBackQueuePutPos+0.w
    lda subtitleDisplayQueuePointerArray+1.w,X
    sta subtitleDisplayBackQueuePutPos+1.w
;    stz subtitleDisplayBackQueuePutPos.w
    
    ; set up procedural graphics transfer
    ; initialize these fields to one before the actual
    ; target value so that they'll get initialized properly
    lda #<(subtitleStates-_sizeof_SubtitleCompBufferLineState)
    sta subtitleAttributeTransferCurrentStatePtr+0.w
    sta subtitleGraphicsTransferCurrentStatePtr+0.w
    lda #>(subtitleStates-_sizeof_SubtitleCompBufferLineState)
    sta subtitleAttributeTransferCurrentStatePtr+1.w
    sta subtitleGraphicsTransferCurrentStatePtr+1.w
;    sta subtitleAttributeTransferEndLineNum.w
    
    ; initialize y-position
    ; multiply line count by 8, then subtract from base Y
    ; to center around target y-offset
    ; (moved into sprite attr line init code to allow for group1/group2
    ; distinction)
/*    lda activeLineCount.w
    asl
    asl
    asl
    sec
    sbc subtitleBaseY.w
    eor #$FF
    ina
    ; subtract 16 because that will be added during line initialization
    sec
    sbc #spritePatternH
    sta subtitleDisplayQueueCurrentY.w*/
    
;    stz subtitleAttributeTransferLineNum.w
    ; set initial line number to #$FF to indicate initialization needed
    lda #$FF
    sta subtitleAttributeTransferLineNum.w
    sta subtitleGraphicsTransferLineNum.w
    ; get dst tile num from op args
    iny
    lda (newZpScriptReg),Y
    sta subtitleAttributeTransferVramPutPos+0.w
    sta subtitleGraphicsTransferVramPutPos+0.w
    iny
    lda (newZpScriptReg),Y
    sta subtitleAttributeTransferVramPutPos+1.w
    sta subtitleGraphicsTransferVramPutPos+1.w
    
    ; left-shift graphics transfer addr to vram address
;    .rept 6
;      asl subtitleGraphicsTransferVramPutPos+0.w
;      rol subtitleGraphicsTransferVramPutPos+1.w
;    .endr
    
    inc subtitleAttributeTransferOn.w
    inc subtitleGraphicsTransferOn.w
    
    ; prevent further evaluation of script until transfer completes
    lda #$01
    sta remainingScriptActions.w
    
    lda #$03
    jmp addToScriptPtr
  
  sceneOp_swapBuf_handler:
    ; do normal activation logic...
    bsr sceneOp_swapAndShowBuf_handler
    ; ...but don't turn subtitle display on
    stz subtitleDisplayOn.w
    rts
  
  sceneOp_swapAndShowBuf_handler:
    lda subtitleDisplayQueueParity.w
    pha
      tax
      lda subtitleDisplayQueueSizeArray.w,X
      ; *8 to get size in bytes
      ; (we assume there will never be more than 31 sprites)
      asl
      asl
      asl
      sta currentSubtitleSpriteAttributeQueueSize.w
      
      txa
      asl
      tax
      
      lda subtitleDisplayQueuePointerArray+0.w,X
      sta currentSubtitleSpriteAttributeQueuePtr+0.w
      lda subtitleDisplayQueuePointerArray+1.w,X
      sta currentSubtitleSpriteAttributeQueuePtr+1.w
      
      lda activeLineCount.w
      sta currentSubtitleActiveLineCount.w
    pla
    ina
    and #$01
    sta subtitleDisplayQueueParity.w
    ; will be 01 or 02; all that matters is that it's nonzero
    ina
    sta subtitleDisplayOn.w
    
    ; reset composition buffers for next string
    jsr resetSubtitleCompBuffers
    
    lda #$01
    jmp addToScriptPtr
  
  sceneOp_subsOff_handler:
    jsr turnSubsOff
    
    ; prevent further evaluation of script
    lda #$01
    sta remainingScriptActions.w
    
    lda #$01
    jmp addToScriptPtr
  
  sceneOp_finishCurrentLine_handler:
    jsr finishCurrentSubtitleBufferLine
    lda #$01
    jmp addToScriptPtr
  
  sceneOp_setPalette_handler:
    iny
    lda (newZpScriptReg),Y
    sta currentSubtitlePaletteIndex.w
    
    lda #$02
    jmp addToScriptPtr
  
  sceneOp_setHighPrioritySprObjOffset_handler:
    iny
    lda (newZpScriptReg),Y
    sta highPrioritySpriteObjGenerationOffset.w
    
    lda #$02
    jmp addToScriptPtr
    
  sceneOp_setLowPrioritySprObjOffset_handler:
    iny
    lda (newZpScriptReg),Y
    sta lowPrioritySpriteObjGenerationOffset.w
    
    lda #$02
    jmp addToScriptPtr
  
;  sceneOp_resetSyncTimer_handler:
;    cla
;    sta syncFrameCounter+0.w
;    sta syncFrameCounter+1.w
;    
;    ina
;    jmp addToScriptPtr
  
;  sceneOp_subtractFromSyncTimer_handler:
;    lda syncFrameCounter+0.w
;    iny
;    sec
;    sbc (newZpScriptReg),Y
;    sta syncFrameCounter+0.w
;    
;    lda syncFrameCounter+1.w
;    iny
;    sbc (newZpScriptReg),Y
;    sta syncFrameCounter+1.w
;    
;    lda #$03
;    jmp addToScriptPtr
  
  sceneOp_writeVramFromSlot_handler:
    tma #$40
    pha
      ; bank
      iny
      lda (newZpScriptReg),Y
      tam #$40
      
      jsr sceneOp_writeVram_handler
    pla
    tam #$40
    rts
  
  sceneOp_writePalette_handler:
    ; src
    lda newZpScriptReg+0
    clc
    adc #$05
    sta @transferCmd.w+1
    cla
    adc newZpScriptReg+1
    sta @transferCmd.w+2
    
    ; size
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+5.w
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+6.w
    
    ; dst
    iny
    lda (newZpScriptReg),Y
;    sta @addrCmdLo+1.w
    sta vce_ctaLo.w
    iny
    lda (newZpScriptReg),Y
;    sta @addrCmdHi+1.w
    sta vce_ctaHi.w
    
;      @addrCmdLo:
;      lda #$00
;      sta vce_ctaLo.w
;      @addrCmdHi:
;      lda #$00
;      sta vce_ctaHi.w
      ; copy colors to vce
      @transferCmd:
      tia $0000,vce_ctwLo,$0000
    
    ; add size to script ptr
    lda newZpScriptReg+0
    clc
    adc @transferCmd+5.w
    sta newZpScriptReg+0
    lda newZpScriptReg+1
    adc @transferCmd+6.w
    sta newZpScriptReg+1
    
    ; prevent further evaluation of script
    lda #$01
    sta remainingScriptActions.w
    
    ; add base size to script ptr
    lda #$05
    jmp addToScriptPtr
  
  ; note: it is the caller's responsibility
  ; not to transfer too much at a time
  sceneOp_writeVram_handler:
    ; src
;    lda newZpScriptReg+0
;    clc
;    adc #$05
;    sta @transferCmd.w+1
;    cla
;    adc newZpScriptReg+1
;    sta @transferCmd.w+2
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+1.w
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+2.w
    
    ; size
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+5.w
    iny
    lda (newZpScriptReg),Y
    sta @transferCmd+6.w
    
    ; dst
    iny
    lda (newZpScriptReg),Y
    sta @addrCmdLo+1.w
    iny
    lda (newZpScriptReg),Y
    sta @addrCmdHi+1.w
      
      st0 #$00
      @addrCmdLo:
      st1 #$00
      @addrCmdHi:
      st2 #$00
      st0 #$02
      
      @transferCmd:
      tia $0000,$0002,$0000
    
    ; add size to script ptr
;    lda newZpScriptReg+0
;    clc
;    adc @transferCmd+5.w
;    sta newZpScriptReg+0
;    lda newZpScriptReg+1
;    adc @transferCmd+6.w
;    sta newZpScriptReg+1
    
    ; prevent further evaluation of script
    lda #$01
    sta remainingScriptActions.w
    
    ; add base size to script ptr
;    lda #$07
    tya
    ina
    jmp addToScriptPtr
  
  sceneOp_waitForAdpcm_handler:
    iny
    lda (newZpScriptReg),Y
    cmp adpcmSyncCounter.w
    beq @done
    bcs @notDone
    @done:
      ; subtract actual trigger time of last adpcm event
      ; from current time.
      ; this accounts for any possible time overrun
      ; (e.g. if a line was still being rendered at the time
      ; the waitForAdpcm event was supposed to occur, causing
      ; it to trigger late)
      lda syncFrameCounter+0.w
      sec
      sbc syncFrameCounterAtLastAdpcmSync+0.w
      sta syncFrameCounter+0.w
      
      lda syncFrameCounter+1.w
      sbc syncFrameCounterAtLastAdpcmSync+1.w
      sta syncFrameCounter+1.w
      
      ; prevent further evaluation of script
      ; (to ensure that the next script action begins at
      ; a frame boundary, for better synchronization)
      lda #$01
      sta remainingScriptActions.w
      
      tya
      ina
      jmp addToScriptPtr
    @notDone:
    ; prevent further evaluation of script
    lda #$01
    sta remainingScriptActions.w
    rts
  
  sceneOp_queueSubsOff_hander:
    iny
    lda (newZpScriptReg),Y
    sta queuedSubsOffTime+0.w
    iny
    lda (newZpScriptReg),Y
    sta queuedSubsOffTime+1.w
    
    tya
    ina
    sta queuedSubsOffIsOn.w
    jmp addToScriptPtr
  
  sceneOp_writeMem_hander:
    iny
    lda (newZpScriptReg),Y
    sta @dstOp+1.w
    iny
    lda (newZpScriptReg),Y
    sta @dstOp+2.w
    iny
    lda (newZpScriptReg),Y
    sta @valueOp+1.w
    
    @valueOp:
    lda #$00
    @dstOp:
    sta $0000.w
    
    tya
    ina
    jmp addToScriptPtr
  
  sceneOp_andOr_hander:
    iny
    lda (newZpScriptReg),Y
    sta @dstOp+1.w
    sta @srcOp+1.w
    iny
    lda (newZpScriptReg),Y
    sta @dstOp+2.w
    sta @srcOp+2.w
    iny
    lda (newZpScriptReg),Y
    sta @andOp+1.w
    iny
    lda (newZpScriptReg),Y
    sta @orOp+1.w
    
    @srcOp:
    lda $0000.w
    @andOp:
    and #$00
    @orOp:
    ora #$00
    @dstOp:
    sta $0000.w
    
    tya
    ina
    jmp addToScriptPtr
  
  sceneOp_showWithAltSat_handler:
    ; read target sat address and set up mawr
    iny
    lda (newZpScriptReg),Y
    sta @satAddrLoOp+1.w
    iny
    lda (newZpScriptReg),Y
    sta @satAddrHiOp+1.w
    
    ; force satb to specified location
    st0 #$13
    @satAddrLoOp:
    st1 #$00
    @satAddrHiOp:
    st2 #$00
    
    tya
    ina
    jmp addToScriptPtr
  
  sceneOp_writeBackQueueToAltSat_handler:
    ; read target sat address and set up mawr
    iny
    st0 #$00
    lda (newZpScriptReg),Y
;    sta @satAddrLoOp+1.w
    sta $0002.w
    iny
    lda (newZpScriptReg),Y
;    sta @satAddrHiOp+1.w
    sta $0003.w
    st0 #$02
    
    ; copy current sprite attribute queue to SAT
;    lda currentSubtitleSpriteAttributeQueuePtr+0.w
;    sta @transferToSatCmd+1.w
;    lda currentSubtitleSpriteAttributeQueuePtr+1.w
;    sta @transferToSatCmd+2.w
    
;    lda currentSubtitleSpriteAttributeQueueSize.w

    ldx subtitleDisplayQueueParity.w
    lda subtitleDisplayQueueSizeArray.w,X
    ; *8 to get size in bytes
    ; (we assume there will never be more than 31 sprites)
    asl
    asl
    asl
    sta @transferToSatCmd+5.w
    ; first clear
    sta @clearToSatCmd+5.w
    ; invert and multiply by 2 to get size of remaining area to clear
    eor #$FF
    ina
    sta @clearToSatCmd2+5.w
    sta @clearToSatCmd3+5.w
    
    txa
    asl
    tax
    lda subtitleDisplayQueuePointerArray+0.w,X
    sta @transferToSatCmd+1.w
    lda subtitleDisplayQueuePointerArray+1.w,X
    sta @transferToSatCmd+2.w
    
;    sta @transferToSatCmd+5.w
;    ; first clear
;    sta @clearToSatCmd+5.w
;    ; invert and multiply by 2 to get size of remaining area to clear
;    eor #$FF
;    ina
;    sta @clearToSatCmd2+5.w
;    sta @clearToSatCmd3+5.w
    
    @transferToSatCmd:
    tia $0000,$0002,$0000
    
    ; blank out rest of table
    @clearToSatCmd:
    tia zeroPlanes,$0002,$0000
    @clearToSatCmd2:
    tia zeroPlanes,$0002,$0000
    @clearToSatCmd3:
    tia zeroPlanes,$0002,$0000
    
    ; force satb to specified location
;    st0 #$13
;    @satAddrLoOp:
;    st1 #$00
;    @satAddrHiOp:
;    st2 #$00
    
    ; prevent further evaluation of script
    lda #$01
    sta remainingScriptActions.w
    
    tya
    ina
    jmp addToScriptPtr
  
  sceneOp_setSpriteFlood_handler:
    ; index
    iny
    lda (newZpScriptReg),Y
    tax
    ; count
    iny
    lda (newZpScriptReg),Y
    sta spriteFloodCount.w,X
    ; y-pos
    iny
    lda (newZpScriptReg),Y
    sta spriteFloodY.w,X
    
    tya
    ina
    jmp addToScriptPtr
  
  addToScriptPtr:
    clc
    adc newZpScriptReg
    sta newZpScriptReg
    cla
    adc newZpScriptReg+1
    sta newZpScriptReg+1
    rts
  
/*  getNextScriptByte:
    @getCmd:
    lda subtitleScriptData.w
    rts
  
  incScript:
    @getCmd:
    inc getNextScriptByte@getCmd+1.w
    bne +
      inc getNextScriptByte@getCmd+2.w
    +:
    rts */
  
  ; newZpFreeReg = state buffer pointer
  ; X = line number
;  prepBufferedLineForDisplay:
;    ; TODO
;    rts
  
  ; A = raw codepoint
  printSubtitleChar:
    ; clear char comp buffer
;    pha
      jsr clearSubtitleCharCompBuffer
;    pla
    
    ; convert from raw codepoint to font index
    sec
    sbc #sceneFontCharsBase
    
    pha
      ; look up pointer to target char
      asl
      tax
      lda fontLut+0.w,X
      sta newZpFreeReg+0
      lda fontLut+1.w,X
      sta newZpFreeReg+1
      
      ; copy bitmap to buffer
      ; x starts at (targetLine * 3),
      ; because we want a blank line at the top
      ; to allow for potential outline effects there
      ldx #bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines
      ; bitshift optimization
      lda activeSubtitleXPos.w
      and #$0F
      cmp #$05
      bcc +
        inx
      +:
      cmp #$0D
      bcc +
        inx
      +:
      cly
      -:
        lda (newZpFreeReg),Y
        sta subtitleCharCompBuffer.w,X
        iny
        inx
        inx
        inx
        cpx #(bytesPerSceneFontChar*3)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        bcc -
      
      ; NOTE: for future reference, here is the original shift routine
      ; before the more space-intensive loop unrolling was applied...
/*      ; apply right-shift to data
      lda activeSubtitleXPos.w
      and #$0F
      beq @noRightShift
      cmp #$05
      bcc @rightShiftLeftTwo
      cmp #$09
      bcc @leftShiftLeftTwo
      cmp #$0D
      bcc @rightShiftRightTwo
      @leftShiftRightTwo:
        eor #$FF
        ina
        and #$03
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            asl subtitleCharCompBuffer+2.w,X
            rol subtitleCharCompBuffer+1.w,X
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc --
        bra @noRightShift
      @rightShiftLeftTwo:
        and #$07
        beq @noRightShift
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            lsr subtitleCharCompBuffer+0.w,X
            ror subtitleCharCompBuffer+1.w,X
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc --
        bra @noRightShift
      @leftShiftLeftTwo:
        and #$07
        beq @noRightShift
        eor #$FF
        ina
        and #$03
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            asl subtitleCharCompBuffer+1.w,X
            rol subtitleCharCompBuffer+0.w,X
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc --
        bra @noRightShift
      @rightShiftRightTwo:
        and #$07
        beq @noRightShift
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            lsr subtitleCharCompBuffer+1.w,X
            ror subtitleCharCompBuffer+2.w,X
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc -- */
      
      ; apply right-shift to data
      lda activeSubtitleXPos.w
      and #$0F
      bne +
        jmp @noRightShift
      +:
      cmp #$05
      bcs +
        jmp @rightShiftLeftTwo
      +:
      cmp #$09
      bcs +
        jmp @leftShiftLeftTwo
      +:
      cmp #$0D
      bcs +
        jmp @rightShiftRightTwo
      +:
      @leftShiftRightTwo:
        eor #$FF
        ina
        and #$03
        dea
        bne +
          jmp @leftShiftRightTwo_shift1
        +:
        dea
        bne +
          jmp @leftShiftRightTwo_shift2
        +:
        @leftShiftRightTwo_shift3:
          leftShiftRightTwoLoop
        @leftShiftRightTwo_shift2:
          leftShiftRightTwoLoop
        @leftShiftRightTwo_shift1:
          leftShiftRightTwoLoop
        jmp @noRightShift
      @rightShiftLeftTwo:
        and #$07
        bne +
          jmp @noRightShift
        +:
        dea
        bne +
          jmp @rightShiftLeftTwo_shift1
        +:
        dea
        bne +
          jmp @rightShiftLeftTwo_shift2
        +:
        dea
        bne +
          jmp @rightShiftLeftTwo_shift3
        +:
        ; shift only the lines that are not empty
        @rightShiftLeftTwo_shift4:
          rightShiftLeftTwoLoop
        @rightShiftLeftTwo_shift3:
          rightShiftLeftTwoLoop
        @rightShiftLeftTwo_shift2:
          rightShiftLeftTwoLoop
        @rightShiftLeftTwo_shift1:
          rightShiftLeftTwoLoop
        jmp @noRightShift
      @leftShiftLeftTwo:
        and #$07
        bne +
          jmp @noRightShift
        +:
        eor #$FF
        ina
        and #$03
        
        dea
        bne +
          jmp @leftShiftLeftTwo_shift1
        +:
        dea
        bne +
          jmp @leftShiftLeftTwo_shift2
        +:
        @leftShiftLeftTwo_shift3:
          leftShiftLeftTwoLoop
        @leftShiftLeftTwo_shift2:
          leftShiftLeftTwoLoop
        @leftShiftLeftTwo_shift1:
          leftShiftLeftTwoLoop
        jmp @noRightShift
      @rightShiftRightTwo:
        and #$07
        bne +
          jmp @noRightShift
        +:
        dea
        bne +
          jmp @rightShiftRightTwo_shift1
        +:
        dea
        bne +
          jmp @rightShiftRightTwo_shift2
        +:
        dea
        bne +
          jmp @rightShiftRightTwo_shift3
        +:
        ; shift only the lines that are not empty
        @rightShiftRightTwoo_shift4:
          rightShiftRightTwoLoop
        @rightShiftRightTwo_shift3:
          rightShiftRightTwoLoop
        @rightShiftRightTwo_shift2:
          rightShiftRightTwoLoop
        @rightShiftRightTwo_shift1:
          rightShiftRightTwoLoop
      
/*      and #$07
      beq @noRightShift
      cmp #$05
      bcc @doRightShift
      @doLeftShift:
        eor #$FF
        ina
        and #$03
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            asl subtitleCharCompBuffer+2.w,X
            rol subtitleCharCompBuffer+1.w,X
            rol subtitleCharCompBuffer+0.w,X
            
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc --
        bra @noRightShift
      @doRightShift:
;        clx
        ; shift only the lines that are not empty
        ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        --:
        tay
          -:
            lsr subtitleCharCompBuffer+0.w,X
            ror subtitleCharCompBuffer+1.w,X
            ror subtitleCharCompBuffer+2.w,X
            
            dey
            bne -
          inx
          inx
          inx
          cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
          bcc -- */
      
      @noRightShift:
      
      ; merge with current pattern
      lda activeSubtitleCompBufferPtr+0.w
      sta newZpFreeReg+0
      lda activeSubtitleCompBufferPtr+1.w
      sta newZpFreeReg+1
      
;      clx
      ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
;      cly
      ldy #(numSubtitleFontCharTopPaddingLines*2)
      -:
        ; get left pattern
        lda (newZpFreeReg),Y
        ; OR with char buffer
        ; (note that the endianness is swapped here
        ; to match the output sprite format)
        ora subtitleCharCompBuffer+1.w,X
        ; write back
        sta (newZpFreeReg),Y
        iny
        
        ; repeat for right pattern
        lda (newZpFreeReg),Y
        ora subtitleCharCompBuffer+0.w,X
        sta (newZpFreeReg),Y
        iny
        
        inx
        inx
        inx
;        cpy #spritePatternH*2
        cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        bcc -
    
    ; restore character index
    pla
    
    ; get char width and add to x-pos
    tax
    ; save currentX/16
    lda activeSubtitleXPos.w
    pha
;      lsr
;      lsr
;      lsr
;      lsr
      and #$F0
      sta @spanCheck+1.w
    pla
    clc
    adc fontWidthTable.w,X
    sta activeSubtitleXPos.w
    ; check currentX/16 against newX/16
;    lsr
;    lsr
;    lsr
;    lsr
    and #$F0
    ; self-modifying
    @spanCheck:
    cmp #$00
    ; if currentX/16 != newX/16, transfer spans two patterns
    ; (or goes exactly to end of current one)
    beq @noSpan
      
      ; note that there is an extra pattern at the end of the buffer
      ; to account for the rare possibility that every single available
      ; pattern is filled to capacity, and this routine attempts to
      ; initialize the "next" pattern (which nominally shouldn't exist)
      
      ; advance to next pattern
      jsr advanceActiveSubtitleCompBufferPtrToNextPattern
      ; copy right side of char comp buffer to left side of new buffer
;      clx
      ldx #(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
;      cly
      ; targeting NEXT pattern after the initial one
      ; and we are swapping the endianness, so target is +1
      ldy #bytesPerSpritePatternPlane+1+(numSubtitleFontCharTopPaddingLines*2)
      -:
        lda subtitleCharCompBuffer+2.w,X
        sta (newZpFreeReg),Y
        
        iny
        iny
        inx
        inx
        inx
;        cpx #spritePatternH*bytesPerSubtitleCharCompBufferLine
        cpx #(linesPerRawSceneFontChar*bytesPerSubtitleCharCompBufferLine)+(bytesPerSubtitleCharCompBufferLine*numSubtitleFontCharTopPaddingLines)
        bcc -
    @noSpan:
    
    rts
  
  ; used to clear out memory blocks with TAI
  blockClearWord:
    .dw $0000
    
  clearSubtitleCharCompBuffer:
    tai blockClearWord,subtitleCharCompBuffer,subtitleCharCompBufferSize
    rts
  
  resetAllStateQueueFields:
    lda #<subtitleStates
    sta newZpFreeReg+0
    lda #>subtitleStates
    sta newZpFreeReg+1
    ldx activeLineCount.w
    -:
      jsr resetSubtitleStateQueueFields
      
      ; advance to next state
      lda newZpFreeReg+0
      clc
      adc #_sizeof_SubtitleCompBufferLineState
      sta newZpFreeReg+0
      cla
      adc newZpFreeReg+1
      sta newZpFreeReg+1
      
      dex
      bne -
    
    rts
  
  ; newZpFreeReg = pointer to state
  resetSubtitleStateQueueFields:
    ; copy numPatterns to patternTransfersLeft
    ldy #SubtitleCompBufferLineState.numPatterns
    lda (newZpFreeReg),Y
    iny
    sta (newZpFreeReg),Y
    
    ; copy startPtr to currentPtr
    ldy #SubtitleCompBufferLineState.startPtr
    lda (newZpFreeReg),Y
    pha
      iny
      lda (newZpFreeReg),Y
      ldy #SubtitleCompBufferLineState.currentPtr+1
      sta (newZpFreeReg),Y
    pla
    dey
    sta (newZpFreeReg),Y
    rts
  
  resetSubtitleCompBuffers:
    ; clear all existing buffer content
    tai blockClearWord,bufferResetArea,endOfBufferResetArea-bufferResetArea
    
    ; reset current buffer pointer, and first state's buffer pointer,
    ; to start of buffer
    lda #<subtitleCompBuffers
    sta activeSubtitleCompBufferPtr+0.w
    sta subtitleStates+SubtitleCompBufferLineState.startPtr+0.w
    lda #>subtitleCompBuffers
    sta activeSubtitleCompBufferPtr+1.w
    sta subtitleStates+SubtitleCompBufferLineState.startPtr+1.w
    
    ; reset active state pointer to first state
    lda #<subtitleStates
    sta activeSubtitleStatePtr+0.w
    lda #>subtitleStates
    sta activeSubtitleStatePtr+1.w
    
    rts
  
  advanceActiveSubtitleCompBufferPtrToNextPattern:
    lda activeSubtitleCompBufferPtr+0.w
    clc
    adc #bytesPerSpritePatternPlane
    sta activeSubtitleCompBufferPtr+0.w
    sta @clearCmd+3.w
    cla
    adc activeSubtitleCompBufferPtr+1.w
    sta activeSubtitleCompBufferPtr+1.w
    sta @clearCmd+4.w
    
    ; clear next pattern
    ; self-modifying
    @clearCmd:
    tai blockClearWord,$0000,bytesPerSpritePatternPlane
    
    rts
  
  finishCurrentSubtitleBufferLine:
    ; copy pointer to zp reg for access
    lda activeSubtitleStatePtr+0.w
    sta newZpFreeReg+0
    lda activeSubtitleStatePtr+1.w
    sta newZpFreeReg+1
    
    ; set final width
    lda activeSubtitleXPos.w
    ldy #SubtitleCompBufferLineState.pixelW
    sta (newZpFreeReg),Y
    pha
      ; set numPatterns
      iny
      
      ; special case:
      ; if pixelX == 0 (i.e. a blank line), output pattern count is zero.
      ; this is needed when breaking lines to reach the next group.
      and #$FF
      beq @writePatternSize
      
      ; (pixelX - 1)/16 yields the correct number.
      ; HOWEVER: due to a subsequent change in the font shadow generator,
      ; we now need a two-pixel margin on the right edge.
      ; a one-pixel margin is guaranteed by the font itself
      ; (every character has a pixel of space on the right).
      ; but we need a second one here to allow space for the rightmost
      ; pixel column of the outline.
      ; due to fortuitous laziness in the pattern initialization code,
      ; a pixelX that is divisible by 16 results in an otherwise-extraneous
      ; pattern getting allocated for the string, so all we have to do
      ; to get our extra pixel (+pattern) is not do a decrement here.
      ; simple, right?
;      dea
      lsr
      lsr
      lsr
      lsr
      ina
      @writePatternSize:
      sta (newZpFreeReg),Y
      ; set patternTransfersLeft
/*      iny
      sta (newZpFreeReg),Y
      
      ; copy startPtr to currentPtr
      ldy #SubtitleCompBufferLineState.startPtr
      lda (newZpFreeReg),Y
      pha
        iny
        lda (newZpFreeReg),Y
        ldy #SubtitleCompBufferLineState.currentPtr+1
        sta (newZpFreeReg),Y
      pla
      dey
      sta (newZpFreeReg),Y */
      jsr resetSubtitleStateQueueFields
    pla
    
    ; round up to next plane start in composition buffer
    ; if at a 16-pixel boundary, no advance needed
;    and #$0F
    ; FUCKING wladx, how do you not catch this as an error
;    beq +:
;    beq +
    ; actually, the behavior i intended here doesn't work anyways.
    ; i'm not even sure any more, but the shadow generation may rely
    ; on an extra pattern getting initialized for the 16px-boundary case,
    ; so let's leaves this as it is
    and #$FF
    beq +
      jsr advanceActiveSubtitleCompBufferPtrToNextPattern
    +:
    
    ; advance active state to next
    lda newZpFreeReg+0
    clc
    adc #<_sizeof_SubtitleCompBufferLineState
    sta newZpFreeReg+0
    sta activeSubtitleStatePtr+0.w
;    lda newZpFreeReg+1
;    adc #>_sizeof_SubtitleCompBufferLineState
    cla
    adc newZpFreeReg+1
    sta newZpFreeReg+1
    sta activeSubtitleStatePtr+1.w
    
    ; set new state's start to plane start
;    ldy #SubtitleCompBufferLineState.startPtr
    cly
    lda activeSubtitleCompBufferPtr+0.w
    sta (newZpFreeReg),Y
    iny
    lda activeSubtitleCompBufferPtr+1.w
    sta (newZpFreeReg),Y
    
    ; increment count of group lines if width nonzero
    lda activeSubtitleXPos.w
    beq +
      ; technically a HACK: assumes 2 lines per group,
      ; which i can assure you is the most we're ever going to have
      lda activeLineCount.w
      lsr
      tax
      inc group1RealLineCount.w,X
    +:
    
    ; reset x-pos
    stz activeSubtitleXPos.w
    
    ; increment count of active lines
    inc activeLineCount.w
    
    rts
  
  turnSubsOff:
    stz subtitleDisplayOn.w
    
    ; blank out the subtitles sprites from the sat
    lda currentSubtitleSpriteAttributeQueueSize.w
    beq @done
      ; set size of the area to blank
;      asl
;      asl
;      asl
/*      sta @transferToSatCmd+5.w
      
      ; set write address
      st0 #$00
      st1 #<satVramAddr
      st2 #>satVramAddr
      
      ; start write
      st0 #$02
      
      @transferToSatCmd:
      tia zeroPlanes,$0002,$0000
      
      ; initiate sat->satb dma
;      st0 #$13
;      st1 #<satVramAddr
;      st2 #>satVramAddr */
    @done:
    rts
.ends




































;=============================
; memory
;=============================

.bank 0 slot 0
.section "memory 1" free
  ; everything in here is cleared to zero by a buffer reset
  bufferResetArea:
    subtitleCharCompBuffer:
      .ds subtitleCharCompBufferSize,$00
    
    activeSubtitleXPos:
      .db $00
    
    activeLineCount:
      .db $00
    
    ; these keep count of the number of "real" (width nonzero) lines
    ; in group1 (bottom) and group2 (top)
    group1RealLineCount:
      .db $00
    group2RealLineCount:
      .db $00
    
    subtitleStates:
      ; this needs to be +1 due to "overflow"
      ; in finishCurrentSubtitleBufferLine
      .ds (numSubtitleCompBufferLines+1)*_sizeof_SubtitleCompBufferLineState,$00
    
    subtitleCompBuffers:
      ; only the first composition buffer is cleared in the reset.
      ; the rest are cleared procedurally during the composition process
      .ds bytesPerSpritePatternPlane,$00
  endOfBufferResetArea:
    ; this SHOULD use one less pattern than the computed amount
    ; to account for the extra pattern in the reset area above...
    ; but since we don't have special handling for the case where
    ; the very last pattern is fully filled and the "next" pattern after
    ; it need to get initialized, we need an extra pattern for possible
    ; "overflow" anyway
;      .ds (numSubtitleCompBufferLines*bytesPerSubtitleCompLineBuffer-bytesPerSpritePatternPlane),$00
      .ds (numSubtitleCompBufferLines*bytesPerSubtitleCompLineBuffer),$00
  
  activeSubtitleCompBufferPtr:
    .dw subtitleCompBuffers
  activeSubtitleStatePtr:
    .dw subtitleStates
  
  currentSubtitlePaletteIndex:
    .db $FF
  
  subtitleAttributeTransferOn:
    .db $00
  subtitleAttributeTransferCurrentStatePtr:
    .dw $0000
;  subtitleAttributeTransferEndLineNum:
;    .db $00
  subtitleAttributeTransferVramPutPos:
    .dw $0000
  subtitleAttributeTransferLineNum:
    .db $00
  
  subtitleGraphicsTransferOn:
    .db $00
  subtitleGraphicsTransferCurrentStatePtr:
    .dw $0000
  subtitleGraphicsTransferVramPutPos:
    .dw $0000
  subtitleGraphicsTransferLineNum:
    .db $00
  
  
  subtitleDisplayOn:
    .db $00
  ; 0 = queue A is back (write), queue B is front (display)
  ; 1 = queue B is back, queue A is front
  subtitleDisplayQueueParity:
    .db $00
  subtitleDisplayQueuePointerArray:
    .dw subtitleSpriteAttributeQueueA
    .dw subtitleSpriteAttributeQueueB
  subtitleDisplayQueueSizeArray:
    .db $00
    .db $00
  subtitleDisplayBackQueuePutPos:
    .dw $0000
;  subtitleDisplayBackQueuePutPos:
;    .db $00
  subtitleDisplayQueueCurrentX:
    .db $00
  subtitleDisplayQueueCurrentY:
    .db $00
  
  subtitleSpriteAttributeQueueA:
    .ds _sizeof_SpriteAttribute*maxNumSubtitleSprites,$00
  subtitleSpriteAttributeQueueB:
    .ds _sizeof_SpriteAttribute*maxNumSubtitleSprites,$00
  
  currentSubtitleSpriteAttributeQueuePtr:
    .dw $0000
  currentSubtitleSpriteAttributeQueueSize:
    .db $00
  currentSubtitleActiveLineCount:
    .db $00
  
;  currentSubtitleGroup1RealLineCount:
;    .dw $0000
;  currentSubtitleGroup2RealLineCount:
;    .dw $0000
  
  subtitleScriptPtr:
;    .dw subtitleScriptData
;    .dw testSubtitleData
    .dw subtitleDataLoadAddr
  
  queuedSubsOffTime:
    .dw $0000
  queuedSubsOffIsOn:
    .db $00
  
;  subtitleSpriteClearNeeded:
;    .db $00
  
  ; reset to this at start of new subtitle
;  fontSpriteBaseVramTarget:
;    .dw $0000
  ; next converted font sprite goes here
;  fontSpriteNextVramTarget:
;    .dw $0000
  
;  subtitleBaseX:
;    .db 128
  
  ; bottom group
  subtitleBaseY:
    .db 208
  ; top group
  subtitleBaseYGroup2:
    .db 24
.ends

.include "asm/scene00.s"
