#include "yuna2/Yuna2ScriptReader.h"
#include "yuna2/Yuna2LineWrapper.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TPngConversion.h"
#include "util/TFreeSpace.h"
#include <cctype>
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Pce;

const static int textBlockBaseSector = 0x2E7A;
const static int textBlockSize = 0x4000;
const static int numTextBlocks = 50;
const static int battleBlockSize = 0x1A000;
const static int numBattleBlocks = 26;
const static int sectorSize = 0x800;

const static int battleBlockIndexNumEntries = 0x40;
// yes, there's one extra byte here for some unknown reason
const static int battleBlockIndexSize = 0x81;

//const static int textCharsStart = 0x10;
//const static int textCharsEnd = 0x80;
const static int textCharsStart = 0x10;
const static int textCharsEnd = textCharsStart + 0x70;
const static int textEncodingMax = 0x100;
const static int maxDictionarySymbols = textEncodingMax - textCharsEnd;

//const static unsigned int mainExeBaseAddr = 0x80010000;
//const static int mainExeHeaderSize = 0x800;

//const static unsigned int mapDataOffsetTableAddr = 0x8012335C;
//const static unsigned int numMaps = 0x46;

// have to account for offset of exe from base
//const static int creditsFreeStrSpaceStart = 0x100000 - 0x10000;
//const static int creditsFreeStrSpaceEnd = 0x101000 - 0x10000;



TThingyTable table;
TThingyTable tableScene;

string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
}

std::string getNumStr(int num) {
  std::string str = TStringConversion::intToString(num);
  while (str.size() < 2) str = string("0") + str;
  return str;
}

