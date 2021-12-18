
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
    ; TRACK 03 START
    ;==========================================
    
    SYNC_cdTime 1 0.000
    
    SCENE_setUpAutoPlace $01C8 $1C
    
    ;=====
    ; fleet far pan
    ;=====
    
;    cut_waitForFrame $0100
    
    cut_waitForFrameMinSec 0 3.000

    ; "area 110"
    .incbin "out/script/strings/scene/scene1-0.bin"
;    cut_prepAndSendGrp $01C8
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 10.943
    cut_swapAndShowBuf
    
    cut_setHighPrioritySprObjOffset 12

    ; "photon torpedo loading"
    .incbin "out/script/strings/scene/scene1-1.bin"
;    cut_prepAndSendGrp $01E4
    SCENE_prepAndSendGrpAuto
    cut_waitForFrameMinSec 0 14.182
;    cut_subsOff
    cut_swapAndShowBuf
    
    ;=====
    ; fleet close pan
    ;=====

    ; "visual room"
    .incbin "out/script/strings/scene/scene1-6.bin"
    ; wait until blackout ends to send graphics
    cut_waitForFrameMinSec 0 17.953
;    cut_prepAndSendGrp $01C8
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 18.469
;    cut_subsOff
    cut_swapAndShowBuf

    ; "noncombatants"
;    .incbin "out/script/strings/scene/scene1-7.bin"
;    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 20.142+0.100
      cut_subsOff
      
      ; *** CACHE: "reaction on the"
      .incbin "out/script/strings/scene/scene1-10.bin"
      cut_prepAndSendGrp $01B0
;      cut_writeBackQueueToAltSat $6B00
      cut_swapBuf
    
    ; "noncombatants"
    .incbin "out/script/strings/scene/scene1-7.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 21.589
;    cut_subsOff
    cut_swapAndShowBuf

    ; "have we received"
    .incbin "out/script/strings/scene/scene1-8.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 24.176
;    cut_subsOff
    cut_swapAndShowBuf

    ; "all ships, stand by"
    .incbin "out/script/strings/scene/scene1-9.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6B00
    
;    cut_waitForFrameMinSec 0 26.082-0.050
    ; NOTE: this line starts very very very close to the cutoff point
    ; at which we can no longer swap in the subtitles normally.
    ; a few frames too late and it will fail.
    ; exercise caution.
;    cut_waitForFrameMinSec 0 26.082-0.150
/*    cut_waitForFrameMinSec 0 26.082-0.050
    cut_swapAndShowBuf*/

    cut_waitForFrameMinSec 0 26.082
;    cut_subsOff
    cut_showWithAltSat $6B00
    ; this is just for some extra insurance in case emulator/hardware timing
    ; is slightly off and we missed our target window
    cut_waitForFrameMinSec 0 26.082+0.020
    cut_showWithAltSat $6B00
    cut_waitForFrameMinSec 0 26.082+0.040
    cut_showWithAltSat $6B00
    cut_waitForFrameMinSec 0 26.082+0.060
    cut_showWithAltSat $6B00
    cut_waitForFrameMinSec 0 26.082+0.080
    cut_showWithAltSat $6B00
    cut_waitForFrameMinSec 0 26.082+0.100
    cut_showWithAltSat $6B00
    ; we are now hopefully within the blackout zone,
    ; so set up the subtitles properly
    cut_waitForFrameMinSec 0 26.082+0.200
    cut_swapAndShowBuf
    
    ;=====
    ; ship interior overview
    ;=====

    ; DECACHE: "reaction on the"
    .incbin "out/script/strings/scene/scene1-10.bin"
    ; wait until blackout over
;    cut_waitForFrameMinSec 0 28.199
;    SCENE_prepAndSendGrpAuto
    ; ready sprite attr
    cut_prepSpriteAttr $01B0
    
;    cut_waitForFrameMinSec 0 28.241
    cut_waitForFrameMinSec 0 28.199
;    cut_subsOff
    cut_swapAndShowBuf

    ; "enemy fleet emerging"
    .incbin "out/script/strings/scene/scene1-11.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 30.405+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 31.484
