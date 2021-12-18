
echo "*******************************************************************************"
echo "Setting up environment..."
echo "*******************************************************************************"

set -o errexit

BASE_PWD=$PWD
PATH=".:$PATH"
INROM="yuna2_02.iso"
OUTROM="yuna2_02_build.iso"
WLADX="./wla-dx/binaries/wla-huc6280"
WLALINK="./wla-dx/binaries/wlalink"
DISCASTER="../discaster/discaster"

function remapPalette() {
  oldFile=$1
  palFile=$2
  newFile=$3
  
  convert "$oldFile" -dither None -remap "$palFile" PNG32:$newFile
}

function remapPaletteOverwrite() {
  newFile=$1
  palFile=$2
  
  remapPalette $newFile $palFile $newFile
}

# remapPaletteOverwrite "rsrc/grp/logo_eyecatch.png" "rsrc/grp/logo_eyecatch_remap.png"
# remapPaletteOverwrite "rsrc/grp/title_subtitle.png" "rsrc/grp/title_subtitle_remap.png"
# remapPaletteOverwrite "rsrc/grp/logo_ch5.png" "rsrc/grp/orig/logo_ch5.png"
# remapPaletteOverwrite "rsrc/grp/finisher.png" "rsrc/grp/orig/finisher.png"
# remapPaletteOverwrite "rsrc/grp/battle_empty.png" "rsrc/grp/orig/battle_empty.png"
# remapPaletteOverwrite "rsrc/grp/quiz.png" "rsrc/grp/quiz_remap.png"
# remapPaletteOverwrite "rsrc/grp/ice.png" "rsrc/grp/ice_remap.png"
# remapPaletteOverwrite "rsrc/grp/hatopoppo.png" "rsrc/grp/hatopoppo_remap.png"
# remapPaletteOverwrite "rsrc/grp/tv.png" "rsrc/grp/orig/tv.png"
# remapPaletteOverwrite "rsrc/grp/newschool.png" "rsrc/grp/newschool_remap.png"
# remapPaletteOverwrite "rsrc/grp/continued.png" "rsrc/grp/orig/continued.png"
# remapPaletteOverwrite "rsrc/grp/continued.png" "rsrc/grp/continued_remap.png"
# remapPaletteOverwrite "rsrc/grp/diagram_ship.png" "rsrc/grp/diagram_ship_remap.png"
# remapPaletteOverwrite "rsrc/grp/diagram.png" "rsrc/grp/diagram_remap.png"
# remapPaletteOverwrite "rsrc/grp/windmtn.png" "rsrc/grp/windmtn_remap.png"
# remapPaletteOverwrite "rsrc/grp/ferriswheel_sign.png" "rsrc/grp/ferriswheel_sign_remap.png"
# exit

#mkdir -p log
mkdir -p out

echo "********************************************************************************"
echo "Building project tools..."
echo "********************************************************************************"

make blackt
make libpce
make

if [ ! -f $WLADX ]; then
  
  echo "********************************************************************************"
  echo "Building WLA-DX..."
  echo "********************************************************************************"
  
  cd wla-dx
    cmake -G "Unix Makefiles" .
    make
  cd $BASE_PWD
  
fi

echo "*******************************************************************************"
echo "Copying binaries..."
echo "*******************************************************************************"

cp -r base out
cp -r rsrc_raw out

cp "$INROM" "$OUTROM"

echo "*******************************************************************************"
echo "Building font..."
echo "*******************************************************************************"

numFontChars=96
numLimitedFontChars=80
bytesPerFontChar=10

mkdir -p out/font
fontbuild "font/" "out/font/font.bin" "out/font/fontwidth.bin"
fontbuild "font/scene/" "out/font/font_scene.bin" "out/font/fontwidth_scene.bin"
fontbuild "font/narrow/" "out/font/font_narrow.bin" "out/font/fontwidth_narrow.bin"

# well shit, hoped i wouldn't have to resort to this again
datsnip "out/font/font.bin" 0 $(($numLimitedFontChars*$bytesPerFontChar)) "out/font/font_limited.bin"
datsnip "out/font/fontwidth.bin" 0 $(($numLimitedFontChars*1)) "out/font/fontwidth_limited.bin"

echo "*******************************************************************************"
echo "Trimming large scene graphics..."
echo "*******************************************************************************"

function doGrpCut() {
  name=$1
  startOffset=$2
  endOffset=$3
  
  datsnip "out/rsrc_raw/grp/${name}_decmp.bin" $startOffset $endOffset "out/rsrc_raw/grp/${name}_decmp.bin"
  yuna2_cmp "out/rsrc_raw/grp/${name}_decmp.bin" "out/rsrc_raw/grp/${name}.bin"
}