std::string getHexByteNumStr(int num) {
  std::string str = TStringConversion::intToString(num,
    TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  return string("$") + str;
}

std::string getHexWordNumStr(int num) {
  std::string str = TStringConversion::intToString(num,
    TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 4) str = string("0") + str;
  return string("$") + str;
}
                      

void binToDcb(TStream& ifs, std::ostream& ofs) {
  int constsPerLine = 16;
  
  while (true) {
    if (ifs.eof()) break;
    
    ofs << "  .db ";
    
    for (int i = 0; i < constsPerLine; i++) {
      if (ifs.eof()) break;
      
      TByte next = ifs.get();
      ofs << as2bHexPrefix(next);
      if (!ifs.eof() && (i != constsPerLine - 1)) ofs << ",";
    }
    
    ofs << std::endl;
  }
}




typedef std::map<std::string, int> UseCountTable;
//typedef std::map<std::string, double> EfficiencyTable;
typedef std::map<double, std::string> EfficiencyTable;

bool isCompressible(std::string& str) {
  for (int i = 0; i < str.size(); i++) {
    if ((unsigned char)str[i] < textCharsStart) return false;
    if ((unsigned char)str[i] >= textCharsEnd) return false;
  }
  
  return true;
}

void addStringToUseCountTable(std::string& input,
                        UseCountTable& useCountTable,
                        int minLength, int maxLength) {
  int total = input.size() - minLength;
  if (total <= 0) return;
  
  for (int i = 0; i < total; ) {
    int basePos = i;
    for (int j = minLength; j < maxLength; j++) {
      int length = j;
      if (basePos + length >= input.size()) break;
      
      std::string str = input.substr(basePos, length);
      
      // HACK: avoid analyzing parameters of control sequences
      // the ops themselves are already ignored in the isCompressible check;
      // we just check when an op enters into the first byte of the string,
      // then advance the check position so the parameter byte will
      // never be considered
      if ((str.size() > 0) && ((unsigned char)str[0] < textCharsStart)) {
        unsigned char value = str[0];
        if ((value == 0x02) // "L"
            || (value == 0x05) // "P"
            || (value == 0x06)) { // "W"
          // skip the argument byte
          i += 1;
        }
        break;
      }
      
      if (!isCompressible(str)) break;
      
      ++(useCountTable[str]);
    }
    
    // skip literal arguments to ops
/*    if ((unsigned char)input[i] < textCharsStart) {
      ++i;
      int opSize = numOpParamWords((unsigned char)input[i]);
      i += opSize;
    }
    else {
      ++i;
    } */
    ++i;
  }
}

void addRegionsToUseCountTable(Yuna2ScriptReader::RegionToResultMap& input,
                        UseCountTable& useCountTable,
                        int minLength, int maxLength) {
  for (Yuna2ScriptReader::RegionToResultMap::iterator it = input.begin();
       it != input.end();
       ++it) {
    Yuna2ScriptReader::ResultCollection& results = it->second;
    for (Yuna2ScriptReader::ResultCollection::iterator jt = results.begin();
         jt != results.end();
         ++jt) {
//      std::cerr << jt->srcOffset << std::endl;
      if (jt->isLiteral) continue;
      if (jt->isNotCompressible) continue;
      
      addStringToUseCountTable(jt->str, useCountTable,
                               minLength, maxLength);
    }
  }
}

void buildEfficiencyTable(UseCountTable& useCountTable,
                        EfficiencyTable& efficiencyTable) {
  for (UseCountTable::iterator it = useCountTable.begin();
       it != useCountTable.end();
       ++it) {
    std::string str = it->first;
    // penalize by 1 byte (length of the dictionary code)
    double strLen = str.size() - 1;
    double uses = it->second;
//    efficiencyTable[str] = strLen / uses;
    
    efficiencyTable[strLen / uses] = str;
  }
}

void applyDictionaryEntry(std::string entry,
                          Yuna2ScriptReader::RegionToResultMap& input,
                          std::string replacement) {
  for (Yuna2ScriptReader::RegionToResultMap::iterator it = input.begin();
       it != input.end();
       ++it) {
    Yuna2ScriptReader::ResultCollection& results = it->second;
    int index = -1;
    for (Yuna2ScriptReader::ResultCollection::iterator jt = results.begin();
         jt != results.end();
         ++jt) {
      ++index;
      
      if (jt->isNotCompressible) continue;
      
      std::string str = jt->str;
      if (str.size() < entry.size()) continue;
      
      std::string newStr;
      int i;
      for (i = 0; i < str.size() - entry.size(); ) {
        if ((unsigned char)str[i] < textCharsStart) {
/*          int numParams = numOpParamWords((unsigned char)str[i]);
          
          newStr += str[i];
          for (int j = 0; j < numParams; j++) {
            newStr += str[i + 1 + j];
          }
          
          ++i;
          i += numParams; */
          newStr += str[i];
          ++i;
          continue;
        }
        
        if (entry.compare(str.substr(i, entry.size())) == 0) {
          newStr += replacement;
          i += entry.size();
        }
        else {
          newStr += str[i];
          ++i;
        }
      }
      
      while (i < str.size()) newStr += str[i++];
      
      jt->str = newStr;
    }
  }
}

void generateCompressionDictionary(
    Yuna2ScriptReader::RegionToResultMap& results,
    std::string outputDictFileName) {
  TBufStream dictOfs;
  for (int i = 0; i < maxDictionarySymbols; i++) {
//    cerr << i << endl;
    UseCountTable useCountTable;
    addRegionsToUseCountTable(results, useCountTable, 2, 3);
    EfficiencyTable efficiencyTable;
    buildEfficiencyTable(useCountTable, efficiencyTable);
    
//    std::cout << efficiencyTable.begin()->first << std::endl;
    
    // if no compressions are possible, give up
    if (efficiencyTable.empty()) break;  
    
    int symbol = i + textCharsEnd;
    applyDictionaryEntry(efficiencyTable.begin()->second,
                         results,
                         std::string() + (char)symbol);
    
    // debug
/*    TBufStream temp;
    temp.writeString(efficiencyTable.begin()->second);
    temp.seek(0);
//    binToDcb(temp, cout);
    std::cout << "\"";
    while (!temp.eof()) {
      std::cout << table.getEntry(temp.get());
    }
    std::cout << "\"" << std::endl; */
    
    dictOfs.writeString(efficiencyTable.begin()->second);
  }
  
//  dictOfs.save((outPrefix + "dictionary.bin").c_str());
  dictOfs.save(outputDictFileName.c_str());
}

// merge a set of RegionToResultMaps into a single RegionToResultMap
void mergeResultMaps(
    std::vector<Yuna2ScriptReader::RegionToResultMap*>& allSrcPtrs,
    Yuna2ScriptReader::RegionToResultMap& dst) {
  int targetOutputId = 0;
  for (std::vector<Yuna2ScriptReader::RegionToResultMap*>::iterator it
        = allSrcPtrs.begin();
       it != allSrcPtrs.end();
       ++it) {
    Yuna2ScriptReader::RegionToResultMap& src = **it;
    for (Yuna2ScriptReader::RegionToResultMap::iterator jt = src.begin();
         jt != src.end();
         ++jt) {
      dst[targetOutputId++] = jt->second;
    }
  }
}

// undo the effect of mergeResultMaps(), applying any changes made to
// the merged maps back to the separate originals
void unmergeResultMaps(
    Yuna2ScriptReader::RegionToResultMap& src,
    std::vector<Yuna2ScriptReader::RegionToResultMap*>& allSrcPtrs) {
  int targetInputId = 0;
  for (std::vector<Yuna2ScriptReader::RegionToResultMap*>::iterator it
        = allSrcPtrs.begin();
       it != allSrcPtrs.end();
       ++it) {
    Yuna2ScriptReader::RegionToResultMap& dst = **it;
    for (Yuna2ScriptReader::RegionToResultMap::iterator jt = dst.begin();
         jt != dst.end();
         ++jt) {
      jt->second = src[targetInputId++];
    }
  }
}

/*void freeResultSpace(Yuna2ScriptReader::RegionToResultMap& src,
                     BlackT::TFreeSpace& dst) {
  for (Yuna2ScriptReader::RegionToResultMap::iterator it
        = src.begin();
       it != src.end();
       ++it) {
    Yuna2ScriptReader::ResultCollection& results = it->second;
    for (Yuna2ScriptReader::ResultCollection::iterator it
          = results.begin();
         it != results.end();
         ++it) {
      Yuna2ScriptReader::ResultString str = *it;
      // free anything flagged for auto-insertion
      if ((str.pointerRefs.size() > 0)
//          && str.overwriteAddresses.empty()
          ) {
        dst.free(str.srcOffset, str.srcSize);
      }
    }
  }
}

void autoInsertStrings(Yuna2ScriptReader::RegionToResultMap& src,
                       TStream& dst,
                       BlackT::TFreeSpace& freeSpace,
                       unsigned int pointerOffset) {
  for (Yuna2ScriptReader::RegionToResultMap::iterator it
        = src.begin();
       it != src.end();
       ++it) {
    Yuna2ScriptReader::ResultCollection& results = it->second;
    for (Yuna2ScriptReader::ResultCollection::iterator it
          = results.begin();
         it != results.end();
         ++it) {
      Yuna2ScriptReader::ResultString str = *it;
      
      if (str.pointerRefs.size() > 0) {
        // insert to file
        int target = freeSpace.claim(str.str.size());
        unsigned int targetPointer = target + pointerOffset;
        dst.seek(target);
        dst.write(str.str.c_str(), str.str.size());
        
        // update pointer references
        for (int i = 0; i < str.pointerRefs.size(); i++) {
          int pointerOffset = str.pointerRefs[i];
          
//          std::cerr << str.id << ": updating pointer at "
//            << std::hex << pointerOffset
//            << " to "
//            << std::hex << targetPointer
//            << std::endl;
          
          dst.seek(pointerOffset);
          dst.writeu32le(targetPointer);
        }
      }
      
      // overwrite where specified
      for (unsigned int i = 0; i < str.overwriteAddresses.size(); i++) {
        dst.seek(str.overwriteAddresses[i]);
        dst.write(str.str.c_str(), str.str.size());
      }
    }
  }
}

TFreeSpace generateMapFreeSpace(
    const Yuna2ScriptReader::ResultCollection& mapStrings) {
  TFreeSpace freeSpace;
  
  int lowestPos = 0;
  int highestPos = 0;
  if (!mapStrings.empty()) {
    lowestPos = mapStrings.front().srcOffset;
    highestPos = mapStrings.front().srcOffset
                  + mapStrings.front().srcSize;
  }
  
  for (Yuna2ScriptReader::ResultCollection::const_iterator it
        = mapStrings.cbegin();
       it != mapStrings.cend();
       ++it) {
    const Yuna2ScriptReader::ResultString& str = *it;
    
    int endPos = str.srcOffset + str.srcSize;
    if (str.srcOffset < lowestPos) lowestPos = str.srcOffset;
    if (endPos > highestPos) highestPos = endPos;
    
    // free the original locations of all strings
//    freeSpace.free(str.srcOffset, str.srcSize);
    
    // if string uses a standard print sequence
    // (scriptRefEnd != -1).
    // if it does, and there are consecutive print sequences
    // following it, free everything beyond what we need to
    // do one sequence followed by a jump.
    if ((str.scriptRefEnd >= 0)) {
      int newCmdSize = Yuna2PlmData::printSequenceFullSize
        + Yuna2PlmData::jumpSequenceFullSize;
      int additionalSpace = (str.scriptRefEnd - str.scriptRefStart)
                              - newCmdSize;
      if (additionalSpace > 0) {
        freeSpace.free(str.scriptRefStart + newCmdSize,
                       additionalSpace);
      }
    }
  }
  
  // FIXME: very lazy and might not work,
  // but it's easier than trying to separately track all the strings
  // we're merging just to make sure we allocate them one at a time
//  std::cerr << std::hex << lowestPos << " " << highestPos << std::endl;
  freeSpace.free(lowestPos, highestPos - lowestPos);
  
  return freeSpace;
}

void patchMapStrings(const Yuna2ScriptReader::ResultCollection& mapStrings,
                     TStream& ofs) {
  // set up free space
  TFreeSpace freeSpace = generateMapFreeSpace(mapStrings);
  
  for (Yuna2ScriptReader::ResultCollection::const_iterator it
        = mapStrings.cbegin();
       it != mapStrings.cend();
       ++it) {
    const Yuna2ScriptReader::ResultString& str = *it;
    
    // find space for string
    int newStrOffset = freeSpace.claim(str.str.size());
    if (newStrOffset < 0) {
      throw TGenericException(T_SRCANDLINE,
                              "patchMapStrings()",
                              "Ran out of space for map strings");
    }
    
    // write string to new position
    ofs.seek(newStrOffset);
    ofs.writeString(str.str);
    
    // update script reference
    ofs.seek(str.scriptRefStart + 1);
    ofs.writeu16le(newStrOffset);
    
    // if this is a standard print sequence,
    // and this is a multi-part merged string,
    // insert a jump command after the sequence
    // that jumps to the next script command following
    // the merged sequence
    if ((str.scriptRefEnd >= 0)) {
      int areaSize = str.scriptRefEnd - str.scriptRefStart;
      if (areaSize > (Yuna2PlmData::printSequenceFullSize
                        + Yuna2PlmData::jumpSequenceFullSize)) {
        ofs.seek(str.scriptRefStart + Yuna2PlmData::printSequenceFullSize);
        ofs.writeu8(Yuna2PlmData::op_jump);
        ofs.writeu16le(str.scriptRefEnd);
      }
    }
  }
  
//  for (TFreeSpace::FreeSpaceMap::iterator it = freeSpace.freeSpace_.begin();
//       it != freeSpace.freeSpace_.end();
//       ++it) {
//    std::cerr << std::hex << it->first << " " << it->second
//      << " " << it->first + it->second << std::endl;
//  }
} */

void updateTextBlock(TBufStream& iso, int blockNum,
                     Yuna2ScriptReader::ResultCollection& strings) {
//  int blockBasePos = (textBlockBaseSector * sectorSize)
//                      + (blockNum * textBlockSize);
  int blockBasePos = (blockNum * textBlockSize);
  
  //==================================
  // read in target block from iso
  //==================================
  
  TBufStream ifs;
  iso.seek(blockBasePos);
  ifs.writeFrom(iso, textBlockSize);
  ifs.seek(0);
  
  if (strings.size() > 0) {
    //==================================
    // analyze block structure
    //==================================
    
    int scriptBlockOffset = 6;
    int unindexedStringBlockOffset = ifs.readu16le() + scriptBlockOffset;
    int stringIndexBlockOffset = unindexedStringBlockOffset + ifs.readu16le();
    int indexedStringBlockOffset = stringIndexBlockOffset + ifs.readu16le();
    
/*    std::cerr << "block " << blockNum << endl;
    std::cerr << "  " << hex << scriptBlockOffset << endl;
    std::cerr << "  " << hex << unindexedStringBlockOffset << endl;
    std::cerr << "  " << hex << stringIndexBlockOffset << endl;
    std::cerr << "  " << hex << indexedStringBlockOffset << endl;*/
    
    //==================================
    // set up free space
    //==================================
    
    // we could "properly" expand the unindexed block...
    // but why bother when we can just write "outside" it
    // and reference the results without consequence
    int freeSpaceStart = indexedStringBlockOffset;
    int freeSpaceEnd = textBlockSize;
    int freeSpaceSize = freeSpaceEnd - freeSpaceStart;
    
    TFreeSpace freeSpace;
    freeSpace.free(freeSpaceStart, freeSpaceSize);
    
    // as a hack, all original-string free commands are attached
    // to the first string in the block.
    // this is due to this game's unusual situation where each
    // box of dialogue is constructed from independent
    // strings for each individual line of text; as a result,
    // one string in the dump does not correspond to one
    // string in the actual input, so this can't simply be
    // a property of the strings themselves as normal.
    for (unsigned int i = 0; i < strings[0].freeSpaces.size(); i++) {
      Yuna2ScriptReader::ResultString::FreeSpace space
        = strings[0].freeSpaces[i];
      freeSpace.free(unindexedStringBlockOffset + space.pos, space.size);
    }
    
    //==================================
    // write each string to block and
    // update references
    //==================================
    
/*    std::cerr << "block " << blockNum << endl;
    
    std::cerr << "  " << std::hex << indexedStringBlockOffset << std::endl;
    
    for (TFreeSpace::FreeSpaceMap::iterator it = freeSpace.freeSpace_.begin();
         it != freeSpace.freeSpace_.end();
         ++it) {
      std::cerr << "  " << it->first << ": " << it->second << std::endl;
    } */
    
    for (unsigned int i = 0; i < strings.size(); i++) {
      Yuna2ScriptReader::ResultString str = strings[i];
      
      int pos = freeSpace.claim(str.str.size());
      if (pos == -1) {
        throw TGenericException(T_SRCANDLINE,
                                "updateTextBlock()",
                                std::string("Block ")
                                + TStringConversion::intToString(blockNum)
                                + ": failed to find space for string "
                                + TStringConversion::intToString(i));
      }
      
      // write new string
      ifs.seek(pos);
      ifs.writeString(str.str);
      
  //    cerr << "string " << i << " pos: " << hex << pos;
      
      // update script references
      int blockRelPos = pos - unindexedStringBlockOffset;
      for (unsigned int i = 0; i < str.pointerRefs.size(); i++) {
        int offset = str.pointerRefs[i];
        ifs.seek(scriptBlockOffset + offset);
        ifs.writeu16le(blockRelPos);
      }
    }
    
  //  cerr << endl << endl;
  }
  
  //==================================
  // write back updated block to iso
  //==================================
  
  ifs.seek(0);
  iso.seek(blockBasePos);
  iso.writeFrom(ifs, textBlockSize);
}

void updateBattleBlock(TBufStream& iso, int subSectorNum,
                     Yuna2ScriptReader::ResultCollection& strings) {
  int blockBasePos = subSectorNum * sectorSize;
  
  //==================================
  // read in target block from iso
  //==================================
  
  TBufStream ifs;
  iso.seek(blockBasePos);
  ifs.writeFrom(iso, battleBlockSize);
  ifs.seek(0);
  
  //==================================
  // get offset and size of text block
  //==================================
  
  ifs.seek(3);
  int textBlockOffset
    = ifs.readInt(3, EndiannessTypes::little, SignednessTypes::nosign);
  int textBlockSize
    = ifs.readInt(3, EndiannessTypes::little, SignednessTypes::nosign)
      - textBlockOffset;
  
  int textBlockFreeAreaOffset = textBlockOffset + battleBlockIndexSize;
  int textBlockFreeAreaSize = textBlockSize - battleBlockIndexSize;
  
  //==================================
  // update strings and index entries
  //==================================
    
  for (unsigned int i = 0; i < strings.size(); i++) {
    Yuna2ScriptReader::ResultString str = strings[i];
    
    if (str.extraIds.empty()) {
      throw TGenericException(T_SRCANDLINE,
                              "updateBattleBlock()",
                              std::string("Block ")
                              + TStringConversion::intToString(subSectorNum)
                              + ": no ID for string "
                              + TStringConversion::intToString(i));
    }
    
    // we're adding a 2b id string at the start of the string
    int contentSize = str.str.size() + 2;
    
    // try to put block in free space
    if (contentSize > textBlockFreeAreaSize) {
      throw TGenericException(T_SRCANDLINE,
                              "updateBattleBlock()",
                              std::string("Block ")
                              + TStringConversion::intToString(subSectorNum)
                              + ": failed to find space for string "
                              + TStringConversion::intToString(i));
    }
    
    int strPos = textBlockFreeAreaOffset;
    
    ifs.seek(strPos);
    ifs.writeu16le(str.extraIds[0]);
    ifs.writeString(str.str);
    
    textBlockFreeAreaOffset += contentSize;
    textBlockFreeAreaSize -= contentSize;
    
    // update index entries
    for (unsigned int i = 0; i < str.pointerRefs.size(); i++) {
      int ptrId = str.pointerRefs[i];
      ifs.seek(textBlockOffset + (ptrId * 2));
      ifs.writeu16le(strPos - textBlockOffset);
    }
  }
  
  //==================================
  // write back updated block to iso
  //==================================
  
  ifs.seek(0);
  iso.seek(blockBasePos);
  iso.writeFrom(ifs, battleBlockSize);
}

void exportGenericRegion(Yuna2ScriptReader::ResultCollection& results,
                         std::string prefix) {
  for (Yuna2ScriptReader::ResultCollection::iterator it = results.begin();
       it != results.end();
       ++it) {
    if (it->str.size() <= 0) continue;
    
    Yuna2ScriptReader::ResultString str = *it;
    
    std::string outName = prefix + str.id + ".bin";
    TFileManip::createDirectoryForFile(outName);
    
    TBufStream ofs;
    ofs.writeString(str.str);
    ofs.save(outName.c_str());
  }
}


int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Yuna 2 script builder" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [outprefix]"
      << endl;
    return 0;
  }
  