;    cut_subsOff
    cut_swapAndShowBuf

    ; "their numbers..."
    .incbin "out/script/strings/scene/scene1-12.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 33.535
    cut_swapAndShowBuf

    ; "around one-tenth"
    .incbin "out/script/strings/scene/scene1-13.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6B00
    
    cut_waitForFrameMinSec 0 35.182
    cut_swapAndShowBuf
    cut_showWithAltSat $6B00
    
    ;=====
    ; alarm screen
    ;=====

    ; "wait... there's something"
    .incbin "out/script/strings/scene/scene1-15.bin"
    
      cut_waitForFrameMinSec 0 37.584
      cut_subsOff
    
    ; wait for blackout to end
    cut_waitForFrameMinSec 0 38.555
    SCENE_prepAndSendGrpAuto
    cut_waitForFrameMinSec 0 39.143
    cut_swapAndShowBuf

    ; "my god"
    .incbin "out/script/strings/scene/scene1-16.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 41.333
    cut_swapAndShowBuf
    
    ;=====
    ; radar ship
    ;=====

    ; "they have a ship"
    .incbin "out/script/strings/scene/scene1-17.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 42.118+0.200
      cut_subsOff
    
    cut_waitForFrameMinSec 0 46.457
    cut_swapAndShowBuf
    
    ;=====
    ; report to princess
    ;=====

    ; "princess, it's the enemy"
    .incbin "out/script/strings/scene/scene1-18.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 48.517
      cut_subsOff
    
    cut_waitForFrameMinSec 0 55.970
    cut_swapAndShowBuf

    ; "calm yourselves"
    .incbin "out/script/strings/scene/scene1-19.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 57.680
      cut_subsOff
    
    cut_waitForFrameMinSec 1 2.271
    cut_swapAndShowBuf
    
    ;=====
    ; ryudia closeup
    ;=====

    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene1-99.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6B00
    ; switch off during blackout by showing "blank" sprite table
    cut_waitForFrameMinSec 1 3.480
    cut_swapBuf
    cut_showWithAltSat $6B00
    cut_subsOff
    
    ; ensure we're not blacked out before sending next lines
    cut_waitForFrameMinSec 1 7.000

    ; "so the ringleader"
    .incbin "out/script/strings/scene/scene1-23.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 1 13.251
    cut_swapAndShowBuf

    ; "gravitons detected"
    .incbin "out/script/strings/scene/scene1-24.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 15.379+0.500
      cut_subsOff
    
    ; set sprites to "default-off" for next scene
;    cut_andOr $20F3 $BF $00
    
    ;==========================================
    ; TRACK 04 START
    ;==========================================
    
    SYNC_cdTime 2 0.000
    
    ;=====
    ; ship interior pan up
    ;=====
    
    cut_waitForFrameMinSec 0 3.313
    cut_swapAndShowBuf

    ; "all hands"
    .incbin "out/script/strings/scene/scene1-25.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 4.722
    cut_swapAndShowBuf

    ; "incoming"
    .incbin "out/script/strings/scene/scene1-26.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 6.131+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 7.031
    cut_swapAndShowBuf
    
    SCENE_setUpAutoPlace $01D0 $1C

    ; "i am the eternal"
    .incbin "out/script/strings/scene/scene1-27.bin"
    
      cut_waitForFrameMinSec 0 7.748+0.250
      cut_subsOff
    
    SCENE_prepAndSendGrpAuto
    
    ; set sprites to "default-off" for next scenes
;    cut_andOr $20F3 $DF $00
    
    ;=====
    ; princess mirage intro
    ;=====
    
    cut_waitForFrameMinSec 0 57.030
    cut_swapAndShowBuf

    ; "i am justice"
    .incbin "out/script/strings/scene/scene1-28.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 59.626
      cut_subsOff
    
    cut_waitForFrameMinSec 1 2.013
    cut_swapAndShowBuf
    
    SCENE_setUpAutoPlace $01CE $20

    ; "all who oppose"
    .incbin "out/script/strings/scene/scene1-29.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 4.296
      cut_subsOff
    
    cut_waitForFrameMinSec 1 6.213
    cut_swapAndShowBuf
    
    ; sprites default-on
    ; (rcr is disabled during this transition, so this is needed
    ; to keep subtitles visible)
    cut_andOr $20F3 $FF $40

    ; "all who oppose"
    .incbin "out/script/strings/scene/scene1-29.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 9.292
      cut_subsOff
    
    ; sprites default-off
    cut_andOr $20F3 ($40~$FF) $00
    
    cut_waitForFrameMinSec 1 11.170
    cut_swapAndShowBuf

    ; "the green planet"
    .incbin "out/script/strings/scene/scene1-30.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 14.666
      cut_subsOff
    
    cut_waitForFrameMinSec 1 17.497
    cut_swapAndShowBuf

    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene1-99.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $7200
    ; switch off during blackout by showing "blank" sprite table
    cut_waitForFrameMinSec 1 21.488+0.300
    cut_swapBuf
    cut_showWithAltSat $7200
    cut_subsOff

    ; "no matter what, we must"
    .incbin "out/script/strings/scene/scene1-31.bin"
    cut_waitForFrameMinSec 1 23.500
    SCENE_prepAndSendGrpAuto
    