#datsnip "out/rsrc_raw/grp/intro_biggrp1_decmp.bin" 0 0xE800 "out/rsrc_raw/grp/intro_biggrp1_decmp.bin"
#yuna2_cmp "out/rsrc_raw/grp/intro_biggrp1_decmp.bin" "out/rsrc_raw/grp/intro_biggrp1.bin"
doGrpCut "scene00_biggrp1" 0 0xE400
doGrpCut "scene05_biggrp1" 0 0xE400
doGrpCut "intro_biggrp1" 0 0xE800

# subrender "font/scene/" "font/scene/table.tbl" "asm/include/scene10/string170006.bin" "table/yuna_scenes_en.tbl" "out/grp/scene10-170006.png"
# subrender "font/scene/" "font/scene/table.tbl" "asm/include/scene10/string170007.bin" "table/yuna_scenes_en.tbl" "out/grp/scene10-170007.png"
# subrender "font/scene/" "font/scene/table.tbl" "asm/include/scene10/string170008.bin" "table/yuna_scenes_en.tbl" "out/grp/scene10-170008.png"
# subrender "font/scene/" "font/scene/table.tbl" "asm/include/scene10/string170009.bin" "table/yuna_scenes_en.tbl" "out/grp/scene10-170009.png"
# subrender "font/scene/" "font/scene/table.tbl" "asm/include/scene10/string170010.bin" "table/yuna_scenes_en.tbl" "out/grp/scene10-170010.png"
# datsnip "out/pal/scene10_pan.pal" $((0x7*0x20)) 0x20 "out/pal/scene10_pan_line.pal"

echo "*******************************************************************************"
echo "Building graphics..."
echo "*******************************************************************************"

mkdir -p out/grp
mkdir -p out/maps

# remapPaletteOverwrite "out/grp/intro_suit_patch.png" "out/grp/orig/intro_suit_patch.png"
# remapPaletteOverwrite "out/grp/scene00_patch.png" "out/grp/orig/scene00_patch.png"

