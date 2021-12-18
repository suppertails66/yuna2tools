versionnum="v1.0"

# fabt/faat have identical data tracks; only audio differs
#filename_fabt="patch/auto_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-fabt].xdelta"
#filename_faat="patch/auto_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-faat].xdelta"
filename_iso="patch/auto_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-iso].xdelta"
filenameredump_fabt="patch/redump_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-fabt] Redump.xdelta"
filenameredump_faat="patch/redump_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-faat] Redump.xdelta"
filenamesplitbin_fabt="patch/splitbin_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-fabt] SplitBin.xdelta"
filenamesplitbin_faat="patch/splitbin_patch/Ginga Ojousama Densetsu Yuna 2 EN [${versionnum}-faat] SplitBin.xdelta"

mkdir -p patch
mkdir -p patch/auto_patch
mkdir -p patch/redump_patch
mkdir -p patch/splitbin_patch


./build.sh

rm -f "$filename"
#xdelta3 -e -f -B 202635264 -s "patch/exclude/yuna2_fabt_02.iso" "yuna2_02_build.iso" "$filename_fabt"
#xdelta3 -e -f -B 202635264 -s "patch/exclude/yuna2_faat_02.iso" "yuna2_02_build.iso" "$filename_faat"
xdelta3 -e -f -B 202635264 -s "patch/exclude/yuna2_fabt_02.iso" "yuna2_02_build.iso" "$filename_iso"

rm -f "$filenameredump"
../discaster/discaster yuna2.dsc
xdelta3 -e -f -B 739602864 -s "patch/exclude/yuna2_fabt.bin" "yuna2_build.bin" "$filenameredump_fabt"
xdelta3 -e -f -B 739602864 -s "patch/exclude/yuna2_faat.bin" "yuna2_build.bin" "$filenameredump_faat"
