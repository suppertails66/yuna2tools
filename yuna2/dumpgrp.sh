set -o errexit

mkdir -p rsrc/grp/orig

make

# ./grpunmap_pce "rsrc_raw/grp/carderror.bin" "rsrc_raw/grp/carderror.bin" 64 64 "rsrc/grp/orig/carderror.png" -v 0 -o 0 -p "rsrc_raw/pal/carderror.pal"
# ./grpunmap_pce "rsrc_raw/grp/carderror.bin" "rsrc_raw/grp/carderror.bin" 64 64 "rsrc/grp/orig/carderror_grayscale.png" -v 0 -o 0

# ./datsnip "yuna2_02.iso" 0x1851800 0x10000 "rsrc_raw/grp/interface_vram_raw.bin"
# ./grpdmp_pce "rsrc_raw/grp/interface_vram_raw.bin" "rsrc_raw/grp/interface_vram_raw.png"

# ./datsnip "yuna2_02.iso" 0x98B5AD6 0x4000 "rsrc_raw/grp/logo_ch5.bin"
# ./grpunmap_pce "rsrc_raw/grp/logo_ch5.bin" "rsrc_raw/grp/logo_ch5.bin" 64 64 "rsrc/grp/orig/logo_ch5.png" -v 0 -o 0 -p "rsrc_raw/pal/logo_ch5_bg_mod.pal"

# ./datsnip "yuna2_02.iso" 0x30D625A 0x8000 "rsrc_raw/grp/concert.bin"
# ./grpunmap_pce "rsrc_raw/grp/concert.bin" "rsrc_raw/grp/concert.bin" 64 64 "rsrc/grp/orig/concert.png" -v 0 -o 0 -p "rsrc_raw/pal/concert_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x9A6646E 0x8000 "rsrc_raw/grp/anderope_intro.bin"
# ./grpunmap_pce "rsrc_raw/grp/anderope_intro.bin" "rsrc_raw/grp/anderope_intro.bin" 64 64 "rsrc/grp/orig/anderope_intro.png" -v 0 -o 0 -p "rsrc_raw/pal/anderope_intro_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x9EA00 0x200 "rsrc_raw/grp/elline_name.bin"
# #./datsnip "yuna2_02.iso" 0xAEA00 0x200 "rsrc_raw/grp/elline_name2.bin"
# #./datsnip "yuna2_02.iso" 0xBEA00 0x200 "rsrc_raw/grp/elline_name3.bin"
# ./grpdmp_pce "rsrc_raw/grp/elline_name.bin" "rsrc/grp/orig/elline_name.png" -p "rsrc_raw/pal/anderope_name_line.pal" -r 8

# ./datsnip "yuna2_02.iso" 0xA1400 0x300 "rsrc_raw/grp/finisher.bin"
# #./datsnip "yuna2_02.iso" 0xB1400 0x200 "rsrc_raw/grp/elline_name2.bin"
# #./datsnip "yuna2_02.iso" 0xC1400 0x200 "rsrc_raw/grp/elline_name3.bin"
# ./spritedmp_pce "rsrc_raw/grp/finisher.bin" "rsrc/grp/orig/finisher.png" -p "rsrc_raw/pal/anderope_cards_line.pal" -r 2

# ./datsnip "yuna2_02.iso" 0x91400 0x300 "rsrc_raw/grp/battle_empty.bin"
# ./spritedmp_pce "rsrc_raw/grp/battle_empty.bin" "rsrc/grp/orig/battle_empty.png" -p "rsrc_raw/pal/battle_cards_line.pal" -r 2

