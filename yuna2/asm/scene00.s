
;==============================================================================
; note that unlike all other scenes, this file is included directly into
; scene_main (it's loaded by default with the scene player)
;==============================================================================

.define patchTransferIncrement $100

; elner pop-in patch
.define patch1SrcSlot $7F
.define patch1Size $1000
.define patch1NumTransfers patch1Size/patchTransferIncrement
.define patch1Src $C000
.define patch1Dst $7480

.bank 0 slot 0
.orga $9000
.section "op subtitle data 1" SIZE $1000 overwrite
  testSubtitleData:
    
    ;=====
    ; init
    ;=====
    
    cut_resetCompBuffers
    cut_setPalette $08
    
    ;=====
    ; 
    ;=====
    
;    cut_waitForFrame $0100
    
    SYNC_cdTime 1 0.000
    
    cut_waitForFrameMinSec 0 3.000
    
;    .db $6E,$79,$87,$88,$50,$52,$07
;    .db $6E,$79,$87,$88,$50,$53,$07
;    .db $6E,$79,$87,$88,$50,$54,$07
;    .db $6E,$79,$87,$88,$50,$55,$07

    ; "kyou mo FUNNY FUNNY BEAT"
    .incbin "out/script/strings/scene/scene0-0.bin"
    cut_prepAndSendGrp $01D2
    
    cut_waitForFrameMinSec 0 3.969
    cut_swapAndShowBuf
    
    ; "watashi BOOGIE-WOOGIE DANCE"
    .incbin "out/script/strings/scene/scene0-1.bin"
;    cut_prepAndSendGrp $01C0
    ; wait until lia's bg graphics disappear, then overwrite them
    cut_waitForFrameMinSec 0 6.237
    cut_prepAndSendGrp $00BA
    
    cut_waitForFrameMinSec 0 7.574
;    cut_subsOff
    cut_swapAndShowBuf

    ; "dakara VERY VERY GOOD"
    .incbin "out/script/strings/scene/scene0-2.bin"
    cut_prepAndSendGrp $01D2
    cut_waitForFrameMinSec 0 11.187
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; "haato ni yume ga"
    .incbin "out/script/strings/scene/scene0-3.bin"
    cut_prepAndSendGrp $00BA
    cut_waitForFrameMinSec 0 15.021
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; restore overwritten sprites for elner pop-in
    .rept patch1NumTransfers INDEX count
      cut_writeVramFromSlot patch1SrcSlot patch1Src+(patchTransferIncrement*count) patchTransferIncrement patch1Dst+((patchTransferIncrement/2)*count)
    .endr
    
    cut_waitForFrameMinSec 0 21.568
    cut_subsOff
    
    ; "legend of the galaxy fraulein"
    .incbin "out/script/strings/scene/scene0-4.bin"
;    cut_waitForFrame $590
    cut_waitForFrame $570
    cut_prepAndSendGrp $01E4
    
;    cut_waitForFrame $660
    cut_waitForFrame $590
    cut_swapAndShowBuf
    
    cut_waitForFrame $6C0+$20
    cut_subsOff
    
    ; "tanoshikute jikan o"
    .incbin "out/script/strings/scene/scene0-5.bin"
    cut_waitForFrame $840
    cut_prepAndSendGrp $01C8-1
    
    cut_waitForFrameMinSec 0 37.123
    cut_swapAndShowBuf
    
    ; "mainichi ga kasokudo"
    .incbin "out/script/strings/scene/scene0-6.bin"
    cut_prepAndSendGrp $01E4-1
;    cut_prepAndSendGrp $0048+$14
    cut_waitForFrameMinSec 0 44.315
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; okay, here's where things start getting tricky again...
    ; the next line starts during a loading transition,
    ; so we need to prep 
    
    ; "tokidoki wa kizutsuiute"
    .incbin "out/script/strings/scene/scene0-7.bin"
    cut_prepAndSendGrp $01C8-1
    cut_writeBackQueueToAltSat $6D00
    cut_waitForFrameMinSec 0 51.105
;    cut_waitForFrameMinSec 0 51.105-0.170
;    cut_subsOff
    cut_swapAndShowBuf
    cut_showWithAltSat $6D00
    
    ; "sugu ni torimodosu"
    .incbin "out/script/strings/scene/scene0-8.bin"
    ; wait until loading finishes to send graphics
    cut_waitForFrameMinSec 0 52.910
    cut_prepAndSendGrp $01E4
    cut_waitForFrameMinSec 0 59.226
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; "jitto shitenai no"
    .incbin "out/script/strings/scene/scene0-9.bin"
    cut_prepAndSendGrp $01C8
    cut_writeBackQueueToAltSat $6D00
    
;      cut_waitForFrameMinSec 1 4.643
;      cut_subsOff

    cut_waitForFrameMinSec 1 5.326
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; "mune ni RING A RING A BELL"
    .incbin "out/script/strings/scene/scene0-10.bin"
    cut_prepAndSendGrp $01E4
    cut_writeBackQueueToAltSat $6E00
    
      ; wait until load transition starts occurring, hurredly switch
      ; to alt sat before the main one gets overwritten
      cut_waitForFrameMinSec 1 7.577
      cut_showWithAltSat $6D00
    
    cut_waitForFrameMinSec 1 8.930
;    cut_subsOff
    cut_swapAndShowBuf
    cut_showWithAltSat $6E00
    
    ; "jitto dekinai no"
    .incbin "out/script/strings/scene/scene0-11.bin"
    cut_prepAndSendGrp $01C8
    cut_waitForFrameMinSec 1 12.541
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; "yokan wa dare yori"
    .incbin "out/script/strings/scene/scene0-12.bin"
    cut_prepAndSendGrp $01E4
    cut_writeBackQueueToAltSat $6D00
    cut_waitForFrameMinSec 1 16.368
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; "mo wakaru no"
    .incbin "out/script/strings/scene/scene0-13.bin"
    
      ; wait until load transition starts occurring, hurredly switch
      ; to alt sat before the main one gets overwritten
      cut_waitForFrameMinSec 1 16.600
      cut_showWithAltSat $6D00
    
    ; wait until load finishes to transfer graphics
    cut_waitForFrameMinSec 1 19.000
    cut_prepAndSendGrp $01C8
    cut_waitForFrameMinSec 1 19.749
;    cut_subsOff
    cut_swapAndShowBuf
    
    ; sprite flood to make it less obvious that the subtitles
    ; are actually cutting off the bottom part of the large
    ; sprite overlay for the robots
    cut_setSpriteFlood 0 8 200
    
      ; "hora ne FUNNY FUNNY BEAT"
      .incbin "out/script/strings/scene/scene0-14.bin"
      cut_prepAndSendGrp $01E4
      cut_waitForFrameMinSec 1 23.402
  ;    cut_subsOff
      cut_swapAndShowBuf
      
      ; "watashi BOOGIE-WOOGIE DANCE"
      .incbin "out/script/strings/scene/scene0-15.bin"
      cut_prepAndSendGrp $01C8
      cut_writeBackQueueToAltSat $6D00
      cut_waitForFrameMinSec 1 26.971
  ;    cut_subsOff
      cut_swapAndShowBuf
      cut_showWithAltSat $6D00
    
    cut_setSpriteFlood 0 0 200
    
    ; "dakara VERY VERY GOOD"
    .incbin "out/script/strings/scene/scene0-16.bin"
    cut_prepAndSendGrp $01E4
    cut_waitForFrameMinSec 1 30.610
    cut_swapAndShowBuf
    
    cut_setHighPrioritySprObjOffset 16
    
    ; "haato ni yume ga"
    .incbin "out/script/strings/scene/scene0-17.bin"
    cut_prepAndSendGrp $01C8
;    cut_writeBackQueueToAltSat $6D00
    cut_waitForFrameMinSec 1 34.416-0.100
    cut_swapAndShowBuf
;    cut_showWithAltSat $6D00
    
    cut_waitForFrameMinSec 1 41.206
    cut_subsOff
    
    cut_setHighPrioritySprObjOffset 0
    
;    cut_waitForFrameMinSec 0 7.000
    
/*    .db $6E,$79,$87,$88,$50,$56,$07
    .db $6E,$79,$87,$88,$50,$57,$07
    .db $6E,$79,$87,$88,$50,$58,$07
    .db $6E,$79,$87,$88,$50,$59,$07
    cut_prepAndSendGrp $01D8
    cut_writeBackQueueToAltSat $7500
    
;    cut_waitForFrame $6D0
;    cut_swapAndShowBuf
    
    cut_waitForFrame $530
    cut_swapAndShowBuf
    cut_showWithAltSat $7500
    
;    cut_waitForFrameMinSec 0 6.000
;    cut_subsOff */
    
    
    cut_terminator
.ends
