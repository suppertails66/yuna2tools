
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
    
    ;=====
    ; 
    ;=====
    
;    cut_waitForFrame $0100
    
    ;==========================================
    ; TRACK 20 START
    ;==========================================
    
    SYNC_cdTime 1 0.000
    
    SCENE_setUpAutoPlace $01A0 $30
    
    ; for some reason, having this set to 16 from the start
    ; leads to a 1-frame scroll glitch (blocked rcr hit?)
    ; during the line "chiisana negai ga aru".
    ; having it set to 10 appears to fix this.
    ; of course, it's not at all unlikely that the emulator
    ; isn't emulating the timing correctly and this actually
    ; occurs all the time on real hardware, not just in this
    ; one instance.
    ; but i have no way of knowing.
    ; also, seriously, what the hell is causing this?
    ; i broke up all the block transfers that were causing issues before...
;    cut_setHighPrioritySprObjOffset 16
    cut_setHighPrioritySprObjOffset 10

    ; "itsudemo kokoro no"
    .incbin "out/script/strings/scene/scene4-0.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 13.830
    cut_swapAndShowBuf

    ; "chiisana negai ga aru"
    .incbin "out/script/strings/scene/scene4-1.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 21.095
    cut_swapAndShowBuf

    ; "sunao janakute"
    .incbin "out/script/strings/scene/scene4-2.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 28.286
    cut_swapAndShowBuf

    ; "kenka shite soredemo"
    .incbin "out/script/strings/scene/scene4-3.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 32.902
    cut_swapAndShowBuf

    ; "anata no koto ga"
    .incbin "out/script/strings/scene/scene4-4.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 36.084
    cut_setHighPrioritySprObjOffset 16
    
    cut_waitForFrameMinSec 0 39.229
    cut_swapAndShowBuf

    ; "itsuka toki ga tachi"
    .incbin "out/script/strings/scene/scene4-5.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 46.788
    cut_swapAndShowBuf

    ; "kyou no koto gomen"
    .incbin "out/script/strings/scene/scene4-6.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 50.632
    cut_swapAndShowBuf

    ; "tomodachi da kara ne"
    .incbin "out/script/strings/scene/scene4-7.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 2.016
    cut_swapAndShowBuf

    ; "shikata ga nai wa ne"
    .incbin "out/script/strings/scene/scene4-8.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 5.639
    cut_swapAndShowBuf

    ; "sonna no ari"
    .incbin "out/script/strings/scene/scene4-9.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6700
    
    cut_waitForFrameMinSec 1 9.281
    cut_swapAndShowBuf
    cut_showWithAltSat $6700

    ; "touzen ari"
    .incbin "out/script/strings/scene/scene4-10.bin"
    ; wait until blackout ends
    cut_waitForFrameMinSec 1 10.862-0.500
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 10.862
    cut_swapAndShowBuf

    ; "kurikaeshi desu"
    .incbin "out/script/strings/scene/scene4-11.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 12.697
    cut_swapAndShowBuf

    ; "tomodachi da kara ne"
    .incbin "out/script/strings/scene/scene4-12.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 16.550
    cut_swapAndShowBuf

    ; "tomodachi da mon ne"
    .incbin "out/script/strings/scene/scene4-13.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 20.187
    cut_swapAndShowBuf

    ; "nakayoshi desu"
    .incbin "out/script/strings/scene/scene4-14.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 23.824
    cut_swapAndShowBuf

    ; "sou yo ne yappari"
    .incbin "out/script/strings/scene/scene4-15.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 27.226
    cut_swapAndShowBuf

    ; "tabi wa go! go!"
    .incbin "out/script/strings/scene/scene4-16.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 30.417
    cut_swapAndShowBuf

    ; "tsuzuku go! go!"
    .incbin "out/script/strings/scene/scene4-17.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 34.049
    cut_swapAndShowBuf

    ; "dakedo ne minna"
    .incbin "out/script/strings/scene/scene4-18.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 37.746
      cut_subsOff
    
    cut_waitForFrameMinSec 2 6.552
    cut_swapAndShowBuf

    ; "hitori ni natta"
    .incbin "out/script/strings/scene/scene4-19.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 13.816
    cut_swapAndShowBuf

    ; "fushigi na kurai"
    .incbin "out/script/strings/scene/scene4-20.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 21.063
    cut_swapAndShowBuf

    ; "samishikute"
    .incbin "out/script/strings/scene/scene4-21.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 25.555
    cut_swapAndShowBuf

    ; "anato no koto o"
    .incbin "out/script/strings/scene/scene4-22.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 31.969
    cut_swapAndShowBuf

    ; "itsuka toki ga tachi"
    .incbin "out/script/strings/scene/scene4-23.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 39.505
    cut_swapAndShowBuf

    ; "kyou no koto"
    .incbin "out/script/strings/scene/scene4-24.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 43.358
    cut_swapAndShowBuf

    ; "otona ni naritai"
    .incbin "out/script/strings/scene/scene4-25.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 54.719
    cut_swapAndShowBuf

    ; "otona ni narenai"
    .incbin "out/script/strings/scene/scene4-26.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 2 58.360
    cut_swapAndShowBuf

    ; "watashi wa muri"
    .incbin "out/script/strings/scene/scene4-27.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 1.984
    cut_swapAndShowBuf

    ; "toubun muri"
    .incbin "out/script/strings/scene/scene4-28.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 3.565
    cut_swapAndShowBuf

    ; "kodomo mitai desuu"
    .incbin "out/script/strings/scene/scene4-29.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 5.404
    cut_swapAndShowBuf

    ; "kodomo de ii mon"
    .incbin "out/script/strings/scene/scene4-30.bin"
    ; wait until blackout ends
    cut_waitForFrameMinSec 3 9.267-1.000
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 9.267
    cut_swapAndShowBuf

    ; "tachinaorenai wa"
    .incbin "out/script/strings/scene/scene4-31.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 12.899
    cut_swapAndShowBuf

    ; "joudan desu"
    .incbin "out/script/strings/scene/scene4-32.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 16.513
    cut_swapAndShowBuf

    ; "sou yo ne yappari"
    .incbin "out/script/strings/scene/scene4-33.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 19.943
    cut_swapAndShowBuf

    ; "minna go! go!"
    .incbin "out/script/strings/scene/scene4-34.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 23.115
    cut_swapAndShowBuf

    ; "susume go! go!"
    .incbin "out/script/strings/scene/scene4-35.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 26.748
    cut_swapAndShowBuf

    ; "itsumo soba ni"
    .incbin "out/script/strings/scene/scene4-36.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 30.389
    cut_swapAndShowBuf

    ; "jareatte itai kara"
    .incbin "out/script/strings/scene/scene4-37.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 34.270
    cut_swapAndShowBuf

    ;===
    ; repeat of earlier chorus
    ;===
    
    ; "tomodachi da kara ne"
    .incbin "out/script/strings/scene/scene4-7.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 45.627
    cut_swapAndShowBuf
    
    ; "shikata ga nai wa ne"
    .incbin "out/script/strings/scene/scene4-8.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 49.204
    cut_swapAndShowBuf
    
    ; "sonna no ari"
    .incbin "out/script/strings/scene/scene4-9.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 52.900
    cut_swapAndShowBuf
    
    ; "touzen ari"
    .incbin "out/script/strings/scene/scene4-10.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 54.491
    cut_swapAndShowBuf
    
    ; "touzen ari"
    .incbin "out/script/strings/scene/scene4-11.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 3 56.321
    cut_swapAndShowBuf

    ;===
    ; finish
    ;===
    
    ; "hirogaru ginga ni"
    .incbin "out/script/strings/scene/scene4-38.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 4 0.183
    cut_swapAndShowBuf
    
    ; "ashita o mezashite"
    .incbin "out/script/strings/scene/scene4-39.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 4 3.770
    cut_swapAndShowBuf
    
    ; "miageta sora tabidatsu ima"
    .incbin "out/script/strings/scene/scene4-40.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 4 7.420
    cut_swapAndShowBuf
    
    ; "furimukanai de"
    .incbin "out/script/strings/scene/scene4-41.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 4 10.850
    cut_swapAndShowBuf
    
    ; "kitto go! go!"
    .incbin "out/script/strings/scene/scene4-42.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 4 14.032
    cut_swapAndShowBuf
    
    ; "yume e go! go!"
    .incbin "out/script/strings/scene/scene4-43.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6700
    
    cut_waitForFrameMinSec 4 17.665
    cut_swapAndShowBuf
    cut_showWithAltSat $6700
    
    cut_waitForFrameMinSec 4 21.987
    cut_subsOff
    
    ; "the end"
    .incbin "out/script/strings/scene/scene4-44.bin"
    SCENE_prepAndSendGrpAuto
    
    ; 0x4093/0x4160
    cut_waitForFrame $4093-2
    cut_swapAndShowBuf
    
    ; 0x41E9/0x42B6
    cut_waitForFrame $41E9-2
    cut_subsOff
    
    
    cut_terminator
.ends