//  string infile(argv[1]);
  string inPrefix(argv[1]);
  string outPrefix(argv[2]);

  table.readUtf8("table/yuna2_en.tbl");
  tableScene.readUtf8("table/yuna2_scenes_en.tbl");
  
  //=====
  // read script
  //=====
  
  Yuna2ScriptReader::RegionToResultMap scriptResults;
  {
    TBufStream ifs;
    ifs.open((inPrefix + "spec_main.txt").c_str());
    Yuna2ScriptReader(ifs, scriptResults, table)();
  }
  
  Yuna2ScriptReader::RegionToResultMap battleResults;
  {
    TBufStream ifs;
    ifs.open((inPrefix + "spec_battle.txt").c_str());
    Yuna2ScriptReader(ifs, battleResults, table)();
  }
  
  Yuna2ScriptReader::RegionToResultMap sceneResults;
  {
    TBufStream ifs;
    ifs.open((inPrefix + "spec_scene.txt").c_str());
    Yuna2ScriptReader(ifs, sceneResults, tableScene)();
  }
  
//  generateCompressionDictionary(
//    scriptResults, outPrefix + "script_dictionary.bin");
  
  //=====
  // compress
  //=====
  
  {
    Yuna2ScriptReader::RegionToResultMap allStrings;
    
    // FIXME: make separate tables for main/battle?
    // if it even matters
    std::vector<Yuna2ScriptReader::RegionToResultMap*> allSrcPtrs;
    allSrcPtrs.push_back(&scriptResults);
    allSrcPtrs.push_back(&battleResults);
    
    // merge everything into one giant map for compression
    mergeResultMaps(allSrcPtrs, allStrings);
    
    // compress
    generateCompressionDictionary(
      allStrings, outPrefix + "script_dictionary.bin");
    
    // restore results from merge back to individual containers
    unmergeResultMaps(allStrings, allSrcPtrs);
  }
  
  //=====
  // update text blocks
  //=====
  
  {
  //  TIfstream ifs("yuna2_02.iso");
    // oops i never made an fstream wrapper and don't want to bother now.
    // we need to read and write this, so let's just load the whole thing
    // into memory, because it's the year 2021 and we can probably afford
    // a few hundred megabytes of RAM
  //  ifs.open("yuna2_02_build.iso");
    // actually, i guess what i did for the first game is probably better...
    TBufStream ifs;
    ifs.open("base/text_all_2E7A.bin");
    
    for (int i = 0; i < numTextBlocks; i++) {
      int unindexedBlockId = (i * 2);
      updateTextBlock(ifs, i, scriptResults[unindexedBlockId]);
    }
    
    ifs.save((outPrefix + "text_all_2E7A.bin").c_str());
  }
  
  //=====
  // update battle blocks
  //=====
  
  {
    TBufStream ifs;
    ifs.open("base/battleblock_all_206.bin");

    for (Yuna2ScriptReader::RegionToResultMap::iterator it
          = battleResults.begin();
         it != battleResults.end();
         ++it) {
      // ignore the miscellaneous strings region
      if (it->first == -1) continue;
      
      // otherwise, region number is target block's sector number
      // within the overall text block
      updateBattleBlock(ifs, it->first, it->second);
    }
    
    ifs.save((outPrefix + "battleblock_all_206.bin").c_str());
  }
  
  //=====
  // export generic/hardcoded strings
  //=====
  
  exportGenericRegion(scriptResults[-1], "out/script/strings/main/");
  exportGenericRegion(battleResults[-1], "out/script/strings/battle/");
  exportGenericRegion(sceneResults[-1], "out/script/strings/scene/");
  
  //=====
  // save modified iso
  //=====
  
