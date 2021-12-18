
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
   
   slotsize        $3800
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
  
  banksize $3800
  banks $1
.endro

.emptyfill $FF

.background "starbowl_CA.bin"

.unbackground $690B+$80-$4000 $6FFF-$4000
.unbackground $74D4-$4000 $77FF-$4000

;===================================
; old routines
;===================================

.define my_CD_READ $7000

;===================================
; old memory locations
;===================================

;.define my_CD_READ $7000

;==============================================================================
; load new subtitle data
;==============================================================================

.define starBowlSubtitleDataSrcSectorLo $BA
.define starBowlSubtitleDataSrcSectorMid $2E
.define starBowlSubtitleDataSrcSectorHi $00
.define starBowlSubtitleDataSectorCount 16
.define starBowlSubtitleDataDstPage $7E
.define starBowlSubtitleByteSize $1000
.define starBowlSubtitlePatternSize starBowlSubtitleByteSize/bytesPerSpritePattern

.bank 0 slot 0
.orga $40FD
.section "load subtitle data 1" overwrite
  jsr loadSubtitleDataFromDisc
.ends

.bank 0 slot 0
.section "load subtitle data 2" free
  loadSubtitleDataFromDisc:
    lda #starBowlSubtitleDataSrcSectorLo
    sta _DL
    lda #starBowlSubtitleDataSrcSectorMid
    sta _CH
    lda #starBowlSubtitleDataSrcSectorHi
    sta _CL
    
    ; type = mpr6
    lda #$06
    sta _DH
    
    ; length
    lda #starBowlSubtitleDataSectorCount
    sta _AL
    
    ; dst bank num
    lda #starBowlSubtitleDataDstPage
    sta _BL
    
    jsr my_CD_READ
    
    ; make up work
    jmp $55E5
.ends

;==============================================================================
; new subtitle data to vram
;==============================================================================

.define subtitleBaseVramTile $180
.define subtitleBaseVramAddr (subtitleBaseVramTile*bytesPerSpritePattern)/2
.define subtitleBaseY 192-16
.define subtitleBaseX 0

.define subtitlePalNum 10
.define subtitlePalOffset subtitlePalNum*16

.bank 0 slot 0
.section "subtitle vram 1" free
  subtitlePtrTbl:
    .dw $C000
    .dw $D000
    .dw $C000
    .dw $D000
    
  subtitleBankTbl:
    .db starBowlSubtitleDataDstPage+0
    .db starBowlSubtitleDataDstPage+0
    .db starBowlSubtitleDataDstPage+1
    .db starBowlSubtitleDataDstPage+1
  
  subtitleDstTbl:
    .dw subtitleBaseVramAddr
    .dw subtitleBaseVramAddr+(starBowlSubtitleByteSize/2)
    .dw subtitleBaseVramAddr
    .dw subtitleBaseVramAddr+(starBowlSubtitleByteSize/2)
  
  subtitlePalette:
    .incbin "out/rsrc_raw/pal/subtitles.pal"
  
  ; X = index
  loadSubtitleToVram:
    tma #$40
    pha
      lda subtitleBankTbl.w,X
      tam #$40
      
      ; i could be making separate upper/lower byte index tables and skipping this,
      ; but who cares
      sax
      asl
      sax
      lda subtitlePtrTbl+0.w,X
      sta @vramTransferOp+1.w
      lda subtitlePtrTbl+1.w,X
      sta @vramTransferOp+2.w
      
;      lda #<subtitleBaseVramAddr
;      ldx #>subtitleBaseVramAddr
      lda subtitleDstTbl+0.w,X
      pha
        lda subtitleDstTbl+1.w,X
      plx
      sax
      jsr EX_SETWRT
      
      @vramTransferOp:
      tia $0000,$0002,starBowlSubtitleByteSize
    pla
    tam #$40
    
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
    
    rts
  
  loadSub0:
    pha
    phx
      ldx #$00
      jsr loadSubtitleToVram
    plx
    pla
    jmp $4D1E
  
  loadSub1:
    pha
    phx
      ldx #$01
      jsr loadSubtitleToVram
    plx
    pla
    jmp $4D1E
  
  loadSub2:
    pha
    phx
      ldx #$02
      jsr loadSubtitleToVram
    plx
    pla
    jmp $4D1E
  
  loadSub3:
    pha
    phx
      ldx #$03
      jsr loadSubtitleToVram
    plx
    pla
    jmp $4D1E
.ends

.bank 0 slot 0
.orga $419B
.section "subtitle vram 2" overwrite
  jsr loadSub0
.ends

.bank 0 slot 0
.orga $41B3
.section "subtitle vram 3" overwrite
  jsr loadSub1