for file in tilemappers/*.txt; do
  tilemapper_pce "$file"
done;

datpatch "out/rsrc_raw/grp/carderror.bin" "out/rsrc_raw/grp/carderror.bin" "out/grp/carderror.bin" 0x2020
datpatch "out/rsrc_raw/grp/carderror.bin" "out/rsrc_raw/grp/carderror.bin" "out/maps/carderror.bin" 0x0000

datpatch "out/rsrc_raw/grp/logo_ch5.bin" "out/rsrc_raw/grp/logo_ch5.bin" "out/grp/logo_ch5.bin" 0x2020
datpatch "out/rsrc_raw/grp/logo_ch5.bin" "out/rsrc_raw/grp/logo_ch5.bin" "out/maps/logo_ch5.bin" 0x0000

datpatch "out/rsrc_raw/grp/concert.bin" "out/rsrc_raw/grp/concert.bin" "out/grp/concert.bin" 0x2020
datpatch "out/rsrc_raw/grp/concert.bin" "out/rsrc_raw/grp/concert.bin" "out/maps/concert.bin" 0x0000

datpatch "out/rsrc_raw/grp/quiz.bin" "out/rsrc_raw/grp/quiz.bin" "out/grp/quiz.bin" 0x2020
datpatch "out/rsrc_raw/grp/quiz.bin" "out/rsrc_raw/grp/quiz.bin" "out/maps/quiz.bin" 0x0000

datpatch "out/rsrc_raw/grp/ice.bin" "out/rsrc_raw/grp/ice.bin" "out/grp/ice.bin" 0x2020
datpatch "out/rsrc_raw/grp/ice.bin" "out/rsrc_raw/grp/ice.bin" "out/maps/ice.bin" 0x0000
datpatch "out/rsrc_raw/grp/ice2.bin" "out/rsrc_raw/grp/ice2.bin" "out/grp/ice2.bin" 0x2020
datpatch "out/rsrc_raw/grp/ice2.bin" "out/rsrc_raw/grp/ice2.bin" "out/maps/ice2.bin" 0x0000
datpatch "out/rsrc_raw/grp/ice3.bin" "out/rsrc_raw/grp/ice3.bin" "out/grp/ice3.bin" 0x2020
datpatch "out/rsrc_raw/grp/ice3.bin" "out/rsrc_raw/grp/ice3.bin" "out/maps/ice3.bin" 0x0000
datpatch "out/rsrc_raw/grp/ice4.bin" "out/rsrc_raw/grp/ice4.bin" "out/grp/ice4.bin" 0x2020
datpatch "out/rsrc_raw/grp/ice4.bin" "out/rsrc_raw/grp/ice4.bin" "out/maps/ice4.bin" 0x0000
datpatch "out/rsrc_raw/grp/ice5.bin" "out/rsrc_raw/grp/ice5.bin" "out/grp/ice5.bin" 0x2020
datpatch "out/rsrc_raw/grp/ice5.bin" "out/rsrc_raw/grp/ice5.bin" "out/maps/ice5.bin" 0x0000

datpatch "out/rsrc_raw/grp/bathsign.bin" "out/rsrc_raw/grp/bathsign.bin" "out/grp/bathsign.bin" 0x2020
datpatch "out/rsrc_raw/grp/bathsign.bin" "out/rsrc_raw/grp/bathsign.bin" "out/maps/bathsign.bin" 0x0000

datpatch "out/rsrc_raw/grp/hatopoppo.bin" "out/rsrc_raw/grp/hatopoppo.bin" "out/grp/hatopoppo.bin" 0x2020
datpatch "out/rsrc_raw/grp/hatopoppo.bin" "out/rsrc_raw/grp/hatopoppo.bin" "out/maps/hatopoppo.bin" 0x0000

datpatch "out/rsrc_raw/grp/doka.bin" "out/rsrc_raw/grp/doka.bin" "out/grp/doka.bin" 0x2020
datpatch "out/rsrc_raw/grp/doka.bin" "out/rsrc_raw/grp/doka.bin" "out/maps/doka.bin" 0x0000

datpatch "out/rsrc_raw/grp/broadcast.bin" "out/rsrc_raw/grp/broadcast.bin" "out/grp/broadcast.bin" 0x2020
datpatch "out/rsrc_raw/grp/broadcast.bin" "out/rsrc_raw/grp/broadcast.bin" "out/maps/broadcast.bin" 0x0000

datpatch "out/rsrc_raw/grp/windmtn.bin" "out/rsrc_raw/grp/windmtn.bin" "out/grp/windmtn.bin" 0x2020
datpatch "out/rsrc_raw/grp/windmtn.bin" "out/rsrc_raw/grp/windmtn.bin" "out/maps/windmtn.bin" 0x0000

datpatch "out/rsrc_raw/grp/ferriswheel.bin" "out/rsrc_raw/grp/ferriswheel.bin" "out/grp/ferriswheel.bin" 0x2020
datpatch "out/rsrc_raw/grp/ferriswheel.bin" "out/rsrc_raw/grp/ferriswheel.bin" "out/maps/ferriswheel.bin" 0x0000
spritebuild_pce "rsrc/grp/ferriswheel_sign.png" "rsrc/grp/ferriswheel_sign.txt" "rsrc_raw/pal/ferriswheel_spr.pal" "out/grp/ferriswheel_sign_grp.bin" "out/grp/ferriswheel_sign_spr.bin"
datpatch "out/rsrc_raw/grp/ferriswheel.bin" "out/rsrc_raw/grp/ferriswheel.bin" "out/grp/ferriswheel_sign_grp.bin" 0x7000

spriteundmp_pce "rsrc/grp/bathsign2.png" "out/rsrc_raw/grp/bathsign2.bin" -r 2 -p "rsrc_raw/pal/bathsign2_sign_line.pal"

spriteundmp_pce "rsrc/grp/diagram_ship.png" "out/rsrc_raw/grp/diagram_ship.bin" -r 4 -p "rsrc_raw/pal/diagram_spr.pal"
datpatch "out/rsrc_raw/grp/diagram.bin" "out/rsrc_raw/grp/diagram.bin" "out/grp/diagram.bin" 0x2020
datpatch "out/rsrc_raw/grp/diagram.bin" "out/rsrc_raw/grp/diagram.bin" "out/maps/diagram.bin" 0x0000
datpatch "out/rsrc_raw/grp/diagram.bin" "out/rsrc_raw/grp/diagram.bin" "out/rsrc_raw/grp/diagram_ship.bin" $((0xCC*0x80))

datpatch "out/rsrc_raw/grp/anderope_intro.bin" "out/rsrc_raw/grp/anderope_intro.bin" "out/grp/anderope_intro.bin" 0x2020
datpatch "out/rsrc_raw/grp/anderope_intro.bin" "out/rsrc_raw/grp/anderope_intro.bin" "out/maps/anderope_intro.bin" 0x0000

grpundmp_pce "rsrc/grp/elline_name.png" 16 "out/rsrc_raw/grp/elline_name.bin" -r 8 -p "rsrc_raw/pal/anderope_name_line.pal"

spriteundmp_pce "rsrc/grp/finisher.png" "out/rsrc_raw/grp/finisher.bin" -r 2 -p "rsrc_raw/pal/anderope_cards_line.pal"

spriteundmp_pce "rsrc/grp/battle_empty.png" "out/rsrc_raw/grp/battle_empty.bin" -r 2 -p "rsrc_raw/pal/battle_cards_line.pal"

spriteundmp_pce "rsrc/grp/spaceduck_label.png" "out/rsrc_raw/grp/spaceduck_label.bin" -r 2 -p "rsrc_raw/pal/spaceduck_label_line.pal"

# spriteundmp_pce "rsrc/grp/continued.png" "out/rsrc_raw/grp/continued_rawdmp.bin" -r 4 -p "rsrc_raw/pal/continued_line.pal"
# datpatch "out/rsrc_raw/grp/continued.bin" "out/rsrc_raw/grp/continued.bin" "out/rsrc_raw/grp/continued_rawdmp.bin" $((0xFC*0x80)) $((0x80*4)) $((0x80*1)) "out/rsrc_raw/grp/continued_rawdmp.bin" $((0xFC*0x80)) $((0x80*1))
spritelayout_pce "rsrc/grp/continued.png" "rsrc_raw/grp/continued.bin" "rsrc/grp/continued.txt" "out/grp/continued.bin" -p "rsrc_raw/pal/continued_line.pal"

#spriteundmp_pce "rsrc/grp/intro_sub1.png" "out/rsrc_raw/grp/intro_sub1.bin" -r 15 -p "rsrc_raw/pal/subtitles.pal"
spritebuild_pce "rsrc/grp/intro_sub1.png" "rsrc/grp/intro_sub1.txt" "rsrc_raw/pal/subtitles_full.pal" "out/grp/intro_sub1_grp.bin" "out/grp/intro_sub1_spr.bin"
datpatch "out/rsrc_raw/grp/intro_subgrp1.bin" "out/rsrc_raw/grp/intro_subgrp1.bin" "out/grp/intro_sub1_grp.bin" $((0x0+(0x19C*0x80)))
# trim unused patterns at end to ensure compressed result fits
#datsnip "out/rsrc_raw/grp/intro_subgrp1.bin" 0 $((0xE000-(0x15*0x80))) "out/rsrc_raw/grp/intro_subgrp1.bin"
datsnip "out/rsrc_raw/grp/intro_subgrp1.bin" 0 $((0xE000-(0x4*0x80))) "out/rsrc_raw/grp/intro_subgrp1.bin"
datpatch "out/rsrc_raw/grp/intro_subgrp1_def.bin" "out/rsrc_raw/grp/intro_subgrp1_def.bin" "out/grp/intro_sub1_spr.bin" 0x5E2
yuna2_cmp "out/rsrc_raw/grp/intro_subgrp1.bin" "out/rsrc_raw/grp/intro_subgrp1_cmp.bin"
yuna2_cmp "out/rsrc_raw/grp/intro_subgrp1_def.bin" "out/rsrc_raw/grp/intro_subgrp1_def_cmp.bin"

#spritebuild_pce "rsrc/grp/intro_sub2.png" "rsrc/grp/intro_sub2.txt" "rsrc_raw/pal/subtitles_full.pal" "out/grp/intro_sub2_grp.bin" "out/grp/intro_sub2_spr.bin"
spritebuild_pce "rsrc/grp/intro_sub2.png" "rsrc/grp/intro_sub2.txt" "rsrc_raw/pal/intro_sub2_spr.pal" "out/grp/intro_sub2_grp.bin" "out/grp/intro_sub2_spr.bin"
datpatch "out/rsrc_raw/grp/intro_subgrp2.bin" "out/rsrc_raw/grp/intro_subgrp2.bin" "out/grp/intro_sub2_grp.bin" $((0x0+(0xD8*0x80)))
# trim unused patterns at end to ensure compressed result fits
datsnip "out/rsrc_raw/grp/intro_subgrp2.bin" 0 $((0x8000-(0x4*0x80))) "out/rsrc_raw/grp/intro_subgrp2.bin"
datpatch "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/grp/intro_sub2_spr.bin" 0x2D1
datpatch "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/grp/intro_sub2_spr.bin" 0x3E5
datpatch "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/grp/intro_sub2_spr.bin" 0x4F9
yuna2_cmp "out/rsrc_raw/grp/intro_subgrp2.bin" "out/rsrc_raw/grp/intro_subgrp2_cmp.bin"
yuna2_cmp "out/rsrc_raw/grp/intro_subgrp2_def.bin" "out/rsrc_raw/grp/intro_subgrp2_def_cmp.bin"

yuna2_interface_vram_patch "out/rsrc_raw/grp/interface_vram_raw.bin" "out/rsrc_raw/grp/interface_vram_raw.bin"

spritebuild_pce "rsrc/grp/title_logo.png" "rsrc/grp/title_logo.txt" "rsrc_raw/pal/title_spr.pal" "out/grp/title_logo_grp.bin" "out/grp/title_logo_spr.bin"
datpatch "out/rsrc_raw/advgrp/TIT.GRP" "out/rsrc_raw/advgrp/TIT.GRP" "out/grp/title_logo_grp.bin" $((0x3F6+(0x50*0x80)))
datpatch "out/rsrc_raw/advgrp/TIT.GRP" "out/rsrc_raw/advgrp/TIT.GRP" "out/grp/title_logo_spr.bin" $((0x24C))

spritebuild_pce "rsrc/grp/title_subtitle.png" "rsrc/grp/title_subtitle.txt" "rsrc_raw/pal/title_spr.pal" "out/grp/title_subtitle_grp.bin" "out/grp/title_subtitle_spr.bin"
datpatch "out/rsrc_raw/advgrp/TIT.GRP" "out/rsrc_raw/advgrp/TIT.GRP" "out/grp/title_subtitle_grp.bin" $((0x3F6+(0xD8*0x80)))
#datpatch "out/rsrc_raw/advgrp/TIT.GRP" "out/rsrc_raw/advgrp/TIT.GRP" "out/grp/title_subtitle_spr.bin" $((0x24C))

spritebuild_pce "rsrc/grp/logo_eyecatch.png" "rsrc/grp/logo_eyecatch.txt" "rsrc_raw/pal/eyecatch_spr.pal" "out/grp/logo_eyecatch_grp.bin" "out/grp/logo_eyecatch_spr.bin"
spritebuild_pce "rsrc/grp/logo_eyecatch.png" "rsrc/grp/logo_eyecatch2.txt" "rsrc_raw/pal/eyecatch_spr.pal" "out/grp/logo_eyecatch2_grp.bin" "out/grp/logo_eyecatch2_spr.bin"

spritebuild_pce "rsrc/grp/tv.png" "rsrc/grp/tv.txt" "rsrc_raw/pal/tv_spr.pal" "out/grp/tv_grp.bin" "out/grp/tv_spr.bin"

spritebuild_pce "rsrc/grp/newschool.png" "rsrc/grp/newschool.txt" "rsrc_raw/pal/newschool_spr.pal" "out/grp/newschool_grp.bin" "out/grp/newschool_spr.bin"
#datpatch "out/rsrc_raw/grp/newschool.bin" "out/rsrc_raw/grp/newschool.bin" "out/grp/newschool_grp.bin" $((0x1900))

spritebuild_pce "rsrc/grp/gon.png" "rsrc/grp/gon.txt" "rsrc_raw/pal/gon_spr.pal" "out/grp/gon_grp.bin" "out/grp/gon_spr.bin"

# datsnip "out/pal/intro_suit_patch.pal" $((0x7*0x20)) 0x20 "out/pal/intro_suit_patch_line.pal"
# datsnip "out/pal/intro.pal" $((0x6*0x20)) 0x20 "out/pal/intro_line.pal"
# datsnip "out/pal/scene00_patch.pal" $((0x6*0x20)) 0x40 "out/pal/scene00_patch_line.pal"
# datsnip "out/pal/scene0B_patch.pal" $((0x7*0x20)) 0x20 "out/pal/scene0B_patch_line.pal"
# 
# #remapPaletteOverwrite "out/grp/karaoke.png" "out/grp/karaoke_remap.png"
# remapPaletteOverwrite "out/grp/karaoke.png" "out/grp/orig/karaoke.png"
# yuna_grpbuild "rsrc_raw/img/karaoke.bin" "out/grp/karaoke.png" "out/grp/karaoke.bin"
# datpatch "out/base/grp_889A.bin" "out/base/grp_889A.bin" "out/grp/karaoke.bin" 0xC942 0 0x218A
# 
# #remapPaletteOverwrite "out/grp/snap.png" "out/grp/snap_remap.png"
# remapPaletteOverwrite "out/grp/snap.png" "out/grp/orig/snap.png"
# yuna_grpbuild "rsrc_raw/img/snap.bin" "out/grp/snap.png" "out/grp/snap.bin"
# datpatch "out/base/grp_892A.bin" "out/base/grp_892A.bin" "out/grp/snap.bin" 0x64A1 0 0x218A
# 
# #remapPaletteOverwrite "rsrc/grp/noentry_map.png" "rsrc/grp/orig/noentry_map.png"
# remapPaletteOverwrite "out/grp/noentry.png" "out/grp/orig/noentry.png"
# yuna_grpbuild "rsrc_raw/img/noentry.bin" "out/grp/noentry.png" "out/grp/noentry.bin"
# datpatch "out/base/grp_8C8A.bin" "out/base/grp_8C8A.bin" "out/grp/noentry.bin" 0x64A1 0 0x218A
# datpatch "out/base/grp_8D62.bin" "out/base/grp_8D62.bin" "out/grp/noentry.bin" 0x4316 0 0x218A
# 
# spriteundmp_pce "rsrc/grp/flint_map.png" "out/grp/flint_map.bin" -p "rsrc_raw/pal/flint_map_line.pal" -r 1 -n 1
# 
# spriteundmp_pce "rsrc/grp/blackhole_txt.png" "out/grp/blackhole_txt.bin" -r 8 -n 24
# spriteundmp_pce "rsrc/grp/flint_txt.png" "out/grp/flint_txt.bin" -r 8 -n 16
# spriteundmp_pce "rsrc/grp/mariana_txt.png" "out/grp/mariana_txt.bin" -r 8 -n 16
# spriteundmp_pce "rsrc/grp/luries_txt.png" "out/grp/luries_txt.bin" -r 8 -n 16
# spriteundmp_pce "rsrc/grp/balmood_txt.png" "out/grp/balmood_txt.bin" -r 6 -n 12
# spriteundmp_pce "rsrc/grp/darknebula_txt.png" "out/grp/darknebula_txt.bin" -r 8 -n 16
# spriteundmp_pce "rsrc/grp/asteroid_txt.png" "out/grp/asteroid_txt.bin" -r 8 -n 24
# 
# spriteundmp_pce "rsrc/grp/title_sublogo_en.png" "out/grp/title_sublogo_en.bin" -r 7 -n 7
# 
# bigspriteundmp_pce "rsrc/grp/title_logo.png" "out/grp/title_logo.bin" -p "rsrc_raw/pal/title_logo_yellow.pal" -r 4 -n 8 -w 2 -h 4
# 
# spritelayout_pce "rsrc/grp/poka.png" "rsrc_raw/grp/poka.bin" "rsrc_raw/layout/poka.txt" "out/grp/poka.bin" -p "rsrc_raw/pal/poka.pal"
# 
# spritelayout_pce "rsrc/grp/temple_doka.png" "rsrc_raw/grp/temple_doka.bin" "rsrc_raw/layout/temple_doka.txt" "out/grp/temple_doka.bin" -p "rsrc_raw/pal/temple_doka.pal"
# 
# grpundmp_pce "rsrc/grp/hud_gemy.png" 35 "out/grp/hud_gemy.bin" -r 5
# 
# yuna_credits "rsrc_raw/grp/credits_grp.bin" "out/grp/credits_grp.bin"

# echo "*******************************************************************************"
# echo "Building script..."
# echo "*******************************************************************************"
# 
# mkdir -p out/script
# mkdir -p out/scripttxt
# mkdir -p out/scriptwrap
# #mkdir -p out/script/include
# 
# importscript "script/script.csv"
# 
# scriptwrap "out/scripttxt/battle0.txt" "out/scriptwrap/battle0.txt"
# scriptwrap "out/scripttxt/battle2.txt" "out/scriptwrap/battle2.txt"
# scriptwrap "out/scripttxt/battle3.txt" "out/scriptwrap/battle3.txt"
# scriptwrap "out/scripttxt/battle4.txt" "out/scriptwrap/battle4.txt"
# scriptwrap "out/scripttxt/battle_enemy.txt" "out/scriptwrap/battle_enemy.txt"
# scriptwrap "out/scripttxt/battle_yuna.txt" "out/scriptwrap/battle_yuna.txt"
# scriptwrap "out/scripttxt/postbat.txt" "out/scriptwrap/postbat.txt" "table/yuna_scenes_en.tbl" "out/font/fontwidth_scene.bin"
# scriptwrap "out/scripttxt/scene19.txt" "out/scriptwrap/scene19.txt"
# scriptwrap "out/scripttxt/scene1C.txt" "out/scriptwrap/scene1C.txt" "table/yuna_en.tbl" "out/font/fontwidth_narrow.bin"
# scriptwrap "out/scripttxt/script.txt" "out/scriptwrap/script.txt"
# scriptwrap "out/scripttxt/system_adv.txt" "out/scriptwrap/system_adv.txt"
# scriptwrap "out/scripttxt/system_boot.txt" "out/scriptwrap/system_boot.txt"
# scriptwrap "out/scripttxt/system_load.txt" "out/scriptwrap/system_load.txt"
# scriptwrap "out/scripttxt/system_title.txt" "out/scriptwrap/system_title.txt"
# 
# scriptwrap "out/scripttxt/scenes.txt" "out/scriptwrap/scenes.txt" "table/yuna_scenes_en.tbl" "out/font/fontwidth_scene.bin"
# scriptwrap "out/scripttxt/subintro.txt" "out/scriptwrap/subintro.txt" "table/yuna_scenes_en.tbl" "out/font/fontwidth_scene.bin"
# scriptwrap "out/scripttxt/title.txt" "out/scriptwrap/title.txt" "table/yuna_scenes_en.tbl" "out/font/fontwidth_scene.bin"
# 
# #scriptbuild "script/" "out/script/"
# scriptbuild "out/scriptwrap/" "out/script/"

echo "*******************************************************************************"
echo "Building script..."
echo "*******************************************************************************"

mkdir -p out/scripttxt
mkdir -p out/scriptwrap
mkdir -p out/script

yuna2_scriptimport

#for file in out/scripttxt/*.txt; do
#  name=$(basename $file)
#  yuna2_scriptwrap "$file" "out/scriptwrap/$name"
#done

yuna2_scriptwrap "out/scripttxt/spec_main.txt" "out/scriptwrap/spec_main.txt"
yuna2_scriptwrap "out/scripttxt/spec_battle.txt" "out/scriptwrap/spec_battle.txt"
yuna2_scriptwrap "out/scripttxt/spec_scene.txt" "out/scriptwrap/spec_scene.txt" "table/yuna2_scenes_en.tbl" "out/font/fontwidth_scene.bin" 0x50

# # ugh
# yuna2_scriptwrap "out/scripttxt/spec_end.txt" "out/scriptwrap/spec_end.txt" "table/pom_end.tbl"
# yuna2_scriptwrap "out/scripttxt/spec_endnew.txt" "out/scriptwrap/spec_endnew.txt" "table/pom_end.tbl"

yuna2_scriptbuild "out/scriptwrap/" "out/script/"

echo "*******************************************************************************"
echo "Building prerendered subtitles..."
echo "*******************************************************************************"

#cp -r rsrc_raw/pal out
#cp -r rsrc/grp out

subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/starbowl0.bin" "table/yuna_scenes_en.tbl" "out/grp/starbowl0.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/starbowl1.bin" "table/yuna_scenes_en.tbl" "out/grp/starbowl1.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/starbowl2.bin" "table/yuna_scenes_en.tbl" "out/grp/starbowl2.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/starbowl3.bin" "table/yuna_scenes_en.tbl" "out/grp/starbowl3.png"

subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/darkqueen0.bin" "table/yuna_scenes_en.tbl" "out/grp/darkqueen0.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/darkqueen1.bin" "table/yuna_scenes_en.tbl" "out/grp/darkqueen1.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/darkqueen2.bin" "table/yuna_scenes_en.tbl" "out/grp/darkqueen2.png"
subrender "font/scene/" "font/scene/table.tbl" "out/script/strings/main/darkqueen3.bin" "table/yuna_scenes_en.tbl" "out/grp/darkqueen3.png"

spriteundmp_pce "out/grp/starbowl0.png" "out/grp/starbowl0.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/starbowl1.png" "out/grp/starbowl1.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/starbowl2.png" "out/grp/starbowl2.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/starbowl3.png" "out/grp/starbowl3.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"

spriteundmp_pce "out/grp/darkqueen0.png" "out/grp/darkqueen0.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/darkqueen1.png" "out/grp/darkqueen1.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/darkqueen2.png" "out/grp/darkqueen2.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"
spriteundmp_pce "out/grp/darkqueen3.png" "out/grp/darkqueen3.bin" -r 16 -n 32 -p "out/rsrc_raw/pal/subtitles.pal"

echo "********************************************************************************"
echo "Applying ASM patches..."
echo "********************************************************************************"

function applyAsmPatch() {
  infile=$1
  asmname=$2
#  linkfile=$3
  infile_base=$(basename $infile)
  infile_base_noext=$(basename $infile .bin)
  
  linkfile=${asmname}_link
  
  echo "******************************"
  echo "patching: $asmname"
  echo "******************************"
  
  # generate linkfile
  printf "[objects]\n${asmname}.o" >"asm/$linkfile"
  
  cp "$infile" "asm/$infile_base"
  
  cd asm
    # apply hacks
    ../$WLADX -I ".." -o "$asmname.o" "$asmname.s"
    ../$WLALINK -v -S "$linkfile" "${infile_base}_build"
  cd $BASE_PWD
  
  mv -f "asm/${infile_base}_build" "out/base/${infile_base}"
  rm "asm/${infile_base}"
  
  rm asm/*.o
  
  # delete linkfile
  rm "asm/$linkfile"
}

function applyAsmPatchScene() {
  infile=$1
  asmname=$2
  infile_base=$(basename $infile)
  
  applyAsmPatch "$1" "$2"
  mv "out/base/${infile_base}" "out/base/$asmname.bin"
}

# we're expanding this file, and wla-dx won't accept .background commands
# if the filesize doesn't match the rom map, so we have to pad it outself
datpad "out/base/scene_main_32.bin" 0x6000

applyAsmPatch "out/base/adv_2.bin" "adv"
applyAsmPatch "out/base/scene_main_32.bin" "scene_main"
applyAsmPatch "out/base/starbowl_CA.bin" "starbowl"
applyAsmPatch "out/base/battle_10A.bin" "battle"

applyAsmPatchScene "base/scene_dummy.bin" "scene01"
applyAsmPatchScene "base/scene_dummy.bin" "scene02"
applyAsmPatchScene "base/scene_dummy.bin" "scene03"
applyAsmPatchScene "base/scene_dummy.bin" "scene04"
applyAsmPatchScene "base/scene_dummy.bin" "scene05"
applyAsmPatchScene "base/scene_dummy.bin" "scene06"

# applyAsmPatch "out/base/adv_87EA.bin" "adv"
# applyAsmPatch "out/base/battle0_B1BA.bin" "battle0"
# applyAsmPatch "out/base/battle2_B1E2.bin" "battle2"
# applyAsmPatch "out/base/battle3_B1F6.bin" "battle3"
# applyAsmPatch "out/base/battle4_B20A.bin" "battle4"
# applyAsmPatch "out/base/boot_2E2.bin" "boot"
# applyAsmPatch "out/base/bootloader2_A97C.bin" "bootloader2"
# applyAsmPatch "out/base/bootloader4_A97E.bin" "bootloader4"
# applyAsmPatch "out/base/bootloader5_A97F.bin" "bootloader5"
# applyAsmPatch "out/base/bootloader7_A981.bin" "bootloader7"
# applyAsmPatch "out/base/bootloader8_A982.bin" "bootloader8"
# applyAsmPatch "out/base/load_42.bin" "load"
# applyAsmPatch "out/base/subintro_2.bin" "subintro"
# applyAsmPatch "out/base/title_202.bin" "title"
# applyAsmPatch "out/base/title_spritedef.bin" "title_spritedef"
# 
# for i in `seq 0 28`; do
#   numstr=$(printf "%02X" $i)
# #  echo $numstr
#   scenebase="scene${numstr}"
#   scenefile="out/base/$scenebase.bin"
#   
#   # build scene if its asm file exists
#   if [ -f "asm/$scenebase.s" ]; then
#     applyAsmPatch "$scenefile" "$scenebase"
#   fi;
#   
# done;
# 
# for i in `seq 0 16`; do
#   numstr=$(printf "%02X" $i)
# #  echo $numstr
#   scenebase="postbat${numstr}"
#   scenefile="out/base/$scenebase.bin"
#   
#   # build scene if its asm file exists
#   if [ -f "asm/$scenebase.s" ]; then
#     applyAsmPatch "$scenefile" "$scenebase"
#   fi;
#   
# done;
# 
# # HACK: get palette chunk offset from sprite definition file so we can
# # patch it to the separate data block where it is stored
# datsnip "out/base/title_spritedef.bin" 0x1FFE 0x2 "out/grp/title_spritedef_paloffset.bin"

# DEBUG: use test menu instead of normal debug scene select menu
#datpatch "out/script/text_all_2E7A.bin" "out/script/text_all_2E7A.bin" "out/rsrc_raw/misc/test_menu_patch.bin" 0x2A

echo "********************************************************************************"
echo "Patching disc..."
echo "********************************************************************************"

# # patch scene files to scene pack
# for i in `seq 0 28`; do
#   numstr=$(printf "%02X" $i)
#   scenebase="scene${numstr}"
#   scenefile="out/base/$scenebase.bin"
#   
#   datpatch "out/base/scenes_all_E23A.bin" "out/base/scenes_all_E23A.bin" "$scenefile" $(($i*0xA000)) 0 0xA000
# done;
# 
# # patch postbat files to postbat pack
# for i in `seq 0 16`; do
#   numstr=$(printf "%02X" $i)
#   scenebase="postbat${numstr}"
#   scenefile="out/base/$scenebase.bin"
#   
#   datpatch "out/base/postbat_all_B4DA.bin" "out/base/postbat_all_B4DA.bin" "$scenefile" $(($i*0xA000)) 0 0xA000
# done;

yuna2patch "$OUTROM" "$OUTROM"

echo "*******************************************************************************"
echo "Success!"
echo "Output file:" $OUTROM
echo "*******************************************************************************"
