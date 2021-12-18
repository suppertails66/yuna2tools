
.include "include/global.inc"
.include "include/scene_common.inc"
.include "include/scene_sub_common.inc"

.bank 0 slot 0
.orga $9000
.section "subtitle data 1" SIZE $1000 overwrite
  testSubtitleData:
    
    ;=====
    ; init
    ;=====
    
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
    
    cut_setHighPrioritySprObjOffset 16
    
    cut_waitForFrameMinSec 0 1.000

    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene5-99.bin"
    ; you know, i could just write this to the last "tile"
    ; of the sprite table, since both it and the end of the generated table
    ; will be null in that area... but it's probably not going to matter anyway.
    ; hell, if we know the target area will be blank anyway, we could skip
    ; this whole dummy write, all we really need is 0x200 bytes of null VRAM
    cut_prepAndSendGrp $01B8
    cut_writeBackQueueToAltSat $6F00
    cut_swapBuf

    ; "looks like we made it"
    .incbin "out/script/strings/scene/scene5-0.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 7.612
    cut_swapAndShowBuf

    ; "so we did"
    .incbin "out/script/strings/scene/scene5-1.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 9.396
    cut_swapAndShowBuf

    ; "so, erika closed down"
    .incbin "out/script/strings/scene/scene5-5.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 10.288
      cut_subsOff
    
    cut_waitForFrameMinSec 0 13.764
    cut_swapAndShowBuf

    ; "transferred to our"
    .incbin "out/script/strings/scene/scene5-6.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 18.259
    cut_swapAndShowBuf

    ; "that part's fine, but"
    .incbin "out/script/strings/scene/scene5-7.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 23.762
    cut_swapAndShowBuf

    ; "hi, yuna"
    .incbin "out/script/strings/scene/scene5-8.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 25.338+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 30.053
    cut_swapAndShowBuf

    ; "oh, erika"
    .incbin "out/script/strings/scene/scene5-9.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 31.432
      cut_subsOff
    
    cut_waitForFrameMinSec 0 34.212
    cut_swapAndShowBuf

    ; "were you waiting"
    .incbin "out/script/strings/scene/scene5-10.bin"
    
      cut_waitForFrameMinSec 0 36.333
      cut_showWithAltSat $6F00
      cut_subsOff
    
    ;==========================================
    ; TRACK 13 START
    ;==========================================
    
    SYNC_cdTime 2 0.000
    
    ; erika walks up
    SCENE_setUpAutoPlace $01C8 $1C
    SCENE_prepAndSendGrpAuto
    cut_waitForFrameMinSec 0 0.245
    cut_swapAndShowBuf

    ; "oh, yuri, are you still"
    .incbin "out/script/strings/scene/scene5-11.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 2.521
    cut_swapAndShowBuf

    ; "that is right"
    .incbin "out/script/strings/scene/scene5-12.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 5.706
    cut_swapAndShowBuf

    ; "come on, just"
    .incbin "out/script/strings/scene/scene5-13.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 7.118
    cut_swapAndShowBuf

    ; "no"
    .incbin "out/script/strings/scene/scene5-14.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 9.524
    cut_swapAndShowBuf

    ; "i am together with"
    .incbin "out/script/strings/scene/scene5-15.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 10.388
    cut_swapAndShowBuf

    ; "i will not be"
    .incbin "out/script/strings/scene/scene5-16.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 12.045
    cut_swapAndShowBuf

    ; "no! she's my"
    .incbin "out/script/strings/scene/scene5-17.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 14.134
    cut_swapAndShowBuf

    ; "wrong! miss yuna is"
    .incbin "out/script/strings/scene/scene5-18.bin"
    
      cut_waitForFrameMinSec 0 16.584+0.200
      cut_subsOff
    
    ; argument closeup + mai
    SCENE_setUpAutoPlace $00CE $19
    cut_waitForFrameMinSec 0 22.880-0.100
    SCENE_prepAndSendGrpAuto
    cut_waitForFrameMinSec 0 22.880
    cut_swapAndShowBuf

    ; "my yuna"
    .incbin "out/script/strings/scene/scene5-19.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 25.949
    cut_swapAndShowBuf

    ; "yuri's miss yuna"
    .incbin "out/script/strings/scene/scene5-20.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 27.505
    cut_swapAndShowBuf

    ; "my yuna"
    .incbin "out/script/strings/scene/scene5-21.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 28.975
    cut_swapAndShowBuf

    ; "how has my life"
    .incbin "out/script/strings/scene/scene5-22.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 30.704
      cut_subsOff
    
    cut_waitForFrameMinSec 0 31.683
    cut_swapAndShowBuf

    ; "c'mon! i want you to"
    .incbin "out/script/strings/scene/scene5-23.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 33.672
    cut_swapAndShowBuf

    ; "how come i don't"
    .incbin "out/script/strings/scene/scene5-24.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 36.769
    cut_swapAndShowBuf
    
      cut_waitForFrameMinSec 0 39.262+0.200
      cut_subsOff

      ; dummy line for sub clear during blackout
      .incbin "out/script/strings/scene/scene5-99.bin"
      cut_waitForFrameMinSec 0 40.300
      cut_prepAndSendGrp $01B8
      cut_writeBackQueueToAltSat $6F00
      cut_swapBuf

    ; "my yuna"
    .incbin "out/script/strings/scene/scene5-25.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 41.092
    cut_swapAndShowBuf

    ; "yuri's miss yuna"
    .incbin "out/script/strings/scene/scene5-26.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 42.489
    cut_swapAndShowBuf

    ; "geez, both of you"
    .incbin "out/script/strings/scene/scene5-27.bin"
    
      cut_waitForFrameMinSec 0 44.895+0.025
      cut_subsOff
  
    SCENE_setUpAutoPlace $01C0 $20
    cut_waitForFrameMinSec 0 46.351
    SCENE_prepAndSendGrpAuto
    cut_waitForFrameMinSec 0 47.287
    cut_swapAndShowBuf

    ; "what now"
    .incbin "out/script/strings/scene/scene5-28.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 49.881
      cut_subsOff
    
    ;==========================================
    ; TRACK 14 START
    ;==========================================
    
    SYNC_cdTime 3 0.000
    
    cut_waitForFrameMinSec 0 11.224
    cut_swapAndShowBuf

    ; "hi, yuna"
    .incbin "out/script/strings/scene/scene5-29.bin"
    SCENE_prepAndSendGrpAuto
    