# ./datsnip "yuna2_02.iso" 0x4db4286 0x6000 "rsrc_raw/grp/quiz.bin"
# ./grpunmap_pce "rsrc_raw/grp/quiz.bin" "rsrc_raw/grp/quiz.bin" 64 64 "rsrc/grp/orig/quiz.png" -v 0 -o 0 -p "rsrc_raw/pal/quiz_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x5DB4286 0x6000 "rsrc_raw/grp/quiz2.bin"
# ./grpunmap_pce "rsrc_raw/grp/quiz2.bin" "rsrc_raw/grp/quiz2.bin" 64 64 "rsrc/grp/orig/quiz2.png" -v 0 -o 0 -p "rsrc_raw/pal/quiz_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x4D4FA28 0x6000 "rsrc_raw/grp/ice.bin"
# #./datsnip "yuna2_02.iso" 0x5D4FA28 0x6000 "rsrc_raw/grp/ice.bin"
# ./grpunmap_pce "rsrc_raw/grp/ice.bin" "rsrc_raw/grp/ice.bin" 64 64 "rsrc/grp/orig/ice.png" -v 0 -o 0 -p "rsrc_raw/pal/ice_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x4D5CA28 0x6000 "rsrc_raw/grp/ice2.bin"
# #./datsnip "yuna2_02.iso" 0x5D5CA28 0x6000 "rsrc_raw/grp/ice2.bin"
# ./grpunmap_pce "rsrc_raw/grp/ice2.bin" "rsrc_raw/grp/ice2.bin" 64 64 "rsrc/grp/orig/ice2.png" -v 0 -o 0 -p "rsrc_raw/pal/ice2_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x4AE2228 0x6000 "rsrc_raw/grp/ice3.bin"
# #./datsnip "yuna2_02.iso" 0x5AE2228 0x6000 "rsrc_raw/grp/ice3.bin"
# ./grpunmap_pce "rsrc_raw/grp/ice3.bin" "rsrc_raw/grp/ice3.bin" 64 64 "rsrc/grp/orig/ice3.png" -v 0 -o 0 -p "rsrc_raw/pal/ice3_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x4AEAA28 0x6000 "rsrc_raw/grp/ice4.bin"
# #./datsnip "yuna2_02.iso" 0x5AEAA28 0x6000 "rsrc_raw/grp/ice4.bin"
# ./grpunmap_pce "rsrc_raw/grp/ice4.bin" "rsrc_raw/grp/ice4.bin" 64 64 "rsrc/grp/orig/ice4.png" -v 0 -o 0 -p "rsrc_raw/pal/ice4_bg.pal" -t

./datsnip "yuna2_02.iso" 0x4D76421 0x6000 "rsrc_raw/grp/ice5.bin"
#./datsnip "yuna2_02.iso" 0x5D76421 0x6000 "rsrc_raw/grp/ice5.bin"
./grpunmap_pce "rsrc_raw/grp/ice5.bin" "rsrc_raw/grp/ice5.bin" 64 64 "rsrc/grp/orig/ice5.png" -v 0 -o 0 -p "rsrc_raw/pal/ice5_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x7978AE5 0x6000 "rsrc_raw/grp/bathsign.bin"
# # ??? what is this?
# #./datsnip "yuna2_02.iso" 0x797F2E3 0x6000 "rsrc_raw/grp/bathsign.bin"
# #./datsnip "yuna2_02.iso" 0x7996AE5 0x6000 "rsrc_raw/grp/bathsign.bin"
# ./grpunmap_pce "rsrc_raw/grp/bathsign.bin" "rsrc_raw/grp/bathsign.bin" 64 64 "rsrc/grp/orig/bathsign.png" -v 0 -o 0 -p "rsrc_raw/pal/bathsign_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x7AC7530 0x6000 "rsrc_raw/grp/bathsign2.bin"
# ./grpunmap_pce "rsrc_raw/grp/bathsign2.bin" "rsrc_raw/grp/bathsign2.bin" 64 64 "rsrc/grp/orig/bathsign2.png" -v 0 -o 0 -p "rsrc_raw/pal/bathsign2_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x7ACED30 0x200 "rsrc_raw/grp/bathsign2.bin"
# ./spritedmp_pce "rsrc_raw/grp/bathsign2.bin" "rsrc/grp/orig/bathsign2.png" -p "rsrc_raw/pal/bathsign2_sign_line.pal" -r 2

# ./datsnip "yuna2_02.iso" 0x31A3228 0x6000 "rsrc_raw/grp/hatopoppo.bin"
# #./datsnip "yuna2_02.iso" 0x3954A28 0x6000 "rsrc_raw/grp/hatopoppo.bin"
# ./grpunmap_pce "rsrc_raw/grp/hatopoppo.bin" "rsrc_raw/grp/hatopoppo.bin" 64 64 "rsrc/grp/orig/hatopoppo.png" -v 0 -o 0 -p "rsrc_raw/pal/hatopoppo_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x1A3232B 0x2800 "rsrc_raw/grp/newschool.bin"
# ./spritedmp_pce "rsrc_raw/grp/newschool.bin" "rsrc_raw/grp/newschool.png" -p "rsrc_raw/pal/newschool_sign_line.pal"