.ends

.bank 0 slot 0
.orga $41CB
.section "subtitle vram 4" overwrite
  jsr loadSub2
.ends

.bank 0 slot 0
.orga $41E3
.section "subtitle vram 5" overwrite
  jsr loadSub3
.ends

;==============================================================================
; write subtitle layout to sat as needed
;==============================================================================

.define satBaseOffset $0F00
.define subtitleSatOffset satBaseOffset+$80/2
; 16 sprites, 8 bytes per entry
.define subtitleTotalSatSize 16*8

.bank 0 slot 0
.section "subtitle sat 1" free
  subtitleSatData:
    .rept 2 INDEX outerCount
      .rept 8 INDEX innerCount
        ; y
        .dw subtitleBaseY+(spritePatternH*outerCount)+spriteAttrBaseY
        ; x
        .dw subtitleBaseX+(spritePatternW*2*innerCount)+spriteAttrBaseX
        ; pattern index
        .dw (subtitleBaseVramTile+(outerCount*16)+(innerCount*2))<<1
        ; flags (single-height, double-width, high-priority) + palette
        .dw $0180|subtitlePalNum
      .endr
    .endr
  subtitleSatDataEnd:
  
  subtitleSatDataAltBuffer:
    .rept 2 INDEX outerCount
      .rept 8 INDEX innerCount
        ; y
        .dw subtitleBaseY+(spritePatternH*outerCount)+spriteAttrBaseY
        ; x
        .dw subtitleBaseX+(spritePatternW*2*innerCount)+spriteAttrBaseX
        ; pattern index
        .dw (subtitleBaseVramTile+(outerCount*16)+(innerCount*2)+starBowlSubtitlePatternSize)<<1
        ; flags (single-height, double-width, high-priority) + palette
        .dw $0180|subtitlePalNum
      .endr
    .endr
  
;  blankSubtitleData:
;    .ds subtitleTotalSatSize,$00
  
  subtitleBufferSrcTable:
    .dw subtitleSatData
    .dw subtitleSatDataAltBuffer
  
  ; A = subtitle buffer parity (0 or 1)
  writeSubtitleToSat:
    asl
    tax
    lda subtitleBufferSrcTable+0.w,X
    sta @vramTransferOp+1.w
    lda subtitleBufferSrcTable+1.w,X
    sta @vramTransferOp+2.w
    
    ; set write addr
    lda #<subtitleSatOffset
    ldx #>subtitleSatOffset
    jsr EX_SETWRT
    
    ; transfer to vram
;    tia subtitleSatData,$0002,(subtitleSatDataEnd-subtitleSatData)
;    tia subtitleSatData,$0002,subtitleTotalSatSize
    @vramTransferOp:
    tia $0000,$0002,subtitleTotalSatSize
    rts
  
/*  clearSubtitlesFromSat:
    ; set write addr
    lda #<subtitleSatOffset
    ldx #>subtitleSatOffset
    jsr EX_SETWRT
    
    tia blankSubtitleData,$0002,subtitleTotalSatSize
    
    ; force vsync wait so sat refreshes (otherwise, new data will immediately load in
    ; while with old sprites still displaying it for a frame)
    jmp EX_VSYNC */
  
  showSubtitle:
    ; make up work (show portrait)
;    jsr $4AA1
;    jmp writeSubtitleToSat
    
    ; swap buffer parity
    lda subtitleDisplayParity.w
    eor #$01
    sta subtitleDisplayParity.w
    jsr writeSubtitleToSat
    
    ; make up work (wait for adpcm)
    jsr $4DEE
    
    ; clear subtitles from SAT in preparation for loading next set
;    jmp clearSubtitlesFromSat
    rts
  
  subtitleDisplayParity:
    .db $01
    
.ends

.bank 0 slot 0
.orga $41A9+3
.section "subtitle sat 2" overwrite
  jsr showSubtitle
.ends

.bank 0 slot 0
.orga $41C1+3
.section "subtitle sat 3" overwrite
  jsr showSubtitle
.ends

.bank 0 slot 0
.orga $41D9+3
.section "subtitle sat 4" overwrite
  jsr showSubtitle
.ends

.bank 0 slot 0
.orga $41F1+3
.section "subtitle sat 5" overwrite
  jsr showSubtitle
.ends



;==============================================================================
; text printing
;==============================================================================

;===================================
; additional resources
;===================================

/*.bank 0 slot 0
.section "printing: font data" free
  fontData:
    .incbin "out/font/font.bin"
.ends

;===================================
; printCurrentString
;===================================

.bank 0 slot 0
.orga $6C37
.section "printCurrentString 1" SIZE $9E overwrite
  
.ends */