;      cut_waitForFrameMinSec 0 12.910
;      cut_subsOff
    
    cut_waitForFrameMinSec 0 12.910
    cut_swapAndShowBuf

    ; "mirage"
    .incbin "out/script/strings/scene/scene5-30.bin"
    SCENE_prepAndSendGrpAuto
    
;    cut_waitForFrameMinSec 0 15.329
;    cut_swapAndShowBuf
    cut_waitForFrameMinSec 0 14.695
    cut_swapAndShowBuf

    ; "yuna, i want to be with"
    .incbin "out/script/strings/scene/scene5-31.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 16.321
      cut_subsOff
    
    cut_waitForFrameMinSec 0 17.907
    cut_swapAndShowBuf

    ; "so i've decided to"
    .incbin "out/script/strings/scene/scene5-32.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 21.764
    cut_swapAndShowBuf

    ; "huh"
    .incbin "out/script/strings/scene/scene5-33.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 25.850
    cut_swapAndShowBuf

    ; "thus, if you"
    .incbin "out/script/strings/scene/scene5-34.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 26.692+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 30.064
    cut_swapAndShowBuf

    ; "i will end you"
    .incbin "out/script/strings/scene/scene5-35.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 35.269
    cut_swapAndShowBuf

    ; "what!? she's my"
    .incbin "out/script/strings/scene/scene5-36.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 37.817-0.100
      cut_showWithAltSat $6F00
      cut_subsOff
    
    cut_waitForFrameMinSec 0 39.989
    cut_swapAndShowBuf

    ; "miss yuna is"
    .incbin "out/script/strings/scene/scene5-37.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 42.061
      cut_subsOff
    
    cut_waitForFrameMinSec 0 42.745
    cut_swapAndShowBuf

    ; "isn't is nice, yuna"
    .incbin "out/script/strings/scene/scene5-38.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 44.550+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 55.517
    cut_swapAndShowBuf

    ; ""
;    .incbin "out/script/strings/scene/scene5-38.bin"
;    SCENE_prepAndSendGrpAuto
    
;    cut_waitForFrameMinSec 0 57.400
;    cut_swapAndShowBuf

    ; "i want to be able to"
    .incbin "out/script/strings/scene/scene5-39.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 59.066
      cut_subsOff
    
    cut_waitForFrameMinSec 1 0.088
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 1 2.785+0.300
    cut_subsOff
    
    
    cut_terminator
.ends