# ./datsnip "yuna2_02.iso" 0x1ACF2A0 0xA000 "rsrc_raw/grp/doka.bin"
# ./grpunmap_pce "rsrc_raw/grp/doka.bin" "rsrc_raw/grp/doka.bin" 64 64 "rsrc/grp/orig/doka.png" -v 0 -o 0 -p "rsrc_raw/pal/doka_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x1AD9B36 0xC000 "rsrc_raw/grp/broadcast.bin"
# ./grpunmap_pce "rsrc_raw/grp/broadcast.bin" "rsrc_raw/grp/broadcast.bin" 64 64 "rsrc/grp/orig/broadcast.png" -v 0 -o 0 -p "rsrc_raw/pal/broadcast_bg_mod.pal" -t

# ./datsnip "yuna2_02.iso" 0x1C0D623 0xA000 "rsrc_raw/grp/continued.bin"
# #./datsnip "yuna2_02.iso" 0x940D623 0xA000 "rsrc_raw/grp/continued.bin"

# ./datsnip "yuna2_02.iso" 0x40050C 0x10000 "rsrc_raw/grp/intro_subgrp1_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/intro_subgrp1_cmp.bin" "rsrc_raw/grp/intro_subgrp1.bin"
# ./spritedmp_pce "rsrc_raw/grp/intro_subgrp1.bin" "rsrc_raw/grp/intro_subgrp1.png"

# ./datsnip "yuna2_02.iso" 0x3FFCCD 0x10000 "rsrc_raw/grp/intro_subgrp1_def_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/intro_subgrp1_def_cmp.bin" "rsrc_raw/grp/intro_subgrp1_def.bin"

# ./datsnip "yuna2_02.iso" 0x429F66 0x10000 "rsrc_raw/grp/intro_subgrp2_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/intro_subgrp2_cmp.bin" "rsrc_raw/grp/intro_subgrp2.bin"
# ./spritedmp_pce "rsrc_raw/grp/intro_subgrp2.bin" "rsrc_raw/grp/intro_subgrp2.png"

# ./datsnip "yuna2_02.iso" 0x429C48 0x10000 "rsrc_raw/grp/intro_subgrp2_def_cmp.bin"
# #./datsnip "yuna2_02.iso" 0x3F9B5F 0x10000 "rsrc_raw/grp/intro_subgrp2_def_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/intro_subgrp2_def_cmp.bin" "rsrc_raw/grp/intro_subgrp2_def.bin"

# ./datsnip "yuna2_02.iso" 0x1D74A80 0xA000 "rsrc_raw/grp/diagram.bin"
# #./datsnip "yuna2_02.iso" 0x9574A5B 0xA000 "rsrc_raw/grp/diagram.bin"
# ./grpunmap_pce "rsrc_raw/grp/diagram.bin" "rsrc_raw/grp/diagram.bin" 64 64 "rsrc/grp/orig/diagram.png" -v 0 -o 0 -p "rsrc_raw/pal/diagram_bg.pal" -t
# ./spritedmp_pce "rsrc_raw/grp/diagram.bin" "rsrc/grp/orig/diagram_ship.png" -p "rsrc_raw/pal/diagram_spr.pal" -s $((0xCC*0x80)) -r 4 -n 4

# ./datsnip "yuna2_02.iso" 0x55400 0x200 "rsrc_raw/grp/spaceduck_label.bin"
# ./spritedmp_pce "rsrc_raw/grp/spaceduck_label.bin" "rsrc/grp/orig/spaceduck_label.png" -p "rsrc_raw/pal/spaceduck_label_line.pal" -r 2 -n 4

# ./datsnip "yuna2_02.iso" 0x4DDFA28 0x8000 "rsrc_raw/grp/windmtn.bin"
# #./datsnip "yuna2_02.iso" 0x5DDFA28 0x8000 "rsrc_raw/grp/windmtn.bin"
# #./datsnip "yuna2_02.iso" 0x72CDC50 0x8000 "rsrc_raw/grp/windmtn.bin"
# ./grpunmap_pce "rsrc_raw/grp/windmtn.bin" "rsrc_raw/grp/windmtn.bin" 64 64 "rsrc/grp/orig/windmtn.png" -v 0 -o 0 -p "rsrc_raw/pal/windmtn_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x7A67A28 0x8000 "rsrc_raw/grp/firebird.bin"
# ./grpunmap_pce "rsrc_raw/grp/firebird.bin" "rsrc_raw/grp/firebird.bin" 64 64 "rsrc/grp/orig/firebird.png" -v 0 -o 0 -p "rsrc_raw/pal/firebird_bg.pal" -t