;      cut_waitForFrameMinSec 1 21.488+0.300
;      cut_subsOff
    
    cut_waitForFrameMinSec 1 24.123
    cut_swapAndShowBuf
    
      cut_waitForFrameMinSec 1 26.263+0.400
      cut_subsOff
    
    SCENE_setUpAutoPlace $01C0 $20

    ; "all personnel, prepare"
    .incbin "out/script/strings/scene/scene1-32.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 05 START
    ;==========================================
    
    SYNC_cdTime 3 0.000
    
    cut_waitForFrameMinSec 0 8.059
    cut_swapAndShowBuf
    
    ;=====
    ; fleet exterior
    ;=====

    ; "anticipating combat"
    .incbin "out/script/strings/scene/scene1-33.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 10.448
    cut_swapAndShowBuf

    ; "all ships, prepare"
    .incbin "out/script/strings/scene/scene1-34.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 12.802
    cut_swapAndShowBuf

    ; "photon torpedo firing"
    .incbin "out/script/strings/scene/scene1-35.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 14.281
    cut_swapAndShowBuf

    ; "??? 120%"
    .incbin "out/script/strings/scene/scene1-36.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 16.528
    cut_swapAndShowBuf

    ; "here it comes"
    .incbin "out/script/strings/scene/scene1-37.bin"
    SCENE_prepAndSendGrpAuto
    cut_writeBackQueueToAltSat $6F00
    
    cut_waitForFrameMinSec 0 18.908
    cut_swapAndShowBuf
    cut_showWithAltSat $6F00
    
    ; cut this line off whenever the blackout ends
    cut_subsOff
    
    ;=====
    ; readying guns
    ;=====

    ; "open all gunports"
    .incbin "out/script/strings/scene/scene1-38.bin"
    cut_waitForFrameMinSec 0 20.085
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 20.785
    cut_swapAndShowBuf

    ; "fire"
    .incbin "out/script/strings/scene/scene1-39.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 22.336+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 26.352
    cut_swapAndShowBuf

    ; "neighboring ships"
    .incbin "out/script/strings/scene/scene1-40.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 27.555+0.300
      cut_subsOff
    
    ;=====
    ; status report
    ;=====
    
    cut_waitForFrameMinSec 0 45.429
    cut_swapAndShowBuf

    ; "we've taken a hit"
    .incbin "out/script/strings/scene/scene1-41.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 47.275
    cut_swapAndShowBuf

    ; "your highness, powerful"
    .incbin "out/script/strings/scene/scene1-43.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 50.315
    cut_swapAndShowBuf

    ; "what"
    .incbin "out/script/strings/scene/scene1-44.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 53.649
    cut_swapAndShowBuf

    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene1-99.bin"
;    SCENE_prepAndSendGrpAuto
    cut_prepAndSendGrp $01B8
    cut_writeBackQueueToAltSat $6F00
    ; switch off during blackout by showing "blank" sprite table
    cut_waitForFrameMinSec 0 53.649+1.000
    cut_swapBuf
    cut_showWithAltSat $6F00
    cut_subsOff
      
    cut_waitForFrameMinSec 0 58.000
    ; *** CACHE: "full power to shields"
    .incbin "out/script/strings/scene/scene1-46.bin"
;    SCENE_prepAndSendGrpAuto
    cut_prepAndSendGrp $01E0
    cut_swapBuf

    ; "no"
    .incbin "out/script/strings/scene/scene1-45.bin"
;    cut_waitForFrameMinSec 0 58.000
;    SCENE_prepAndSendGrpAuto
    cut_prepAndSendGrp $01C0
    
;      cut_waitForFrameMinSec 0 53.649+1.000
;      cut_subsOff
    
    ;==========================================
    ; TRACK 06 START
    ;==========================================
    
    SYNC_cdTime 4 0.000
    
    ;=====
    ; princess fires
    ;=====
    
    cut_waitForFrameMinSec 0 0.131
    cut_swapAndShowBuf
    
;    .incbin "out/script/strings/scene/scene1-99.bin"
;    cut_swapBuf
    ; recycle previously generated blank sprite table
    cut_waitForFrameMinSec 0 0.131+1.000
    cut_showWithAltSat $6F00
    cut_subsOff
    
    ;=====
    ; defensive orders
    ;=====

    ; DECACHE: "full power to shields"
    .incbin "out/script/strings/scene/scene1-46.bin"
;    SCENE_prepAndSendGrpAuto
    ; ready sprite attr
    cut_prepSpriteAttr $01E0
    
    cut_waitForFrameMinSec 0 2.762
    cut_swapAndShowBuf
    
