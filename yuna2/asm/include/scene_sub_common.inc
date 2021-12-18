
;==============================================================================
; 
;==============================================================================

; could someone please rewrite wla-dx to allow dynamic bank sizes?
; thanks
.memorymap
   defaultslot     0
   
   slotsize        $1000
   slot            0       $9000
.endme

.rombankmap
  bankstotal $1
  
  banksize $1000
  banks $1
.endro

.emptyfill $FF

.background "scene_dummy.bin"