# ./datsnip "yuna2_02.iso" 0x72FDF89 0x8000 "test.bin"
# ./spritedmp_pce "test.bin" "test.png"

# #./datsnip "yuna2_02.iso" 0x49ABA28 0x6000 "rsrc_raw/grp/firebird.bin"
# ./datsnip "yuna2_02.iso" 0x49ABA28 0xA000 "rsrc_raw/grp/ferriswheel.bin"
# #./datsnip "yuna2_02.iso" 0x59ABA28 0xA000 "rsrc_raw/grp/ferriswheel.bin"
# ./grpunmap_pce "rsrc_raw/grp/ferriswheel.bin" "rsrc_raw/grp/ferriswheel.bin" 64 64 "rsrc/grp/orig/ferriswheel.png" -v 0 -o 0 -p "rsrc_raw/pal/ferriswheel_bg.pal" -t

################
# my conclusion after dumping all these graphics:
# to hell with translating the credits, opening or otherwise.
# i'd have to completely rework so much crap to make it happen,
# and no one cares about or reads this stuff anyway.
# you want the names, they're on mobygames.
################

# ./datsnip "yuna2_02.iso" 0x3B6900 0x700 "rsrc_raw/grp/op_cred1.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred1.bin" "rsrc_raw/grp/op_cred1.png"
# 
# ./datsnip "yuna2_02.iso" 0x3E3A63 0x10000 "rsrc_raw/grp/op_cred2_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred2_cmp.bin" "rsrc_raw/grp/op_cred2.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred2.bin" "rsrc_raw/grp/op_cred2.png"
# 
# ./datsnip "yuna2_02.iso" 0x3E3F75 0x10000 "rsrc_raw/grp/op_cred3_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred3_cmp.bin" "rsrc_raw/grp/op_cred3.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred3.bin" "rsrc_raw/grp/op_cred3.png"
# 
# ./datsnip "yuna2_02.iso" 0x3BBF91 0x10000 "rsrc_raw/grp/op_cred4_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred4_cmp.bin" "rsrc_raw/grp/op_cred4.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred4.bin" "rsrc_raw/grp/op_cred4.png"
# 
# ./datsnip "yuna2_02.iso" 0x3C4E5D 0x10000 "rsrc_raw/grp/op_cred5_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred5_cmp.bin" "rsrc_raw/grp/op_cred5.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred5.bin" "rsrc_raw/grp/op_cred5.png"
# 
# ./datsnip "yuna2_02.iso" 0x3CAD23 0x10000 "rsrc_raw/grp/op_cred6_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred6_cmp.bin" "rsrc_raw/grp/op_cred6.bin"
# #./spritedmp_pce "rsrc_raw/grp/op_cred6.bin" "rsrc_raw/grp/op_cred6.png"
# ./grpdmp_pce "rsrc_raw/grp/op_cred6.bin" "rsrc_raw/grp/op_cred6.png"
# 
# ./datsnip "yuna2_02.iso" 0x3CF888 0x10000 "rsrc_raw/grp/op_cred7_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred7_cmp.bin" "rsrc_raw/grp/op_cred7.bin"
# ./grpdmp_pce "rsrc_raw/grp/op_cred7.bin" "rsrc_raw/grp/op_cred7.png"
# 
# ./datsnip "yuna2_02.iso" 0x3D54A5 0x10000 "rsrc_raw/grp/op_cred8_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred8_cmp.bin" "rsrc_raw/grp/op_cred8.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred8.bin" "rsrc_raw/grp/op_cred8.png"
# 
# ./datsnip "yuna2_02.iso" 0x3DBE26 0x10000 "rsrc_raw/grp/op_cred9_cmp.bin"
# ./yuna2_decmp "rsrc_raw/grp/op_cred9_cmp.bin" "rsrc_raw/grp/op_cred9.bin"
# ./spritedmp_pce "rsrc_raw/grp/op_cred9.bin" "rsrc_raw/grp/op_cred9.png"


