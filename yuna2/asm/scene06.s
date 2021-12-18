
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
    
;    cut_resetCompBuffers
;    cut_setPalette $08   
    
    cut_terminator
.ends