//  ifs.save("yuna2_02_build.iso");
  
  //=====
  // create merge of system/sjis strings as "generic" string set
  // for common handling
  //=====
  
/*  Yuna2ScriptReader::RegionToResultMap genericStrings;
  {
    std::vector<Yuna2ScriptReader::RegionToResultMap*> allSrcPtrs;
    allSrcPtrs.push_back(&systemResults);
    allSrcPtrs.push_back(&sjisResults);
    allSrcPtrs.push_back(&newResults);
    mergeResultMaps(allSrcPtrs, genericStrings);
  }
  
  //=====
  // output auto-inserted generic strings
  //=====
  
  {
    
    // free space from original strings
    TFreeSpace mainFreeSpace;
    freeResultSpace(genericStrings, mainFreeSpace);
    
    // TODO: additional space needed?
    // note that most/all of these strings occur in blocks that are padded
    // to the next 4-byte boundary between each string, so freeing those
    // as one big unit will create extra space
    
    // insert strings
    autoInsertStrings(genericStrings, mainIfs, mainFreeSpace,
                      mainExeBaseAddr);
  }
  
  //=====
  // output generic strings to disk for external use
  //=====
  
  TFileManip::createDirectory((outPrefix + "generic").c_str());
  {
    for (Yuna2ScriptReader::RegionToResultMap::iterator it
          = genericStrings.begin();
         it != genericStrings.end();
         ++it) {
      Yuna2ScriptReader::ResultCollection& results = it->second;
      for (Yuna2ScriptReader::ResultCollection::iterator it
            = results.begin();
           it != results.end();
           ++it) {
        Yuna2ScriptReader::ResultString str = *it;
        TBufStream ofs;
        ofs.writeString(str.str);
        ofs.save((outPrefix + "generic/" + str.id + ".bin").c_str());
      }
    }
  }
  
  //=====
  // write modified MAIN.EXE to disk
  //=====
  
  {
    TBufStream ifs;
    ifs.open("out/files/MAIN.EXE");
    ifs.seek(mainExeHeaderSize);
    mainIfs.seek(0);
    ifs.writeFrom(mainIfs, mainIfs.remaining());
    ifs.save("out/files/MAIN.EXE");
  } */
  
  return 0;
}
