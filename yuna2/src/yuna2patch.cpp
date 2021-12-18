#include "pce/PcePalette.h"
#include "yuna/YunaScriptReader.h"
#include "yuna/YunaLineWrapper.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TFileManip.h"
#include <cctype>
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Pce;

const static int sectorSize = 0x800;

void patchFile(TBufStream& ofs,
               std::string filename,
               int offset,
               int sizeLimit = -1) {
  if (!TFileManip::fileExists(filename)) {
    throw TGenericException(T_SRCANDLINE,
                            "patchFile()",
                            std::string("File does not exist: ")
                              + filename);
  }
  
  TBufStream ifs;
  ifs.open(filename.c_str());
  
  if (sizeLimit == -1) sizeLimit = ifs.size();
  
  ofs.seek(offset);
  ofs.writeFrom(ifs, sizeLimit);
}

void patchFileBySector(TBufStream& ofs,
               std::string filename,
               int sectorNum,
               int sizeLimit = -1) {
  patchFile(ofs, filename, sectorNum * sectorSize, sizeLimit);
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Yuna 2 ISO patcher" << endl;
    cout << "Usage: " << argv[0]
      << " <infile> <outfile>" << endl;
  }
  
  string infile(argv[1]);
  string outfile(argv[2]);

  // patching modified files to the ISO one by one resulted in
  // ridiculous disk I/O, so i've turned the original shell script
  // into this dedicated program to speed it up
  
  TBufStream ofs;
  ofs.open(infile.c_str());
  
  patchFileBySector(
    ofs, "out/base/adv_2.bin", 0x2, 0x6000);
  // overwrite unneeded debug executable with scene subtitle data
  patchFileBySector(
    ofs, "out/base/scene01.bin", 0x22 + (2 * 0), 0x1000);
  patchFileBySector(
    ofs, "out/base/scene02.bin", 0x22 + (2 * 1), 0x1000);
  patchFileBySector(
    ofs, "out/base/scene03.bin", 0x22 + (2 * 2), 0x1000);
  patchFileBySector(
    ofs, "out/base/scene04.bin", 0x22 + (2 * 3), 0x1000);
  patchFileBySector(
    ofs, "out/base/scene05.bin", 0x22 + (2 * 4), 0x1000);
  patchFileBySector(
    ofs, "out/base/scene06.bin", 0x22 + (2 * 5), 0x1000);
  // TODO: remove this, it won't be needed