;    SCENE_setUpAutoPlace $01C0 $20
    SCENE_setUpAutoPlace $01C8 $1C

    ; "i-it's no good"
    .incbin "out/script/strings/scene/scene1-47.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 5.260+0.300
      cut_subsOff
    
    cut_waitForFrameMinSec 0 23.609
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 25.878
    cut_subsOff
      
    ; dummy line for blanking subs during blackout
    .incbin "out/script/strings/scene/scene1-99.bin"
;    SCENE_prepAndSendGrpAuto
    ; wait for blackout to end
    cut_waitForFrameMinSec 0 30.000
    cut_prepAndSendGrp $01FF
    cut_writeBackQueueToAltSat $7100
    cut_swapBuf

    ; "i am the princess"
    .incbin "out/script/strings/scene/scene1-48.bin"
    SCENE_prepAndSendGrpAuto
    
    ;==========================================
    ; TRACK 07 START
    ;==========================================
    
;    SCENE_setUpAutoPlace $01C4 $1E
    
    SYNC_cdTime 5 0.000
    
    cut_waitForFrameMinSec 0 6.715
    cut_writeBackQueueToAltSat $7000
    cut_swapAndShowBuf
    
    ; sprites default-on
    ; (rcr is disabled during this transition, so this is needed
    ; to keep subtitles visible)
    cut_andOr $20F3 $FF $40

    ; "my mission is"
    .incbin "out/script/strings/scene/scene1-49.bin"
    SCENE_prepAndSendGrpAuto
    
    ; wait until blackout
    cut_waitForFrameMinSec 0 8.185
    cut_showWithAltSat $7000
    
;      cut_waitForFrameMinSec 0 9.528
;      cut_subsOff
      ; switch off during blackout by showing "blank" sprite table
      cut_waitForFrameMinSec 0 9.528
      cut_showWithAltSat $7100
      cut_subsOff
    
    cut_waitForFrameMinSec 0 11.026
    cut_swapAndShowBuf

    ; "those who defy me"
    .incbin "out/script/strings/scene/scene1-50.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 14.136
      cut_subsOff
    
    cut_waitForFrameMinSec 0 15.960
    cut_swapAndShowBuf

    ; "report to me the evil"
    .incbin "out/script/strings/scene/scene1-51.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 18.688
    cut_swapAndShowBuf

    ; "report to me" (1)
    .incbin "out/script/strings/scene/scene1-52.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 21.968
    cut_swapAndShowBuf

    ; "report to me" (2)
    .incbin "out/script/strings/scene/scene1-52.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 24.682
    cut_swapAndShowBuf

    ; "report to me" (3)
    .incbin "out/script/strings/scene/scene1-52.bin"
    SCENE_prepAndSendGrpAuto
    
    cut_waitForFrameMinSec 0 27.566
    cut_swapAndShowBuf

    ; "report to me" (4)
    .incbin "out/script/strings/scene/scene1-52.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 0 29.799
      cut_subsOff
      
      ; sprites default-off
      cut_andOr $20F3 ($40~$FF) $00
    
    cut_waitForFrameMinSec 0 31.510
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 0 33.899
    cut_subsOff
    
    SCENE_setUpAutoPlace $01C0 $20

    ; "nooooo"
    .incbin "out/script/strings/scene/scene1-53.bin"
    SCENE_prepAndSendGrpAuto
    
    ;=====
    ; yuna dream
    ;=====
    
    cut_waitForFrameMinSec 1 4.292
    cut_swapAndShowBuf

    ; "???"
    .incbin "out/script/strings/scene/scene1-54.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 6.752
      cut_subsOff
    
    cut_waitForFrameMinSec 1 9.113
    cut_swapAndShowBuf

    ; "???"
    .incbin "out/script/strings/scene/scene1-55.bin"
    SCENE_prepAndSendGrpAuto
    
      cut_waitForFrameMinSec 1 13.495
      cut_subsOff
    
    cut_waitForFrameMinSec 1 15.022
    cut_swapAndShowBuf
    
    cut_waitForFrameMinSec 1 23.687
    cut_subsOff
    
;      cut_waitForFrameMinSec 0 0.131+1.000
;      cut_subsOff
    
/*;    .incbin "include/scene18/string250000.bin"
    .db $6E,$79,$87,$88,$50,$52,$07
;    .db $6E,$79,$87,$88,$50,$53,$07
;    .db $6E,$79,$87,$88,$50,$54,$07
;    .db $6E,$79,$87,$88,$50,$55,$07
    cut_prepAndSendGrp $01E8
    
    cut_waitForFrameMinSec 0 5.000
    cut_swapAndShowBuf
    
;    cut_waitForFrameMinSec 0 7.000
    
    .db $6E,$79,$87,$88,$50,$56,$07
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
