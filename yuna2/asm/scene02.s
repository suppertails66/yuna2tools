
.include "include/global.inc"
.include "include/scene_common.inc"
.include "include/scene_sub_common.inc"

.bank 0 slot 0
.orga $9000
.section "subtitle data 1" SIZE $1000 overwrite
  testSubtitleData:
    
    ;==========================================
    ; init
    ;==========================================
    
    cut_resetCompBuffers
    cut_setPalette $08
    
    ;==========================================
    ; TRACK 09 START
    ;==========================================
    
    SYNC_cdTime 1 0.000
    
    SCENE_setUpAutoPlace $01C8 $1C
    
    ;=====
    ; 
    ;=====
    
;    cut_waitForFrame $0100
    
    cut_setHighPrioritySprObjOffset 12
    
    cut_waitForFrameMinSec 0 0.500

    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene2-99.bin"
    cut_prepAndSendGrp $01FF
    cut_writeBackQueueToAltSat $7000
    cut_swapBuf

    ; "proceed to earth"
    .incbin "out/script/strings/scene/scene2-0.bin"
;    cut_prepAndSendGrp $01C8
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 1.734
    cut_swapAndShowBuf

    ; "understood"
    .incbin "out/script/strings/scene/scene2-1.bin"
    SCENE_prepAndSendGrpAuto
    
;      cut_waitForFrameMinSec 0 3.945
;      cut_subsOff
      ; switch off during blackout by showing "blank" sprite table
      cut_waitForFrameMinSec 0 3.945-0.150
      cut_showWithAltSat $7000
      cut_subsOff
    
    cut_waitForFrameMinSec 0 6.047
    cut_swapAndShowBuf

    ; "the evil which exists"
    .incbin "out/script/strings/scene/scene2-2.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 6.047+1.000
      cut_subsOff
    
    cut_waitForFrameMinSec 0 8.672
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 12.893
    cut_subsOff
    
    SCENE_setUpAutoPlace $01A8 $2C

    ; "gomen ne no hitokoto"
    .incbin "out/script/strings/scene/scene2-3.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 10 START
    ;==========================================
    
    SYNC_cdTime 2 0.000
    
    cut_setHighPrioritySprObjOffset 16
    
    cut_waitForFrameMinSec 0 3.862
    cut_swapAndShowBuf

    ; "surechigau kimochi"
    .incbin "out/script/strings/scene/scene2-4.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6900
    
    cut_waitForFrameMinSec 0 13.921
    cut_swapAndShowBuf

    ; "sunao ni narereba"
    .incbin "out/script/strings/scene/scene2-5.bin"
    SCENE_prepAndSendGrpAuto
      
      ; wait for blackout
      cut_waitForFrameMinSec 0 21.736-0.150
      cut_showWithAltSat $6900
    
    cut_waitForFrameMinSec 0 22.823
    cut_swapAndShowBuf

    ; "ii no sore wa"
    .incbin "out/script/strings/scene/scene2-6.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 27.957
    cut_swapAndShowBuf

    ; "dakara egao de"
    .incbin "out/script/strings/scene/scene2-7.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6900
    
    cut_waitForFrameMinSec 0 33.021
    cut_swapAndShowBuf

    ; "ima wa sore de"
    .incbin "out/script/strings/scene/scene2-8.bin"
    SCENE_prepAndSendGrpAuto
      
      ; wait for blackout
      cut_waitForFrameMinSec 0 34.455-0.100
      cut_showWithAltSat $6900
    
    cut_waitForFrameMinSec 0 38.085
    cut_swapAndShowBuf

    ; blank (humming?)
    .incbin "out/script/strings/scene/scene2-9.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 44.560
    cut_swapAndShowBuf

    ; "mada ashita aeru ne"
    .incbin "out/script/strings/scene/scene2-10.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $7F00
    
    ; flood sprites on line $18 to prevent overdraw as the scene elements
    ; scroll up and into the uncropped subtitle area
    cut_setSpriteFlood 0 8 $18
    
      cut_waitForFrameMinSec 0 47.612-0.050
      cut_swapAndShowBuf
        
        ; wait for blackout
        cut_waitForFrameMinSec 0 48.976-0.100
        cut_showWithAltSat $7F00

      ; "gomen ne no hitokoto"
      .incbin "out/script/strings/scene/scene2-11.bin"
      ; wait for blackout to end
      cut_waitForFrameMinSec 0 52.237
      SCENE_prepAndSendGrpAuto
      
      cut_waitForFrameMinSec 0 57.787
      cut_swapAndShowBuf

      ; "mada ashita aeru ne"
      .incbin "out/script/strings/scene/scene2-12.bin"
      SCENE_prepAndSendGrpAuto
      
      cut_waitForFrameMinSec 1 7.799
      cut_swapAndShowBuf
    
    ; sprite flood off
    cut_setSpriteFlood 0 0 $18
    
    ; sprites default-on during ripple scene
    ; (this completely hijacks our normal rcr handler so it won't even run,
    ; so we have to have sprites absolutely on)
;    cut_waitForFrameMinSec 1 12.000
;    cut_andOr $20F3 $FF $40
    
    cut_waitForFrameMinSec 1 15.037-1.000
    cut_subsOff
    
    SCENE_setUpAutoPlace $01C0 $20

    ; "almost to earth"
    .incbin "out/script/strings/scene/scene2-13.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 11 START
    ;==========================================
    
    SYNC_cdTime 3 0.000
    
    cut_waitForFrameMinSec 0 2.957
    cut_swapAndShowBuf

    ; "somehow, it feels"
    .incbin "out/script/strings/scene/scene2-14.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 5.888
    cut_swapAndShowBuf

    ; "what?"
    .incbin "out/script/strings/scene/scene2-15.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 8.567
      cut_subsOff
    
    cut_waitForFrameMinSec 0 10.235
    cut_swapAndShowBuf

    ; "there's something ahead"
    .incbin "out/script/strings/scene/scene2-16.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 10.235+1.000
      cut_subsOff
    
    cut_waitForFrameMinSec 0 14.000
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 15.820
    cut_subsOff
    
    cut_terminator
.ends