//  patchFileBySector(
//    ofs, "out/base/scene_main_32.bin", 0x32, 0x2800);
  // scene_main has been expanded for this hack;
  // the expanded version overwrites the old, broken adv executable
  patchFileBySector(
    ofs, "out/base/scene_main_32.bin", 0x2E1A, 0x6000);
  patchFileBySector(
    ofs, "out/base/starbowl_CA.bin", 0xCA, 0x3800);
  patchFileBySector(
    ofs, "out/base/battle_10A.bin", 0x10A, 0x5000);
  patchFileBySector(
    ofs, "out/script/battleblock_all_206.bin", 0x206, 0x2A4000);
  patchFileBySector(
    ofs, "out/script/text_all_2E7A.bin", 0x2E7A, 0xC8000);
  
  //=====================
  // star bowl subtitles
  //=====================
  
  // overwrite script module 8, which is a blank filler module
  patchFileBySector(ofs, "out/grp/starbowl0.bin",
            0x2EBA + (0 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/starbowl1.bin",
            0x2EBA + (1 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/starbowl2.bin",
            0x2EBA + (2 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/starbowl3.bin",
            0x2EBA + (3 * 2), 0x1000);
  
  //=====================
  // dark queen subtitles
  //=====================
  
  // overwrite script module 7, which is a blank filler module
  patchFileBySector(ofs, "out/grp/darkqueen0.bin",
            0x2EB2 + (0 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/darkqueen1.bin",
            0x2EB2 + (1 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/darkqueen2.bin",
            0x2EB2 + (2 * 2), 0x1000);
  patchFileBySector(ofs, "out/grp/darkqueen3.bin",
            0x2EB2 + (3 * 2), 0x1000);
  
  //=====================
  // graphics
  //=====================
  
  patchFileBySector(ofs, "out/rsrc_raw/grp/carderror.bin",
            0x1818A);
  patchFile(ofs, "out/rsrc_raw/grp/logo_ch5.bin",
            0x98B5AD6);
  patchFile(ofs, "out/rsrc_raw/grp/concert.bin",
            0x30D625A);
    // ?
    patchFile(ofs, "out/rsrc_raw/grp/concert.bin",
              0x92E8228);
  patchFile(ofs, "out/rsrc_raw/grp/quiz.bin",
            0x4DB4286);
    // ?
    patchFile(ofs, "out/rsrc_raw/grp/quiz.bin",
              0x5DB4286);
  patchFile(ofs, "out/rsrc_raw/grp/ice.bin",
            0x4D4FA28);
    patchFile(ofs, "out/rsrc_raw/grp/ice.bin",
              0x5D4FA28);
  patchFile(ofs, "out/rsrc_raw/grp/ice2.bin",
            0x4D5CA28);
    patchFile(ofs, "out/rsrc_raw/grp/ice2.bin",
              0x5D5CA28);
  patchFile(ofs, "out/rsrc_raw/grp/ice3.bin",
            0x4AE2228);
    patchFile(ofs, "out/rsrc_raw/grp/ice3.bin",
              0x5AE2228);
  patchFile(ofs, "out/rsrc_raw/grp/ice4.bin",
            0x4AEAA28);
    patchFile(ofs, "out/rsrc_raw/grp/ice4.bin",
              0x5AEAA28);
  patchFile(ofs, "out/rsrc_raw/grp/ice5.bin",
            0x4D76421);
    patchFile(ofs, "out/rsrc_raw/grp/ice5.bin",
              0x5D76421);
  patchFile(ofs, "out/rsrc_raw/grp/bathsign.bin",
            0x7978AE5);
    patchFile(ofs, "out/rsrc_raw/grp/bathsign.bin",
              0x7996AE5);
  patchFile(ofs, "out/rsrc_raw/grp/bathsign2.bin",
            0x7ACED30);
  patchFile(ofs, "out/rsrc_raw/grp/hatopoppo.bin",
            0x31A3228);
    patchFile(ofs, "out/rsrc_raw/grp/hatopoppo.bin",
              0x3954A28);
  
  patchFile(ofs, "out/rsrc_raw/grp/battle_empty.bin",
            0x91400);
  
  patchFile(ofs, "out/rsrc_raw/grp/elline_name.bin",
            0x9EA00);
    patchFile(ofs, "out/rsrc_raw/grp/elline_name.bin",
              0xAEA00);
    patchFile(ofs, "out/rsrc_raw/grp/elline_name.bin",
              0xBEA00);
  
  patchFile(ofs, "out/rsrc_raw/grp/finisher.bin",
            0xA1400);
    patchFile(ofs, "out/rsrc_raw/grp/finisher.bin",
              0xB1400);
    patchFile(ofs, "out/rsrc_raw/grp/finisher.bin",
              0xC1400);
  
  patchFile(ofs, "out/rsrc_raw/grp/anderope_intro.bin",
            0x9A6646E);
  
  patchFile(ofs, "out/rsrc_raw/grp/spaceduck_label.bin",
            0x55400);
  
  //=====================
  // adv interface vram
  //=====================
  
//  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
//            0x18531C0 - 0x19C0);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x1851800);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x3851800);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x5851800);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x7851800);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x9051800);
  patchFile(ofs, "out/rsrc_raw/grp/interface_vram_raw.bin",
            0x9851800);
  
  //=====================
  // adv graphics
  //=====================
  
//  patchFileBySector(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
//            0x30C4);
  // title screen (i think only the first one is used but w/e)
  patchFile(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
            0x1862000);
  patchFile(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
            0x3862000);
  patchFile(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
            0x5862000);
  patchFile(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
            0x7862000);
  patchFile(ofs, "out/rsrc_raw/advgrp/TIT.GRP",
            0x9862000);
  
  patchFile(ofs, "out/grp/tv_grp.bin",
            0x18E5AC5);
    patchFile(ofs, "out/grp/tv_grp.bin",
              0x30D3DC4);
    patchFile(ofs, "out/grp/tv_grp.bin",
              0x90E5AC5);
  patchFile(ofs, "out/grp/tv_spr.bin",
            0x18E1A2A);
    patchFile(ofs, "out/grp/tv_spr.bin",
              0x30CFD29);
    patchFile(ofs, "out/grp/tv_spr.bin",
              0x90E1A3B);
  
  patchFile(ofs, "out/grp/newschool_grp.bin",
            0x1A3232B+0x1900);
    patchFile(ofs, "out/grp/newschool_grp.bin",
              0x923232B+0x1900);
//  patchFile(ofs, "out/grp/newschool_spr.bin",
//            0x1A36605);
//    patchFile(ofs, "out/grp/newschool_spr.bin",
//              0x9236605);
  patchFile(ofs, "out/grp/newschool_spr.bin",
            0x1A366A6);
    patchFile(ofs, "out/grp/newschool_spr.bin",
              0x92366A6);
  
  patchFile(ofs, "out/grp/gon_grp.bin",
            0x78BFA9D+0xC00);
    patchFile(ofs, "out/grp/gon_grp.bin",
              0x78F4A99+0xC00);
  patchFile(ofs, "out/grp/gon_spr.bin",
            0x78C3AE2);
    patchFile(ofs, "out/grp/gon_spr.bin",
              0x78F8ADE);
  
  patchFile(ofs, "out/rsrc_raw/grp/doka.bin",
            0x1ACF2A0);
    patchFile(ofs, "out/rsrc_raw/grp/doka.bin",
              0x92CF2A0);
  
  patchFile(ofs, "out/rsrc_raw/grp/broadcast.bin",
            0x1AD9B36);
    patchFile(ofs, "out/rsrc_raw/grp/broadcast.bin",
              0x92D9B36);
  
  patchFile(ofs, "out/grp/continued.bin",
            0x1C0D623);
    patchFile(ofs, "out/grp/continued.bin",
              0x940D623);
  
  patchFile(ofs, "out/rsrc_raw/grp/diagram.bin",
            0x1D74A80);
    patchFile(ofs, "out/rsrc_raw/grp/diagram.bin",
              0x9574A5B);
  
  patchFile(ofs, "out/rsrc_raw/grp/windmtn.bin",
            0x4DDFA28);
    patchFile(ofs, "out/rsrc_raw/grp/windmtn.bin",
              0x5DDFA28);
    patchFile(ofs, "out/rsrc_raw/grp/windmtn.bin",
              0x72CDC50);
  
  patchFile(ofs, "out/rsrc_raw/grp/ferriswheel.bin",
            0x49ABA28);
    patchFile(ofs, "out/rsrc_raw/grp/ferriswheel.bin",
              0x59ABA28);
  
  //=====================
  // intro sub overlays
  //=====================
  
  patchFile(ofs, "out/rsrc_raw/grp/intro_subgrp1_cmp.bin",
            0x40050C);
  patchFile(ofs, "out/rsrc_raw/grp/intro_subgrp1_def_cmp.bin",
            0x3FFCCD);
  
  patchFile(ofs, "out/rsrc_raw/grp/intro_subgrp2_cmp.bin",
            0x429F66);
  patchFile(ofs, "out/rsrc_raw/grp/intro_subgrp2_def_cmp.bin",
            0x429C48);
  
  //=====================
  // eyecatches
  //=====================
  
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x18C4353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x38C2353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x496D353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x58B3353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x5DDEE25);
  // ch. 3 special eyecatch 1 (leaving ice planet)
  patchFile(ofs, "out/grp/logo_eyecatch2_grp.bin",
            0x72FC789 - 0x600);
  // ch. 3 special eyecatch 2 (after space duck)
//  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
//            0x7303789);
  patchFile(ofs, "out/grp/logo_eyecatch2_grp.bin",
            0x72FDF89 + (0x2900 * 2));
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x78B3353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x7A4DB53);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x8846B53);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x9C66353);
  patchFile(ofs, "out/grp/logo_eyecatch_grp.bin",
            0x9E19353);
  
  //=====================
  // extra stuff
  //=====================
  
  // scene graphics that have had blank area trimmed from the end
  // to reduce vram usage when needed for subtitles
  patchFile(ofs, "out/rsrc_raw/grp/scene00_biggrp1.bin",
            0x3BBF91);
//  patchFile(ofs, "out/rsrc_raw/grp/scene05_biggrp1.bin",
//            0x5CF875);
  patchFile(ofs, "out/rsrc_raw/grp/intro_biggrp1.bin",
            0x445DBF);
  
  // this overwrites a non-visible part of the BAT in the system card
  // version error graphic
  patchFileBySector(
    ofs, "out/rsrc_raw/grp/scene00_patch1.bin", 0x1818C, 0x1000);
  
  // test debug things
  // this is an actual debug menu, albeit a minimal one that doesn't
  // do anything useful i haven't already implemented myself
//  ofs.seek(0x800);
//  ofs.writeInt(0x22, 3, EndiannessTypes::big, SignednessTypes::nosign);
  // this looks like an earlier version of the adv executable.
  // apparently, the resources it needs aren't on the disc and it ends up
  // crashing.
//  ofs.seek(0x800);
//  ofs.writeInt(0x2E1A, 3, EndiannessTypes::big, SignednessTypes::nosign);
  
  // 0x8C96
/*  patchFileBySector(
    ofs, "out/base/subintro_2.bin", 0x2, 0xA000);
  patchFileBySector(
    ofs, "out/base/load_42.bin", 0x42, 0xA000);
  patchFileBySector(
    ofs, "out/base/title_202.bin", 0x202, 0xA000);
//  patchFileBySector(
//    ofs, "out/base/boot_2E2.bin", 0x2E2, 0x4400);
  patchFileBySector(
    ofs, "out/base/boot_2E2.bin", 0x2E2, 0xA000);
  patchFileBySector(
    ofs, "out/script/script.bin", 0x85EA, 0x88000);
  patchFileBySector(
    ofs, "out/base/adv_87EA.bin", 0x87EA, 0x8000);
  patchFileBySector(
    ofs, "out/base/grp_889A.bin", 0x889A, 0x24000);
  patchFileBySector(
    ofs, "out/base/grp_892A.bin", 0x892A, 0x24000);
  patchFileBySector(
    ofs, "out/base/grp_8C8A.bin", 0x8C8A, 0x24000);
  patchFileBySector(
    ofs, "out/base/grp_8D62.bin", 0x8D62, 0x24000);
  patchFileBySector(
    ofs, "out/base/bootloader2_A97C.bin", 0xA97C, 0x800);
  patchFileBySector(
    ofs, "out/base/bootloader4_A97E.bin", 0xA97E, 0x800);
  patchFileBySector(
    ofs, "out/base/bootloader5_A97F.bin", 0xA97F, 0x800);
  patchFileBySector(
    ofs, "out/base/bootloader7_A981.bin", 0xA981, 0x800);
  patchFileBySector(
    ofs, "out/base/bootloader8_A982.bin", 0xA982, 0x800);
  patchFileBySector(
    ofs, "out/base/battle0_B1BA.bin", 0xB1BA, 0xA000);
  patchFileBySector(
    ofs, "out/base/battle2_B1E2.bin", 0xB1E2, 0xA000);
  patchFileBySector(
    ofs, "out/base/battle3_B1F6.bin", 0xB1F6, 0xA000);
  patchFileBySector(
    ofs, "out/base/battle4_B20A.bin", 0xB20A, 0xA000);
  patchFileBySector(
    ofs, "out/base/battle_yuna_all_B3BA.bin", 0xB3BA, 0x14000);
  patchFileBySector(
    ofs, "out/base/battle_enemy_all_B3FA.bin", 0xB3FA, 0x8000);
  patchFileBySector(
    ofs, "out/base/battle_yuna_stats_B43A.bin", 0xB43A, 0x9800);
  patchFileBySector(
    ofs, "out/base/postbat_all_B4DA.bin", 0xB4DA, 0xAA000);
  patchFileBySector(
    ofs, "out/base/scenes_all_E23A.bin", 0xE23A, 0x122000);
  
  // minor one-off graphics and things
  patchFile(
    ofs, "out/grp/flint_map.bin", 0x4DBF19C, 0x80);
  patchFile(
    ofs, "out/grp/blackhole_txt.bin", 0x6366F90, 0xC00);
  // duplicated over and over again for no reason and i don't know
  // which one is actually used.
  // unless one of these is for some other cutscene that uses カ
  // as a sprite overlay, which is very probable
  patchFile(
    ofs, "out/grp/flint_txt.bin", 0x41770B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x41D70B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x4261A90, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x42970B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x5D690B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x5D690B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x5DBF0B0, 0x800);
    patchFile(
      ofs, "out/grp/flint_txt.bin", 0x62A50B0, 0x800);
  patchFile(
    ofs, "out/grp/mariana_txt.bin", 0x41A3050, 0x800);
    patchFile(
      ofs, "out/grp/mariana_txt.bin", 0x62D1050, 0x800);
  patchFile(
    ofs, "out/grp/luries_txt.bin", 0x63050B0, 0x800);
  patchFile(
    ofs, "out/grp/balmood_txt.bin", 0x63340B0, 0x800);
  patchFile(
    ofs, "out/grp/darknebula_txt.bin", 0x638FA90, 0x800);
  patchFile(
    ofs, "out/grp/asteroid_txt.bin", 0x63C50B0, 0xC00);
  patchFile(
    ofs, "out/grp/poka.bin", 0x478E991, 0x2000);
  patchFile(
    ofs, "out/grp/temple_doka.bin", 0x4970812, 0x1000);
  patchFile(
    ofs, "out/grp/credits_grp.bin", 0x698D000, 0x28000);
  patchFile(
    ofs, "out/base/title_spritedef.bin", 0x116D12, 0x2000);
    patchFile(
      ofs, "out/base/title_spritedef.bin", 0x123C08, 0x2000);
  patchFile(
    ofs, "out/grp/title_spritedef_paloffset.bin", 0x11410E, 2);
  // ?
    patchFile(
      ofs, "out/grp/title_spritedef_paloffset.bin", 0x121004, 2);
  patchFile(
    ofs, "out/grp/title_sublogo_en.bin", 0x115112, 0x380);
    patchFile(
      ofs, "out/grp/title_sublogo_en.bin", 0x122008, 0x380);
  patchFile(
    ofs, "out/grp/hud_gemy.bin", 0x5408240);
  // ?
    patchFile(
      ofs, "out/grp/hud_gemy.bin", 0x5415000);
    patchFile(
      ofs, "out/grp/hud_gemy.bin", 0x5417000);
    patchFile(
      ofs, "out/grp/hud_gemy.bin", 0x5419000);
    patchFile(
      ofs, "out/grp/hud_gemy.bin", 0x541B000);
    patchFile(
      ofs, "out/grp/hud_gemy.bin", 0x541D000); */
  
  ofs.save(outfile.c_str());
  
  return 0;
}

