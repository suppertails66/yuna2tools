
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
    ; TRACK 12 START
    ;==========================================
    
    SYNC_cdTime 1 0.000
    
    SCENE_setUpAutoPlace $01C0 $20
    
    ;=====
    ; 
    ;=====
    
;    cut_waitForFrame $0100
    
    cut_setHighPrioritySprObjOffset 12
    
    cut_waitForFrameMinSec 0 1.000

    ; "not yet"
    .incbin "out/script/strings/scene/scene3-0.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 2.541
    cut_swapAndShowBuf

    ; "you haven't beaten me"
    .incbin "out/script/strings/scene/scene3-1.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 3.401+0.400
      cut_subsOff
    
    cut_waitForFrameMinSec 0 8.656
    cut_swapAndShowBuf

    ; "erika"
    .incbin "out/script/strings/scene/scene3-2.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6F00
    
    cut_waitForFrameMinSec 0 11.140
    cut_swapAndShowBuf
    cut_showWithAltSat $6F00

    ; "wait! erika"
    .incbin "out/script/strings/scene/scene3-3.bin"
    ; wait for blackout to end
    cut_waitForFrameMinSec 0 12.400
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 12.249
      cut_subsOff
    
    cut_waitForFrameMinSec 0 14.140
    cut_swapAndShowBuf

    ; "this is... the princess"
    .incbin "out/script/strings/scene/scene3-4.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 15.669+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 32.083
    cut_swapAndShowBuf

    ; "but all i can do"
    .incbin "out/script/strings/scene/scene3-5.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 34.395+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 40.319
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 44.026+0.200
    cut_subsOff
    
    SCENE_setUpAutoPlace $01C0 $20

    ; "huh?"
    .incbin "out/script/strings/scene/scene3-6.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 13 START
    ;==========================================
    
    SYNC_cdTime 2 0.000
    
    ;=====
    ; 
    ;=====
    
    cut_waitForFrameMinSec 0 21.712
    cut_swapAndShowBuf

    ; "yuna... yuna"
    .incbin "out/script/strings/scene/scene3-7.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 22.796
    cut_swapAndShowBuf

    ; "elner"
    .incbin "out/script/strings/scene/scene3-8.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 24.984
    cut_swapAndShowBuf

    ; "elner, what are you doing"
    .incbin "out/script/strings/scene/scene3-9.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 26.351
    cut_swapAndShowBuf

    ; "it's not just me"
    .incbin "out/script/strings/scene/scene3-10.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 28.472
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 31.137-0.300
    cut_subsOff
    
;    SCENE_setUpAutoPlace $01C6 $1D
    ; we need one extra pattern available in the second buffer
    ; for elner's "if i'm helping you..." line
    SCENE_setUpAutoPlace $01C6 $1C

    ; "yuna" (1)
    .incbin "out/script/strings/scene/scene3-12.bin"
    cut_waitForFrameMinSec 0 34.500
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 36.383
    cut_swapAndShowBuf

    ; "yuna" (2)
    .incbin "out/script/strings/scene/scene3-12.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 37.735
    cut_swapAndShowBuf

    ; "yuna" (3)
    .incbin "out/script/strings/scene/scene3-12.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 38.919
    cut_swapAndShowBuf

    ; "guys..."
    .incbin "out/script/strings/scene/scene3-13.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 39.617
      cut_subsOff
    
    cut_waitForFrameMinSec 0 42.832
    cut_swapAndShowBuf

    ; "and me too"
    .incbin "out/script/strings/scene/scene3-14.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 44.160
    cut_swapAndShowBuf

    ; "lia"
    .incbin "out/script/strings/scene/scene3-15.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 45.459
    cut_swapAndShowBuf

    ; "come on, yuna"
    .incbin "out/script/strings/scene/scene3-16.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 46.639
      cut_subsOff
    
    cut_waitForFrameMinSec 0 50.934
    cut_swapAndShowBuf

    ; "but elner can't"
    .incbin "out/script/strings/scene/scene3-17.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 52.892
      cut_subsOff
    
    cut_waitForFrameMinSec 0 53.728
    cut_swapAndShowBuf

    ; "yuna, while i can"
    .incbin "out/script/strings/scene/scene3-18.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 55.171
    cut_swapAndShowBuf

    ; "if i'm helping you"
    .incbin "out/script/strings/scene/scene3-19.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 59.853
    cut_swapAndShowBuf

    ; "elner"
    .incbin "out/script/strings/scene/scene3-20.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 5.738
    cut_swapAndShowBuf

    ; "now, yuna"
    .incbin "out/script/strings/scene/scene3-21.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 6.670
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 1 8.442+0.300
    cut_subsOff
    
    SCENE_setUpAutoPlace $01C0 $20

    ; "??? el-line"
    .incbin "out/script/strings/scene/scene3-22.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 14 START
    ;==========================================
    
    SYNC_cdTime 3 0.000
    
    ;=====
    ; 
    ;=====
    
    cut_waitForFrameMinSec 0 1.153
    cut_swapAndShowBuf

    ; "???"
    .incbin "out/script/strings/scene/scene3-23.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 3.494+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 13.862
    cut_swapAndShowBuf

    ; "lightning shot"
    .incbin "out/script/strings/scene/scene3-24.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 15.328+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 19.619
    cut_swapAndShowBuf

    ; "alright"
    .incbin "out/script/strings/scene/scene3-25.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 21.967
      cut_subsOff
    
    cut_waitForFrameMinSec 0 40.525
    cut_swapAndShowBuf

    ; "n-no way"
    .incbin "out/script/strings/scene/scene3-26.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 41.486+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 47.890
    cut_swapAndShowBuf

    ; "lightning shot didn't"
    .incbin "out/script/strings/scene/scene3-27.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 49.804
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 52.537
    cut_subsOff
    
    
    cut_terminator
.ends
