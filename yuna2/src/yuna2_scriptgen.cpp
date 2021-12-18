#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "util/TFileManip.h"
#include "util/TStringSearch.h"
#include "exception/TGenericException.h"
#include "yuna2/Yuna2TranslationSheet.h"
#include "yuna2/Yuna2Script.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

const static int textBlockBaseSector = 0x2E7A;
const static int textBlockSize = 0x4000;
// note: looks like they allocated 10 blocks per chapter,
// with each chapter's section padded out with empty placeholder
// entries as needed
const static int numTextBlocks = 50;
const static int numBattleBlocks = 26;
const static int battleSectorBase = 0x206;
const static int battleBlockSize = 0x34;
const static int sectorSize = 0x800;

struct FreeSpaceSpec {
  int pos;
  int size;
};

string as3bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 3) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as1bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 1) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
}

string as2bHexLiteral(int num) {
  return "<$" + as2bHex(num) + ">";
}

//const static unsigned int mainExeLoadAddr = 0x8000F800;
//const static unsigned int mainExeBaseAddr = 0x80010000;
//const static unsigned int mapDataOffsetTableAddr = 0x8012335C;
//const static unsigned int numMaps = 0x46;

//TThingyTable tableScript;
//TThingyTable tableFixed;
//TThingyTable tableSjis;
//TThingyTable tableEnd;

TThingyTable tableSjisUtf8;

void generateAnalyzedBoxString(
    std::string& content, std::string& prefix, std::string& suffix,
    bool noDefaultQuotes = false) {
  // scan first line of content for sjis open quote (81 75).
  // if one exists, and is not at the start of the line,
  // take whatever precedes it as the nametag and turn it
  // into a prefix.
  // also, we want to wrap all boxes of spoken text in quotes,
  // and this game makes the convenient stylistic choice of
  // having almost no narration, so we just assume everything
  // will be quoted in the script dump.
  // the handful of lines that aren't will be manually edited later.
  
//  std::cerr << "starting: " << content << std::endl;
  
  // default prefix = open quote
//  prefix = "{";
  
  // check if nametag prefix exists
  bool found = false;
  // fucking unsigned sizes!!
  for (int i = 0; i < (int)(content.size() - 1); i++) {
    unsigned char next = content[i];
    if (next >= 0x80) {
      unsigned char nextnext = content[i + 1];
      
      if ((next == 0x81) && (nextnext == 0x75)) {
        // sjis open quote on first line:
        // turn this into the prefix
        prefix += content.substr(0, i + 2);
        content = content.substr(i + 2, std::string::npos);
        found = true;
        break;
      }
      
      // 2-byte sequence: skip second char
      ++i;
    }
    else if ((char)next == '\n') {
      // we're only looking at the first line
      break;
    }
  }
  
  if (!found && !noDefaultQuotes) {
    // default prefix = open quote
    prefix += "{";
  }
  
  // suffix = close quote
  if (!noDefaultQuotes) {
    suffix += "}";
  }
  
//  std::cerr << "done: " << content << std::endl;
}

std::string doBattleCodeConversions(std::string str) {
  std::string result;
  
  TBufStream ifs;
  ifs.writeString(str);
  ifs.seek(0);
  
  while (!ifs.eof()) {
    unsigned char next = ifs.get();
    if (!ifs.eof()
        && (next >= 0x80)) {
      // sjis literal
      result += next;
      result += ifs.get();
    }
    else if ((char)next == '\\') {
      // command code
      char nextnext = ifs.get();
      
      // no params
      if ((nextnext == 'n') || (nextnext == 'N')
          || (nextnext == 's') || (nextnext == 'S')
          || (nextnext == 'u') || (nextnext == 'U')
          || (nextnext == '\\')) {
        result += next;
        // decapitalize for compatibility with our tables
        result += tolower(nextnext);
      }
      // these take a 2-digit param
      else if ((nextnext == 'l') || (nextnext == 'L')
               || (nextnext == 'p') || (nextnext == 'P')
               || (nextnext == 'w') || (nextnext == 'W')) {
        result += next;
        // decapitalize for compatibility with our tables
        result += tolower(nextnext);
        
        // convert 2-digit param to literal
        std::string intStr;
        // ignore first digit if zero
        if (ifs.peek() != '0') intStr += ifs.get();
        else ifs.get();
        // add second digit
        intStr += ifs.get();
        
        int val;
        // game uses "++" as a special sequence that's remapped
        // to 0x80 in code
        if (intStr.compare("++") == 0) val = 0x80;
        else val = TStringConversion::stringToInt(intStr);
        
        result += as2bHexLiteral(val);
      }
      else {
        throw TGenericException(T_SRCANDLINE,
                                "doBattleCodeConversions()",
                                "bad input");
      }
    }
    else {
      result += next;
    }
  }
  
  return result;
}

void generateAnalyzedBattleString(
    std::string& content, std::string& prefix, std::string& suffix) {
  // move any initial slash commands to the prefix
  
  std::string newPrefix;
  
//  std::cerr << content << std::endl;
  
  for (int i = 0; i < content.size() - 1; i++) {
    unsigned char next = content[i];
    if (next >= 0x80) {
      // done
      break;
    }
//    else if ((char)next == '\n') {
//      // we're only looking at the first line
//      break;
//    }
    else if ((char)next == '\\') {
      char nextnext = content[i + 1];
      
      // no params
      if ((nextnext == 'n') || (nextnext == 'N')
          || (nextnext == 's') || (nextnext == 'S')
          || (nextnext == 'u') || (nextnext == 'U')
          || (nextnext == '\\')) {
        newPrefix += next;
        newPrefix += nextnext;
        
        i += 1;
      }
      // these take a 2-digit param
      else if ((nextnext == 'l') || (nextnext == 'L')
               || (nextnext == 'p') || (nextnext == 'P')
               || (nextnext == 'w') || (nextnext == 'W')) {
        newPrefix += next;
        newPrefix += nextnext;
        newPrefix += content[i + 2];
        newPrefix += content[i + 3];
        
        i += 3;
      }
      else {
        throw TGenericException(T_SRCANDLINE,
                                "generateAnalyzedBattleString()",
                                "bad input");
      }
    }
    else {
      break;
    }
  }
  
//  std::cerr << "done: " << newPrefix << std::endl;
  
  if (!newPrefix.empty()) {
    prefix += newPrefix;
    if (newPrefix.size() == content.size()) content = "";
    else content = content.substr(newPrefix.size(), std::string::npos);
  }
  
  // convert character code sequences to new format
  content = doBattleCodeConversions(content);
  prefix = doBattleCodeConversions(prefix);
  suffix = doBattleCodeConversions(suffix);
  
//  std::cerr << "done2" << std::endl;
}

std::string toUtf8(std::string str) {
  // convert from SJIS to UTF8
  
  TBufStream conv;
  conv.writeString(str);
  conv.seek(0);
  
  std::string newStr;
  while (!conv.eof()) {
    if (conv.peek() == '\x0A') {
      newStr += conv.get();
    }
/*    else if (conv.peek() == '[') {
      std::string name;
      while (!conv.eof()) {
        char next = conv.get();
        name += next;
        if (next == ']') break;
      }
      newStr += name;
    } */
    else {
      TThingyTable::MatchResult result = tableSjisUtf8.matchId(conv);
      
      if (result.id == -1) {
        throw TGenericException(T_SRCANDLINE,
                                "toUtf8()",
                                "bad input string");
      }
      
      newStr += tableSjisUtf8.getEntry(result.id);
    }
  }
  
  return newStr;
}

class Yuna2GenericString {
public:
  Yuna2GenericString()
      // needs to not be initialized to -1
      // see Yuna2ScriptReader::flushActiveScript()
    : offset(0),
      size(0),
      doBoxAnalysis(false),
      doBattleAnalysis(false) { }
  
  enum Type {
    type_none,
    type_string,
    type_mapString,
    type_setRegion,
    type_setMap,
    type_setNotCompressible,
    type_addOverwrite,
    type_addFreeSpace,
    type_genericLine,
    type_comment,
    type_marker
  };
  
  Type type;
  
  std::string content;
  std::string prefixBase;
  std::string suffixBase;
  int offset;
  int size;
  bool doBoxAnalysis;
  bool doBattleAnalysis;
  
  std::string idOverride;
  
  int scriptRefStart;
  int scriptRefEnd;
  int scriptRefCode;
  
  int regionId;
  
  int mapMainId;
  int mapSubId;
  
  bool notCompressible;
  
  std::vector<int> pointerRefs;
//  int pointerBaseAddr;

  // fuck this
  std::vector<FreeSpaceSpec> freeSpaces;

  std::string translationPlaceholder;
  
  std::vector<int> overwriteAddresses;
  std::vector<int> extraIds;
  std::vector<std::string> genericLines;
  
protected:
  
};

typedef std::vector<Yuna2GenericString> Yuna2GenericStringCollection;

class Yuna2GenericStringSet {
public:
    
  Yuna2GenericStringCollection strings;
  
  static Yuna2GenericString readString(TStream& src, const TThingyTable& table,
                              int offset) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_string;
    result.offset = offset;
    
    src.seek(offset);
    while (!src.eof()) {
      if (src.peek() == 0x00) {
        src.get();
        result.size = src.tell() - offset;
        return result;
      }
      
      TThingyTable::MatchResult matchCheck
        = table.matchId(src);
      if (matchCheck.id == -1) break;
      
      std::string newStr = table.getEntry(matchCheck.id);
      result.content += newStr;
      
      // HACK
      if (newStr.compare("\\n") == 0) result.content += "\n";
    }
    
    throw TGenericException(T_SRCANDLINE,
                            "Yuna2GenericStringSet::readString()",
                            std::string("bad string at ")
                            + TStringConversion::intToString(offset));
  }
  
  void addString(TStream& src, const TThingyTable& table,
                 int offset) {
    Yuna2GenericString result = readString(src, table, offset);
    strings.push_back(result);
  }
  
  void addRawString(std::string content, int offset, int size) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_string;
    result.content = content;
    result.offset = offset;
    result.size = size;
    strings.push_back(result);
  }
  
  void addOverwriteString(TStream& src, const TThingyTable& table,
                 int offset) {
    Yuna2GenericString result = readString(src, table, offset);
    result.overwriteAddresses.push_back(offset);
    strings.push_back(result);
  }
  
  void addMarker(std::string content) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_marker;
    result.content = content;
    strings.push_back(result);
  }
  
  void addPointerTableString(TStream& src, const TThingyTable& table,
                             int offset, int pointerOffset) {
    // check if string already exists, and add pointer ref if so
    for (unsigned int i = 0; i < strings.size(); i++) {
      Yuna2GenericString& checkStr = strings[i];
      // mapStrings need not apply
      if (checkStr.type == Yuna2GenericString::type_string) {
        if (checkStr.offset == offset) {
          checkStr.pointerRefs.push_back(pointerOffset);
          return;
        }
      }
    }
    
    // new string needed
    Yuna2GenericString result = readString(src, table, offset);
    result.pointerRefs.push_back(pointerOffset);
    strings.push_back(result);
  }
  
  void addComment(std::string comment) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_comment;
    result.content = comment;
    strings.push_back(result);
  }
  
  void addSetNotCompressible(bool notCompressible) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_setNotCompressible;
    result.notCompressible = notCompressible;
    strings.push_back(result);
  }
  
  void addAddOverwrite(int offset) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_addOverwrite;
    result.offset = offset;
    strings.push_back(result);
  }
  
  void addAddFreeSpace(int offset, int size) {
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_addFreeSpace;
    result.offset = offset;
    result.size = size;
    strings.push_back(result);
  }
  
  void addSetRegion(int regionId) {
    Yuna2GenericString str;
    str.type = Yuna2GenericString::type_setRegion;
    str.regionId = regionId;
    strings.push_back(str);
  }
  
  void addGenericLine(std::string content) {
    Yuna2GenericString str;
    str.type = Yuna2GenericString::type_genericLine;
    str.content = content;
    strings.push_back(str);
  }
  
  void exportToSheet(
      Yuna2TranslationSheet& dst,
      std::ostream& ofs,
      std::string idPrefix) const {
    int strNum = 0;
    for (unsigned int i = 0; i < strings.size(); i++) {
      const Yuna2GenericString& item = strings[i];
      
      if ((item.type == Yuna2GenericString::type_string)
          || (item.type == Yuna2GenericString::type_mapString)) {
        std::string idString = idPrefix
//          + TStringConversion::intToString(strNum)
//          + "-"
          + TStringConversion::intToString(strings[i].offset,
              TStringConversion::baseHex);
        if (!item.idOverride.empty()) idString = item.idOverride;
        
        std::string content = item.content;
        std::string prefix = "";
        std::string suffix = "";
        
        if (item.doBattleAnalysis) {
          generateAnalyzedBattleString(content, prefix, suffix);
        }
        
        if (item.doBoxAnalysis) {
          generateAnalyzedBoxString(content, prefix, suffix);
        }
        
        prefix = item.prefixBase + prefix;
        suffix = item.suffixBase + suffix;
    
//    std::cerr << content << std::endl;
        
        content = toUtf8(content);
        prefix = toUtf8(prefix);
        suffix = toUtf8(suffix);
        
//        std::cerr << content << std::endl;
        
        dst.addStringEntry(
          idString, content, prefix, suffix, item.translationPlaceholder);
        
        ofs << "#STARTSTRING("
          << "\"" << idString << "\""
          << ", "
          << TStringConversion::intToString(item.offset,
              TStringConversion::baseHex)
          << ", "
          << TStringConversion::intToString(item.size,
              TStringConversion::baseHex)
          << ")" << endl;
        
        if (item.type == Yuna2GenericString::type_mapString) {
          ofs << "#SETSCRIPTREF("
            << TStringConversion::intToString(item.scriptRefStart,
              TStringConversion::baseHex)
            << ", "
            << TStringConversion::intToString(item.scriptRefEnd,
              TStringConversion::baseHex)
            << ", "
            << TStringConversion::intToString(item.scriptRefCode,
              TStringConversion::baseHex)
            << ")"
            << endl;
        }
        
        for (unsigned int i = 0; i < item.freeSpaces.size(); i++) {
          ofs << "#ADDFREESPACE("
            << TStringConversion::intToString(item.freeSpaces[i].pos,
              TStringConversion::baseHex)
            << ", "
            << TStringConversion::intToString(item.freeSpaces[i].size,
              TStringConversion::baseHex)
            << ")"
            << endl;
        }
        
        for (unsigned int i = 0; i < item.pointerRefs.size(); i++) {
          ofs << "#ADDPOINTERREF("
            << TStringConversion::intToString(item.pointerRefs[i],
              TStringConversion::baseHex)
            << ")"
            << endl;
        }
        
        for (unsigned int i = 0; i < item.overwriteAddresses.size(); i++) {
          ofs << "#ADDOVERWRITE("
            << TStringConversion::intToString(item.overwriteAddresses[i],
              TStringConversion::baseHex)
            << ")"
            << endl;
        }
        
        for (unsigned int i = 0; i < item.extraIds.size(); i++) {
          ofs << "#ADDEXTRAID("
            << TStringConversion::intToString(item.extraIds[i],
              TStringConversion::baseHex)
            << ")"
            << endl;
        }
        
        for (unsigned int i = 0; i < item.genericLines.size(); i++) {
          ofs << item.genericLines[i] << std::endl;
        }
        
        ofs << "#IMPORT(\"" << idString << "\")" << endl;
        
        ofs << "#ENDSTRING()" << endl;
        ofs << endl;
        
        ++strNum;
      }
      else if (item.type == Yuna2GenericString::type_setRegion) {
        ofs << "#STARTREGION("
          << item.regionId
          << ")" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_setMap) {
        ofs << "#SETMAP("
          << item.mapMainId
          << ", "
          << item.mapSubId
          << ")" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_setNotCompressible) {
        ofs << "#SETNOTCOMPRESSIBLE("
          << (item.notCompressible ? 1 : 0)
          << ")" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_addOverwrite) {
        ofs << "#ADDOVERWRITE("
          << TStringConversion::intToString(item.offset,
            TStringConversion::baseHex)
          << ")" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_addFreeSpace) {
        ofs << "#ADDFREESPACE("
          << TStringConversion::intToString(item.offset,
            TStringConversion::baseHex)
          << ", "
          << TStringConversion::intToString(item.size,
            TStringConversion::baseHex)
          << ")" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_genericLine) {
        ofs << item.content << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_comment) {
        dst.addCommentEntry(item.content);
        
        ofs << "//===================================" << endl;
        ofs << "// " << item.content << endl;
        ofs << "//===================================" << endl;
        ofs << endl;
      }
      else if (item.type == Yuna2GenericString::type_marker) {
        dst.addMarkerEntry(item.content);
        
        ofs << "// === MARKER: " << item.content << endl;
        ofs << endl;
      }
    }
  }
  
protected:
  
};

/*void readGenericMainPtrTable(TStream& src, Yuna2GenericStringSet& dst,
                             const TThingyTable& table,
                             int start, int end) {
  int size = (end - start) / 4;
  for (int i = 0; i < size; i++) {
    int target = start + (i * 4);
    src.seek(target);
    int offset = src.readu32le() - mainExeBaseAddr;
//    if (offset >= src.size()) continue;
//    dst.addString(src, table, offset);
    dst.addPointerTableString(src, table, offset, target);
  }
}

void readGenericMainPtrTableRev(TStream& src, Yuna2GenericStringSet& dst,
                             const TThingyTable& table,
                             int start, int end) {
  int size = (end - start) / 4;
  // these tables are in reverse order for whatever compiler-related reason
  for (int i = size - 1; i >= 0; i--) {
    int target = start + (i * 4);
    src.seek(target);
    int offset = src.readu32le() - mainExeBaseAddr;
//    if (offset >= src.size()) continue;
//    dst.addString(src, table, offset);
    dst.addPointerTableString(src, table, offset, target);
  }
} */

void readGenericStringBlock(TStream& src, Yuna2GenericStringSet& dst,
                             const TThingyTable& table,
                             int start, int end) {
  src.seek(start);
  while (src.tell() < end) {
    int offset = src.tell();
    dst.addString(src, table, offset);
    
    // ignore null padding
    // (strings are padded to next word boundary)
    while (!src.eof() && (src.peek() == 0x00)) src.get();
  }
}

void readGenericStringBlockPtrOvr(TStream& src, Yuna2GenericStringSet& dst,
                             const TThingyTable& table,
                             int start, int end) {
  src.seek(start);
  while (src.tell() < end) {
    int offset = src.tell();
//    dst.addString(src, table, offset);
    
    // new string needed
    Yuna2GenericString result = dst.readString(src, table, offset);
    result.pointerRefs.push_back(offset);
    dst.strings.push_back(result);
    
    // ignore null padding
    // (strings are padded to next word boundary)
    while (!src.eof() && (src.peek() == 0x00)) src.get();
  }
}

/*void addGenericStringToSet(TStream& src, Yuna2GenericStringSet& dst,
                      const TThingyTable& table,
                      int offset
//                      std::string idPrefix
                      ) {
//  std::string idString = idPrefix
//    + "-"
//    + TStringConversion::intToString(offset);
  
  Yuna2GenericString result;
  result.offset = offset;
  
  src.seek(offset);
  while (!src.eof()) {
    if (src.peek() == 0x00) {
      src.get();
      result.size = src.tell() - offset;
      dst.strings.push_back(result);
      return;
    }
    
    TThingyTable::MatchResult matchCheck
      = table.matchId(src);
    if (matchCheck.id == -1) break;
    
    result.content += table.getEntry(matchCheck.id);
  }
  
  throw TGenericException(T_SRCANDLINE,
                          "addGenericString()",
                          std::string("bad string at ")
                          + TStringConversion::intToString(offset));
} */

void dumpString(TStream& ifs, Yuna2GenericStringSet& strings,
                std::string idOverride = "") {
  std::ostringstream ofs;
  std::ostringstream preOfs;
  std::ostringstream contentOfs;
  std::ostringstream postOfs;
  int startPos = ifs.tell();
  
//  std::cerr << std::hex << startPos << std::endl;
  
  bool atLineStart = true;
  bool onCommentLine = false;
  bool literalsNotColors = false;
  while (true) {
    char next = ifs.get();
    if (next == 0x00) break;
    
    if (next > 0) {
      if (next == '\x0A') {
        // linebreak
        ofs << "[br]" << endl;
        atLineStart = true;
        onCommentLine = false;
        
        contentOfs << "[br]" << endl;
      }
      else {
        if (!literalsNotColors
            && (isdigit(next)
                || (next == 'A')
                || (next == 'B')
                || (next == 'C')
                || (next == 'D')
                || (next == 'E')
                || (next == 'F'))
            ) {
          if (onCommentLine) {
            ofs << endl;
            onCommentLine = false;
          }
          ofs << "[color" << next << "]" << endl;
          onCommentLine = false;
          atLineStart = true;
          
          if (!contentOfs.str().size()) {
            preOfs << "[color" << next << "]";
          }
          else {
            contentOfs << "[color" << next << "]" << endl;
          }
        }
        else {
//          if (atLineStart) {
//            ofs << "// ";
//            atLineStart = false;
//            onCommentLine = true;
//          }
          if (atLineStart) {
            atLineStart = false;
            onCommentLine = false;
          }
          
          ofs << next;
          contentOfs << next;
          
          literalsNotColors = true;
        }
      }
    }
    else {
      // 2-byte sjis sequence
      
      char nextnext = ifs.get();
      unsigned char uNext = next;
      unsigned char uNextNext = nextnext;
      
      if ((uNext == 0x81) && (uNextNext == 0xA5)) {
        // "more" indicator"
        
        if (!atLineStart) {
          ofs << endl;
        }
        ofs << endl;
        
        ofs << "[more]" << endl;
        atLineStart = true;
        onCommentLine = false;
        
        // FIXME: is this assumption safe?
        postOfs << "[more]";
      }
      else {
        if (atLineStart) {
          ofs << "// ";
          atLineStart = false;
          onCommentLine = true;
        }
        
        ofs << next << nextnext;
        contentOfs << next << nextnext;
      }
    }
  }
  
  if (!atLineStart) ofs << endl;
  ofs << endl;
  
  // literal string flag
  // i'm assuming these bajillion little strings with "f63 = 0"
  // and the like are actually used for setting/evaluating
  // conditions or something, so flag them as such
  bool isLiteral = literalsNotColors;
  
  // add translation string
/*  int srcId = -1;
  if (!isLiteral) {
    YunaTranslationString transStr;
    transStr.id = translationSheet.nextEntryId();
    srcId = transStr.id;
    transStr.sharedContentPre = preOfs.str();
    transStr.sharedContentPost = postOfs.str();
//    transStr.original = contentOfs.str();
    // convert from SJIS to UTF8
//    std::cerr << translationSheet.nextEntryId() << endl;
    {
      std::string origRaw = contentOfs.str();
      TBufStream conv;
      conv.writeString(origRaw);
      conv.seek(0);
//      cerr << conv.size() << endl;
      while (!conv.eof()) {
        if (conv.peek() == '\x0A') {
          transStr.original += conv.get();
        }
        else if (conv.peek() == '[') {
          std::string name;
          while (!conv.eof()) {
            char next = conv.get();
            name += next;
            if (next == ']') break;
          }
          transStr.original += name;
        }
        else {
          TThingyTable::MatchResult result = tableSjisUtf8.matchId(conv);
          transStr.original += tableSjisUtf8.getEntry(result.id);
        }
      }
    }
    translationSheet.addEntry(transStr);
  } */
  
//  std::cerr << contentOfs.str() << std::endl;
  std::string newStr;
  if (!isLiteral) {
    // convert from SJIS to UTF8
    {
      std::string origRaw = contentOfs.str();
      TBufStream conv;
      conv.writeString(origRaw);
      conv.seek(0);

      while (!conv.eof()) {
        if (conv.peek() == '\x0A') {
          newStr += conv.get();
        }
        else if (conv.peek() == '[') {
          std::string name;
          while (!conv.eof()) {
            char next = conv.get();
            name += next;
            if (next == ']') break;
          }
          newStr += name;
        }
        else {
          TThingyTable::MatchResult result = tableSjisUtf8.matchId(conv);
          newStr += tableSjisUtf8.getEntry(result.id);
        }
      }
    }
    
    newStr = preOfs.str() + newStr + postOfs.str();
  }
  else {
    newStr = contentOfs.str();
  }
  
/*  outofs << "#STARTSTRING(" << index
    << ", "
    <<  TStringConversion::intToString(
          (srcOffsetOverride == -1) ? startPos : srcOffsetOverride,
          TStringConversion::baseHex)
    << ", "
    <<  TStringConversion::intToString(ifs.tell() - startPos,
          TStringConversion::baseHex)
    << ", "
    << TStringConversion::intToString(isLiteral)
    << ")" << endl << endl;
  
  if (isLiteral) {
    outofs << ofs.str();
  }
  else {
    outofs << "#IMPORTSTRING(" << srcId << ")" << endl;
  }
  
  outofs << endl << "#ENDSTRING()" << endl << endl; */
  
//  std::cerr << newStr << std::endl;

//  strings.addRawString(newStr, startPos, ifs.tell() - startPos);
  
  Yuna2GenericString result;
  result.type = Yuna2GenericString::type_string;
  result.content = newStr;
  result.offset = startPos;
  result.size = ifs.tell() - startPos;
  result.idOverride = idOverride;
  strings.strings.push_back(result);
}

std::string getRawString(TStream& ifs, int offset) {
  ifs.seek(offset);
  std::string result;
  char next;
  while (!ifs.eof() && ((next = ifs.get()) != 0)) result += next;
  return result;
}

std::string getRawStringWithConversions(TStream& ifs, int offset) {
  ifs.seek(offset);
  std::string result;
  
  char next;
  while (!ifs.eof() && ((next = ifs.get()) != 0)) {
    if (!ifs.eof() && ((unsigned char)next >= 0x80)) {
      // 2b sjis sequence
      result += next;
      result += ifs.get();
    }
    else {
      if (!ifs.eof() && (next == '\\')) {
        char nextnext = ifs.get();
        
        // insert linebreaks after linebreak commands
        if ((nextnext == 'n') || (nextnext == 'N')) {
          result += next;
          result += nextnext;
          result += '\n';
        }
        // some kind of box break
        else if ((nextnext == 'l') || (nextnext == 'L')) {
          result += next;
          result += nextnext;
          result += ifs.get();
          result += ifs.get();
          result += "\n\n";
        }
        else {
          result += next;
          ifs.unget();
        }
      }
      else {
        result += next;
      }
    }
  }
  
  return result;
}

struct BoxStringResult {
  std::string content;
  std::vector<int> pointerRefs;
//  int originalContentOffset;
  int originalContentSize;
  std::vector<FreeSpaceSpec> freeSpaces;
};

void dumpBoxString(const BoxStringResult& boxString,
                   Yuna2GenericStringSet& strings,
                   std::string idPrefix = "",
                   int offset = -1,
                   bool doBoxConversion = false) {
  Yuna2GenericString result;
  result.type = Yuna2GenericString::type_string;
//  result.offset = offset;
  // for technical reasons, the offset must be "valid" (not -1).
  // Yuna2ScriptReader interprets an offset of -1 as a placeholder for
  // "no string" and will not output anything if it is used.
  // so even though these fields are not used, they need to be filled.
  // (now done in constructor)
//  result.offset = 0;
//  result.size = 0;
  
  for (std::vector<int>::const_iterator it = boxString.pointerRefs.cbegin();
       it != boxString.pointerRefs.cend();
       ++it) {
    result.pointerRefs.push_back(*it);
  }
  
  for (std::vector<FreeSpaceSpec>::const_iterator it
        = boxString.freeSpaces.cbegin();
       it != boxString.freeSpaces.cend();
       ++it) {
    result.freeSpaces.push_back(*it);
  }
  
  std::string content = boxString.content;
  
  result.content = content;
  result.doBoxAnalysis = doBoxConversion;
  
  result.idOverride = idPrefix + "-"
    + TStringConversion::intToString(offset,
        TStringConversion::baseHex);
  
  strings.strings.push_back(result);
}

//void dumpTextBlock(TStream& ifs, std::ostream& ofs, int blockNum) {
void dumpTextBlock(TStream& ifs, Yuna2GenericStringSet& strings,
                   int blockNum) {
  std::cout << "dumping block " << blockNum << std::endl;
  
//  strings.addCommentWide(
  strings.addComment(
               string("Text block ")
                + TStringConversion::intToString(blockNum)
                + " (sector "
                + TStringConversion::intToString(
                    textBlockBaseSector
                    + ((blockNum * textBlockSize) / sectorSize),
                    TStringConversion::baseHex)
                + ")");
  
  int blockBaseAddr = (textBlockBaseSector * sectorSize)
                        + (blockNum * textBlockSize);
  ifs.seek(blockBaseAddr);
  
  int scriptDataPos = ifs.tell() + 6;
  int scriptDataSize = ifs.readu16le();
  int unindexedStringBlockOffset = scriptDataSize + 6;
  int stringIndexBlockOffset = unindexedStringBlockOffset + ifs.readu16le();
  int indexedStringBlockOffset = stringIndexBlockOffset + ifs.readu16le();
  
  //=====
  // script data
  //=====
  
  ifs.seek(scriptDataPos);
  Yuna2Script script;
  script.read(ifs, scriptDataSize);
  
  // analyze:
  // - identify all strings used by op 0x16 = print
  //   - concatenate each box into a single string
  //   - preprocess for nametags
  //   - create map of first string addr -> list of callers
  //     (not sure if recycled strings exist but best to account for it)
  // - identify all strings used by op 0x11 (args[1] = string offset)
  //   - create map of string addr -> list of callers
  // - all other strings are literals such as condition strings
  //   or filenames and do not matter
  
  // - okay, optimized boxes are a problem.
  //   we need to make them unique.
  //   add every box string we read to a list, regardless
  //   of uniqueness of contents, then handle those sequentially.
  //   separately generate a free space list with all substrings.
  
//  std::map<int, BoxStringResult> boxStrings;
  std::map<int, BoxStringResult> freeSpaceBoxStrings;
  std::vector<BoxStringResult> boxStrings;
  std::map<int, BoxStringResult> menuStrings;
  
  for (int i = 0; i < script.ops.size(); i++) {
    Yuna2ScriptOp op = script.ops[i];
    // op 16 = print
    if (op.opcode == 0x16) {
      // each param points to the string for the corresponding line
      // of the text box
      
      if (op.params.size() <= 0) continue;
      
      int strOffset = op.params[0];
      
      std::string str;
      int totalSize = 0;
      for (int j = 0; j < op.params.size(); j++) {
        std::string nextStr = getRawString(ifs,
          blockBaseAddr + unindexedStringBlockOffset + op.params[j]);
        // +1 to account for terminator
        freeSpaceBoxStrings[op.params[j]].originalContentSize
          = nextStr.size() + 1;
        totalSize += nextStr.size() + 1;
        str += nextStr;
        
        // add linebreak if not last line
        if (j != op.params.size() - 1) {
          str += '\n';
        }
      }
      
      // pointer = first line pointer
      int strPtrOffset = op.offset + 4;
      
/*      BoxStringResult& result = boxStrings[strOffset];
      
      if (!result.pointerRefs.empty()
          && (result.content.compare(str) != 0)) {
        std::cerr << "bad 1" << endl;
        std::cerr << strOffset << std::endl;
        std::cerr << "was: " << result.content << std::endl;
        std::cerr << "now: " << str << std::endl;
      }
      
      result.content = str;
      result.pointerRefs.push_back(strPtrOffset);
      result.originalContentSize = totalSize; */
      
      BoxStringResult result;
      result.content = str;
      result.pointerRefs.push_back(strPtrOffset);
      // dummy
      result.originalContentSize = -1;
      
      boxStrings.push_back(result);
    }
    // op 11 = set menu option
    else if (op.opcode == 0x11) {
      // params[1] == string offset in unindexed block
      int strOffset = op.params[1];
      std::string str = getRawString(ifs,
        blockBaseAddr + unindexedStringBlockOffset + op.params[1]);
      int strPtrOffset = op.offset + 6;
      freeSpaceBoxStrings[strOffset].originalContentSize
        = str.size() + 1;
      int totalSize = str.size() + 1;
      
      BoxStringResult& result = menuStrings[strOffset];
      
/*      if (!result.pointerRefs.empty()
          && (result.content.compare(str) != 0)) {
        std::cerr << "bad 2" << endl;
        std::cerr << strOffset << std::endl;
        std::cerr << "was: " << result.content << std::endl;
        std::cerr << "now: " << str << std::endl;
      } */
      
      result.content = str;
      result.pointerRefs.push_back(strPtrOffset);
      result.originalContentSize = totalSize;
    }
  }
  
/*  for (std::map<int, BoxStringResult>::iterator it = boxStrings.begin();
       it != boxStrings.end();
       ++it) {
    if (it->second.pointerRefs.size() > 1) {
//      std::cerr << "here" << std::endl;
      std::cerr << it->first << std::endl;
      std::cerr << it->second.content << std::endl;
    }
  } */
  
  //=====
  // unindexed strings
  //=====
  
  int unindexedStringBlockSize
    = stringIndexBlockOffset - unindexedStringBlockOffset;
  
//  strings.addCommentNarrow(
  strings.addComment(
                 string("Unindexed strings "));
  
//  ofs << "#STARTREGION(" << (blockNum * 2) << ")" << endl
//    << endl;
  strings.addSetRegion(blockNum * 2);
  
/*  for (std::map<int, BoxStringResult>::iterator it
        = freeSpaceBoxStrings.begin();
       it != freeSpaceBoxStrings.end();
       ++it) {
    strings.addAddFreeSpace(it->first, it->second.originalContentSize);
  } */
  
  // HACK: shove all free space definitions into the
  // first available string because the existing script reader
  // isn't set up to handle things being attached directly
  // to the region itself
  BoxStringResult* freeDst = NULL;
  if (!menuStrings.empty()) {
    freeDst = &(menuStrings.begin()->second);
  }
  else if (!boxStrings.empty()) {
    freeDst = &(*(boxStrings.begin()));
  }
  
  if (freeDst != NULL) {
    for (std::map<int, BoxStringResult>::iterator it
          = freeSpaceBoxStrings.begin();
         it != freeSpaceBoxStrings.end();
         ++it) {
      FreeSpaceSpec spec;
      spec.pos = it->first;
      spec.size = it->second.originalContentSize;
      freeDst->freeSpaces.push_back(spec);
    }
  }
  
//  ofs << "#SETSIZE(-1, -1)" << endl
//    << endl;
//  strings.addGenericLine("#SETSIZE(216, 4)");
  strings.addGenericLine("#SETSIZE(224, 4)");
  
/*  ifs.seek(blockBaseAddr + unindexedStringBlockOffset);
  int unindexedStringNum = 0;
  while ((ifs.tell() - blockBaseAddr - unindexedStringBlockOffset)
          < unindexedStringBlockSize) {
//    dumpString(ifs, strings, unindexedStringNum,
//               ifs.tell() - (blockBaseAddr + unindexedStringBlockOffset));
    dumpString(ifs, strings,
      std::string("block")
      + TStringConversion::intToString(blockNum)
      + "-"
      + TStringConversion::intToString(
          ifs.tell() - blockBaseAddr - unindexedStringBlockOffset,
          TStringConversion::baseHex));
    ++unindexedStringNum;
  } */
  
  std::string idPrefix = std::string("block")
      + TStringConversion::intToString(blockNum);
  
  // dump menu strings
  for (std::map<int, BoxStringResult>::iterator it
        = menuStrings.begin();
       it != menuStrings.end();
       ++it) {
    BoxStringResult& result = it->second;
    
    // HACK: block 1 ask/listen hack
    if (blockNum == 1) {
      if (it->first == 0x126) {
        // ignore the reference at 0x109A;
        // we are changing it to reference a new string
        for (std::vector<int>::iterator it = result.pointerRefs.begin();
             it != result.pointerRefs.end();
             ++it) {
          if (*it == 0x109A) {
            result.pointerRefs.erase(it);
            break;
          }
        }
      }
    }
    
    dumpBoxString(result, strings, idPrefix, it->first);
  }
  
  // dump box strings
  {
    int num = 0;
    for (std::vector<BoxStringResult>::iterator it
          = boxStrings.begin();
         it != boxStrings.end();
         ++it) {
      BoxStringResult& result = *it;
      dumpBoxString(result, strings,
        idPrefix + "-n", num,
        true);
      ++num;
    }
  }
  
  // HACK: we need to change some instances of "kiku" from "ask"
  // to "listen to" in block 1; make that happen
  if (blockNum == 1) {
    // we do NOT want this to appear in the string sheet
    // (it will be added manually at the end of the sheet)
    strings.addGenericLine("// block 1 ask/listen hack");
    strings.addGenericLine("#STARTSTRING(\"block1-listen-hack\", 0, 0)");
    strings.addGenericLine("#ADDPOINTERREF(0x109A)");
    strings.addGenericLine("#IMPORT(\"block1-listen-hack-content\")");
    strings.addGenericLine("#ENDSTRING()");
  }
  
//  ofs << "#ENDUNINDEXEDSTRINGBLOCK()" << endl
//    << endl;
  
//  ofs << "#ENDREGION(" << (blockNum * 2) << ")" << endl
//    << endl;
  
  //=====
  // indexed strings
  // (no longer used in this game, so this will always output
  // an empty set)
  //=====
  
  int indexedStringBlockSize
    = indexedStringBlockOffset - stringIndexBlockOffset;
  int numIndexedStrings = indexedStringBlockSize/2;
  
//  addLabelNarrow(ofs,
  strings.addComment(
                 string("Indexed strings "));
  
//  ofs << "#STARTREGION(" << (blockNum * 2) + 1 << ")" << endl
//    << endl;
  strings.addSetRegion((blockNum * 2) + 1);
  
//  ofs << "#SETSIZE(240, 4)" << endl
//    << endl;
//  strings.addGenericLine("#SETSIZE(216, 4)");
  strings.addGenericLine("#SETSIZE(224, 4)");
  
  ifs.seek(blockBaseAddr + stringIndexBlockOffset);
//  cerr << ifs.tell() << endl;
  
  std::vector<int> stringIndex;
  for (int i = 0; i < numIndexedStrings; i++) {
    stringIndex.push_back(ifs.readu16le());
  }
  
  for (int i = 0; i < numIndexedStrings; i++) {
    if (stringIndex[i] == 0xFFFF) continue;
    ifs.seek(blockBaseAddr + indexedStringBlockOffset + stringIndex[i]);
//    dumpString(ifs, strings, i,
//               ifs.tell() - (blockBaseAddr + indexedStringBlockOffset));
    dumpString(ifs, strings);
  }
  
//  ofs << "#ENDREGION(" << (blockNum * 2) + 1 << ")" << endl
//    << endl;
}

Yuna2GenericString getGenericString(TStream& ifs, int offset) {
  Yuna2GenericString result;
  result.type = Yuna2GenericString::type_string;
  result.offset = offset;
  result.doBoxAnalysis = true;
  
  std::string content;
  content += getRawString(ifs, offset);
  result.content = content;
  result.size = ifs.tell() - offset;
  
  return result;
}

Yuna2GenericString getGenericConvString(TStream& ifs, int offset) {
  Yuna2GenericString result;
  result.type = Yuna2GenericString::type_string;
  result.offset = offset;
  result.doBoxAnalysis = true;
  result.doBattleAnalysis = true;
  
  std::string content;
  content += getRawStringWithConversions(ifs, offset);
  result.content = content;
  result.size = ifs.tell() - offset;
  
  return result;
}

void dumpGenericStringWithConversions(
    TStream& ifs, Yuna2GenericStringSet& strings, int offset) {
  strings.strings.push_back(getGenericConvString(ifs, offset));
}

void dumpGenericString(
    TStream& ifs, Yuna2GenericStringSet& strings, int offset) {
  strings.strings.push_back(getGenericString(ifs, offset));
}

void dumpGenericRawString(
    TStream& ifs, Yuna2GenericStringSet& strings, int offset) {
  Yuna2GenericString result = getGenericString(ifs, offset);
  result.doBattleAnalysis = false;
  result.doBoxAnalysis = false;
  strings.strings.push_back(result);
}

void dumpBattlePerson(TStream& mainifs, Yuna2GenericStringSet& strings) {
  int sectorNum = mainifs.tell() / sectorSize;
  int subSectorNum = sectorNum - battleSectorBase;
  
  std::cout << "dumping battle person " << std::hex << sectorNum << std::endl;
  
//  strings.addCommentWide(
  strings.addComment(
               string("Battle block ")
                + TStringConversion::intToString(
                    subSectorNum,
                    TStringConversion::baseHex));
  
  strings.addSetRegion(subSectorNum);
  strings.addGenericLine("#SETSIZE(216, 3)");
  
  TBufStream blockIfs;
  blockIfs.writeFrom(mainifs, 0x34 * sectorSize);
  
  blockIfs.seek(3);
  int textBlockOffset
    = blockIfs.readInt(3, EndiannessTypes::little, SignednessTypes::nosign);
  blockIfs.seek(textBlockOffset);
  
/*  TBufStream ifs;
  ifs.writeFrom(blockIfs, 0x800);
  for (int i = 0; i < 64; i++) {
    ifs.seek(i * 2);
    
    int stringOffset = ifs.readu16le();
    if (stringOffset == 0) {
      continue;
    }
    
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_string;
    result.doBoxAnalysis = true;
    result.doBattleAnalysis = true;
    
    // each string is prefixed with a 2b id of some sort
    ifs.seek(stringOffset);
    result.prefixBase += as2bHexLiteral(ifs.readu8());
    result.prefixBase += as2bHexLiteral(ifs.readu8());
    
    std::string content;
//    content += getRawString(ifs, ifs.tell());
    content += getRawStringWithConversions(ifs, ifs.tell());
    result.content = content;
    
    result.idOverride = "battle-block"
      + TStringConversion::intToString(sectorNum,
          TStringConversion::baseHex)
      + "-"
      + TStringConversion::intToString(i,
          TStringConversion::baseHex);
//    result.genericLines.push_back(std::string("#SETSUBID(")
//      + TStringConversion::intToString(i)
//      + ")");
    
    strings.strings.push_back(result);
  } */
  
  std::map<int, std::vector<int> > data;
  
  TBufStream ifs;
  ifs.writeFrom(blockIfs, 0x800);
  for (int i = 0; i < 64; i++) {
    ifs.seek(i * 2);
    
    int stringOffset = ifs.readu16le();
    if (stringOffset == 0) {
      continue;
    }
    
    data[stringOffset].push_back(i);
  }
  
  for (std::map<int, std::vector<int> >::iterator it = data.begin();
       it != data.end();
       ++it) {
    int stringOffset = it->first;
    
    Yuna2GenericString result;
    result.type = Yuna2GenericString::type_string;
    result.doBoxAnalysis = true;
    result.doBattleAnalysis = true;
    
    // each string is prefixed with a 2b id of some sort
    ifs.seek(stringOffset);
//    result.prefixBase += as2bHexLiteral(ifs.readu8());
//    result.prefixBase += as2bHexLiteral(ifs.readu8());
    // actually, we don't want this to be subject to compression
    // or interfere with deduplication, and we're not going to
    // change it in any case, so let's move it out of the string
    int stringId = ifs.readu16le();
    result.extraIds.push_back(stringId);
    
    std::string content;
//    content += getRawString(ifs, ifs.tell());
    content += getRawStringWithConversions(ifs, ifs.tell());
    result.content = content;
    
    result.idOverride = "battleblock-"
      + TStringConversion::intToString(subSectorNum,
          TStringConversion::baseHex)
      + "-"
      + TStringConversion::intToString(stringOffset,
          TStringConversion::baseHex);
//    result.genericLines.push_back(std::string("#SETSUBID(")
//      + TStringConversion::intToString(i)
//      + ")");
    
    for (unsigned int i = 0; i < it->second.size(); i++) {
      int id = it->second[i];
      result.pointerRefs.push_back(id);
    }
    
    strings.strings.push_back(result);
  }
}

int main(int argc, char* argv[]) {
  if (argc < 1) {
    cout << "Yuna 2 script generator" << endl;
//    cout << "Usage: " << argv[0] << " <outprefix>" << endl;
    cout << "Usage: " << argv[0] << endl;
    
    return 1;
  }
  
//  string outprefixName(argv[1]);

  TFileManip::createDirectory("script/orig");
  
  tableSjisUtf8.readUtf8("table/sjis_utf8_yuna2.tbl");
  
  TBufStream ifs;
  ifs.open("yuna2_02.iso");
  
  //========================================================================
  // main
  //========================================================================
  
  {
    Yuna2GenericStringSet strings;
    
    strings.addGenericLine("#SETFAILONBOXOVERFLOW(1)");
    
    //=======================================
    // read map scripts
    //=======================================
    
    for (int i = 0; i < numTextBlocks; i++) {
      dumpTextBlock(ifs, strings, i);
    }
    
    //=======================================
    // read adv module
    //=======================================
    
    Yuna2GenericStringSet extraStrings;
    
    TBufStream advifs;
    ifs.seek(0x2 * sectorSize);
    advifs.writeFrom(ifs, 0xC * sectorSize);
    
    //=======================================
    // hardcoded strings
    //=======================================
    
//    Yuna2GenericStringSet extraStrings;
//    extraStrings.addComment("Messages for retrying battle?");
    extraStrings.addSetRegion(-1);
    extraStrings.addGenericLine("#SETSIZE(216, 4)");
    
    extraStrings.addComment("Debug menu + leftovers");
    advifs.seek(0x96FB - 0x4000);
    for (int i = 0; i < 4; i++) {
      dumpGenericRawString(advifs, extraStrings, advifs.tell());
    }
    
    extraStrings.addComment("Save/load prompt");
    advifs.seek(0x456F - 0x4000);
    for (int i = 0; i < 2; i++) {
      dumpGenericRawString(advifs, extraStrings, advifs.tell());
    }
    
    extraStrings.addComment("No files");
    advifs.seek(0x8F9F - 0x4000);
    for (int i = 0; i < 1; i++) {
      dumpGenericRawString(advifs, extraStrings, advifs.tell());
    }
    
    extraStrings.addComment("File names");
    // the file/chapter numbers are written to hardcoded positions
    // within these extraStrings, so they can't be compressed
    extraStrings.addSetNotCompressible(1);
      advifs.seek(0x90AF - 0x4000);
      for (int i = 0; i < 2; i++) {
        dumpGenericRawString(advifs, extraStrings, advifs.tell());
  //      Yuna2GenericString str
  //        = getGenericString(advifs, advifs.tell());
      }
    extraStrings.addSetNotCompressible(0);
    
    extraStrings.addComment("Backup memory errors");
    advifs.seek(0x99DF - 0x4000);
    for (int i = 0; i < 6; i++) {
      dumpGenericRawString(advifs, extraStrings, advifs.tell());
    }

    Yuna2GenericString blankStr;
    blankStr.type = Yuna2GenericString::type_string;
    blankStr.offset = 0;
    blankStr.size = -1;
    
    extraStrings.addComment("Block 1 ask/listen hack");
    for (int i = 0; i < 1; i++) {
      std::string id = std::string("block1-listen-hack-content");
      blankStr.idOverride = id;
      extraStrings.strings.push_back(blankStr);
    }
    
    extraStrings.addComment("Star Bowl subtitles");
//    extraStrings.addSetRegion(-1);
    extraStrings.addGenericLine("#SETSIZE(240, 2)");
    extraStrings.addGenericLine("#SETSCENEMODE(1)");
    extraStrings.addGenericLine("#LOADTABLE(\"table/yuna2_scenes_en.tbl\")");
    extraStrings.addSetNotCompressible(1);

    for (int i = 0; i < 4; i++) {
      std::string id = std::string("starbowl")
        + TStringConversion::intToString(i);
      blankStr.idOverride = id;
      extraStrings.strings.push_back(blankStr);
    }
    
    extraStrings.addComment("Dark queen ending message subtitles");

    for (int i = 0; i < 4; i++) {
      std::string id = std::string("darkqueen")
        + TStringConversion::intToString(i);
      blankStr.idOverride = id;
      extraStrings.strings.push_back(blankStr);
    }
    
    extraStrings.addSetNotCompressible(0);
    extraStrings.addGenericLine("#SETSCENEMODE(0)");
    
    //=======================================
    // export
    //=======================================
    
//    scriptSheet.exportCsv("script/orig/script_main.csv");
    
//    for (int i = 0; i < 34; i++) {
    
    Yuna2TranslationSheet scriptSheet;
    
    std::ofstream ofs("script/orig/spec_main.txt");
//    std::ofstream extraOfs("script/orig/spec_main_misc.txt");
    strings.exportToSheet(scriptSheet, ofs, "");
//    extraStrings.exportToSheet(scriptSheet, extraOfs, "adv-");
    extraStrings.exportToSheet(scriptSheet, ofs, "adv-");
    scriptSheet.exportCsv("script/orig/script_main.csv");
  }
  
  //========================================================================
  // adv misc
  //========================================================================
  
/*  {
    Yuna2GenericStringSet strings;
    
    //=======================================
    // read adv module
    //=======================================
    
    TBufStream advifs;
    ifs.seek(0x2 * sectorSize);
    advifs.writeFrom(ifs, 0xC * sectorSize);
    
    //=======================================
    // hardcoded strings
    //=======================================
    
//    Yuna2GenericStringSet extraStrings;
//    extraStrings.addComment("Messages for retrying battle?");
    strings.addSetRegion(-1);
    
    strings.addComment("Debug menu + leftovers");
    advifs.seek(0x96FB - 0x4000);
    for (int i = 0; i < 4; i++) {
      dumpGenericRawString(advifs, strings, advifs.tell());
    }
    
    strings.addComment("Save/load prompt");
    
    strings.addComment("No files");
    advifs.seek(0x8F9F - 0x4000);
    for (int i = 0; i < 1; i++) {
      dumpGenericRawString(advifs, strings, advifs.tell());
    }
    
    strings.addComment("File names");
    // the file/chapter numbers are written to hardcoded positions
    // within these strings, so they can't be compressed
    strings.addSetNotCompressible(1);
      advifs.seek(0x90AF - 0x4000);
      for (int i = 0; i < 2; i++) {
        dumpGenericRawString(advifs, strings, advifs.tell());
  //      Yuna2GenericString str
  //        = getGenericString(advifs, advifs.tell());
      }
    strings.addSetNotCompressible(0);
    
    strings.addComment("Backup memory errors");
    advifs.seek(0x99DF - 0x4000);
    for (int i = 0; i < 6; i++) {
      dumpGenericRawString(advifs, strings, advifs.tell());
    }
    
    //=======================================
    // export
    //=======================================
    
    Yuna2TranslationSheet scriptSheet;
    
    std::ofstream ofs("script/orig/spec_adv.txt");
    std::ofstream extraOfs("script/orig/spec_adv.txt");
    
    strings.exportToSheet(scriptSheet, ofs, "adv-");
//    extraStrings.exportToSheet(scriptSheet, extraOfs, "battle-misc-");
    scriptSheet.exportCsv("script/orig/script_adv.csv");
  } */
  
  //========================================================================
  // battle
  //========================================================================
  
  {
    Yuna2GenericStringSet strings;
    
    strings.addGenericLine("#SETFAILONBOXOVERFLOW(1)");
    
    //=======================================
    // read battle module
    //=======================================
    
    TBufStream batifs;
    ifs.seek(0x10A * sectorSize);
    batifs.writeFrom(ifs, 0xA * sectorSize);
    
    //=======================================
    // read enemy/ally sector tables
    //=======================================
    
    std::map<int, int> combatPersonTables;
    
    // enemy
    batifs.seek(0x77B3 - 0x4000);
    for (int i = 0; i < 0x13; i++) {
      combatPersonTables[batifs.readu16le()] = 0;
    }
    
    // ally
    batifs.seek(0x77D9 - 0x4000);
    for (int i = 0; i < 0x13; i++) {
      combatPersonTables[batifs.readu16le()] = 0;
    }
    
    for (std::map<int, int>::iterator it = combatPersonTables.begin();
         it != combatPersonTables.end();
         ++it) {
      int sectorNum = it->first;
      ifs.seek(sectorNum * sectorSize);
      dumpBattlePerson(ifs, strings);
    }
    
    //=======================================
    // hardcoded strings
    //=======================================
    
    Yuna2GenericStringSet extraStrings;
//    extraStrings.addComment("Messages for retrying battle?");
    extraStrings.addSetRegion(-1);
    extraStrings.addGenericLine("#SETSIZE(216, 3)");
    
    extraStrings.addComment("Retry prompt (debug)");
    dumpGenericStringWithConversions(batifs, extraStrings, 0x6FF9 - 0x4000);
    
    extraStrings.addComment("Battle retry messages");
    {
/*      for (int i = 0; i < 0x30; i++) {
        batifs.seek((0x81F1 - 0x4000) + (i * 2));
        int ptr = batifs.readu16le();
        dumpGenericStringWithConversions(batifs, extraStrings, ptr - 0x4000);
      } */
      
      std::map<int, std::vector<int> > data;
      for (int i = 0; i < 0x30; i++) {
        batifs.seek((0x81F1 - 0x4000) + (i * 2));
        int ptr = batifs.readu16le();
        data[ptr].push_back(batifs.tell() - 2);
      }
      
      for (std::map<int, std::vector<int> >::iterator it = data.begin();
           it != data.end();
           ++it) {
        Yuna2GenericString str
          = getGenericConvString(batifs, it->first - 0x4000);
        for (unsigned int i = 0; i < it->second.size(); i++) {
          str.pointerRefs.push_back(it->second[i]);
        }
        extraStrings.strings.push_back(str);
      }
//      dumpGenericStringWithConversions(batifs, extraStrings, ptr - 0x4000);
    }
    
    //=======================================
    // export
    //=======================================
    
    Yuna2TranslationSheet scriptSheet;
    
    std::ofstream ofs("script/orig/spec_battle.txt");
//    std::ofstream extraOfs("script/orig/spec_battle_misc.txt");
    strings.exportToSheet(scriptSheet, ofs, "");
//    extraStrings.exportToSheet(scriptSheet, extraOfs, "battle-misc-");
    extraStrings.exportToSheet(scriptSheet, ofs, "battle-misc-");
    scriptSheet.exportCsv("script/orig/script_battle.csv");
  }
  
  //=======================================
  // add placeholders for new strings
  //=======================================
  
  {
    Yuna2GenericStringSet strings;
    
    strings.addGenericLine("#SETFAILONBOXOVERFLOW(1)");

    Yuna2GenericString blankStr;
    blankStr.type = Yuna2GenericString::type_string;
    blankStr.offset = 0;
    blankStr.size = -1;
        
//    strings.addComment("NEW: Ranks for Pom Community");
//    strings.strings.push_back(blankStr);
//    blankStr.offset++;
    strings.addSetRegion(-1);
    strings.addGenericLine("#SETSIZE(240, 4)");
    strings.addGenericLine("#SETSCENEMODE(1)");
//    strings.addGenericLine("#LOADTABLE(\"table/yuna2_scenes_en.tbl\")");

    for (int i = 0; i < 7; i++) {
      strings.addComment(std::string("Scene ")
        + TStringConversion::intToString(i));
      for (int j = 0; j < 100; j++) {
        std::string id = std::string("scene")
          + TStringConversion::intToString(i)
          + "-"
          + TStringConversion::intToString(j);
        blankStr.idOverride = id;
        strings.strings.push_back(blankStr);
      }
    }
    
    //=======================================
    // export
    //=======================================
    
    Yuna2TranslationSheet scriptSheet;
    
    std::ofstream ofs("script/orig/spec_scene.txt");
    strings.exportToSheet(scriptSheet, ofs, "");
//    extraStrings.exportToSheet(scriptSheet, ofs, "adv-");
    scriptSheet.exportCsv("script/orig/script_scene.csv");
  }
  
/*  tableScript.readSjis("table/pom.tbl");
  tableFixed.readSjis("table/pom_fixedstr.tbl");
  tableSjis.readSjis("table/sjis_pom.tbl");
  tableEnd.readSjis("table/pom_end.tbl");
  
  // main executable
  TBufStream mainifs;
  {
    // read exe, removing header so pointers match up correctly
    TBufStream tempifs;
    tempifs.open("disc/files/MAIN.EXE");
    tempifs.seek(0x800);
    mainifs.writeFrom(tempifs, tempifs.remaining());
  }
  
  // end credits executable
  TBufStream endifs;
  {
    // read exe, removing header so pointers match up correctly
    TBufStream tempifs;
    tempifs.open("disc/files/POM_END.EXE");
    tempifs.seek(0x800);
    endifs.writeFrom(tempifs, tempifs.remaining());
  }
  
//  TBufStream mapTestOfs;
  
  Yuna2TranslationSheet scriptSheet;
  
  //========================================================================
  // MAIN EXE
  //========================================================================
  
  {
//    mainifs.seek(mapDataOffsetTableAddr - mainExeLoadAddr);
    mainifs.seek(mapDataOffsetTableAddr - mainExeBaseAddr);
    
    TBufStream mapifs;
    mapifs.open("disc/files/GRAPHIC/MAP.PAK");
    
    //=======================================
    // read map scripts
    //=======================================
    
    Yuna2GenericStringSet strings;
    
    // DEBUG: enable automatic failure on dialogue box overflow
    // for standard map strings
    // (line wrapping is done dynamically in-game, so no need for this
    // once the static verification has been done)
    {
      Yuna2GenericString str;
      str.type = Yuna2GenericString::type_genericLine;
//      str.content = "#SETSIZE(192, 4)";
      str.content = "//#SETSIZE(200, 4)";
      strings.strings.push_back(str);
    }
    {
      Yuna2GenericString str;
      str.type = Yuna2GenericString::type_genericLine;
      str.content = "//#SETFAILONBOXOVERFLOW(1)";
      strings.strings.push_back(str);
    }
    
    for (unsigned int i = 0; i < numMaps; i++) {
      int mapOffset = mainifs.readu32le();
      
      mapifs.seek(mapOffset);
      Yuna2MapData mapData;
      mapData.read(mapifs);
      mapData.save(std::string("rsrc_raw/maps_decompressed/")
          + TStringConversion::intToString(i)
          + "/");
      
      mapifs.seek(mapOffset);
      Yuna2MapData mapDataCompressed;
      mapDataCompressed.read(mapifs, false);
      mapDataCompressed.save(std::string("rsrc_raw/maps/")
          + TStringConversion::intToString(i)
          + "/");
      
//      Yuna2MapData test;
//      test.load(mapOutDir);
//      test.save(std::string("rsrc_raw/mapstest/")
//          + TStringConversion::intToString(i)
//          + "/");
      
//      std::cout << std::hex << i << " " << mapData.resources.size()
//        << std::endl;
//      std::cout << std::hex << "map: " << i
//        << std::endl;

//      scriptSheet.addCommentEntry(std::string("Map ")
//        + TStringConversion::intToString(i));
      strings.addComment(std::string("Map ")
        + TStringConversion::intToString(i));
//      std::cerr << "map " << std::dec << i << std::endl;
      
      for (unsigned int j = 0; j < mapData.resources.size(); j++) {
        TArray<TByte>& data = mapData.resources[j];
        if ((data.size() >= 4)
            && (data[0] == 'P')
            && (data[1] == 'L')
            && (data[2] == 'M')) {
//          std::cout << "PLM" << data[3] << ": " << i << std::endl;
//          std::cout << std::hex << (int)data[0x10]
//            << " " << (int)data[0x11]
//            << " " << (int)data[0x12]
//            << " " << (int)data[0x13]
//            << std::endl;
          
          TBufStream ifs;
          ifs.write((char*)data.data(), data.size());
          ifs.seek(0);
          
//          TStringSearchResultList searchResults =
//            TStringSearch::searchFullStream(ifs, "48 09 01");
//          for (unsigned int i = 0; i < searchResults.size(); i++) {
//            std::cout << "arb sjis print: " << searchResults[i].offset << std::endl;
//          }
          
//          TStringSearchResultList searchResults =
//            TStringSearch::searchFullStream(ifs, "48 07 01");
//          for (unsigned int i = 0; i < searchResults.size(); i++) {
//            std::cout << "num print: " << searchResults[i].offset << std::endl;
//          }
          
//          TStringSearchResultList searchResults =
//            TStringSearch::searchFullStream(ifs, "48 06 01");
//          for (unsigned int i = 0; i < searchResults.size(); i++) {
//            std::cout << "cmd 106: " << searchResults[i].offset << std::endl;
//          }
          
          ifs.seek(0);
          
          std::string outFileName =
            std::string("testdata/mapscripts/map")
            + as2bHex(i)
            + "_"
            + as2bHex(j)
            + ".bin";
//          TFileManip::createDirectoryForFile(outFileName);
//          ifs.save(outFileName.c_str());
          
          Yuna2PlmStringScanResults scanResults;
          Yuna2PlmData::stringScan(ifs, tableScript, scanResults);
          
//          for (unsigned int k = 0; k < scanResults.results.size(); k++) {
//            std::string idString = "plm_"
//              + TStringConversion::intToString(i)
//              + "-"
//              + TStringConversion::intToString(j)
//              + "-"
//              + TStringConversion::intToString(k);
//            scriptSheet.addStringEntry(
//              idString, scanResults.results[k].content);
//          }
          
          Yuna2PlmScriptStringSet outputStrings;
          Yuna2PlmData::formOutputStrings(ifs, scanResults, outputStrings);
          
          {
            Yuna2GenericString str;
            str.type = Yuna2GenericString::type_setRegion;
            str.regionId = i;
            strings.strings.push_back(str);
          }
          
          {
            Yuna2GenericString str;
            str.type = Yuna2GenericString::type_setMap;
            str.mapMainId = i;
            str.mapSubId = j;
            strings.strings.push_back(str);
          }
          
          for (unsigned int k = 0; k < outputStrings.strings.size(); k++) {
            std::string idString = "plm_"
              + TStringConversion::intToString(i)
              + "-"
              + TStringConversion::intToString(j)
//              + "-"
//              + TStringConversion::intToString(k);
              + "-"
              + TStringConversion::intToString(
                  outputStrings.strings[k].origOffset,
                    TStringConversion::baseHex);
            
            Yuna2GenericString str;
            str.type = Yuna2GenericString::type_mapString;
            str.content = outputStrings.strings[k].content;
            str.offset = outputStrings.strings[k].origOffset;
            str.size = outputStrings.strings[k].origSize;
            str.idOverride = idString;
            str.scriptRefStart = outputStrings.strings[k].scriptRefStart;
            str.scriptRefEnd = outputStrings.strings[k].scriptRefEnd;
            str.scriptRefCode = outputStrings.strings[k].scriptRefStartCode;
            str.translationPlaceholder
              = outputStrings.strings[k].translationPlaceholder;
            strings.strings.push_back(str);
            
//            scriptSheet.addStringEntry(
//              idString, outputStrings.strings[k].content);
          }
        }
      }
    }
    
//    scriptSheet.exportCsv("script/orig/script_main.csv");
    
    std::ofstream ofs("script/orig/spec_main.txt");
    strings.exportToSheet(scriptSheet, ofs, "");
//    scriptSheet.exportCsv("script/orig/script_main.csv");
  }
  
  //=======================================
  // read hardcoded fixed strings
  //=======================================
  
  {
    Yuna2GenericStringSet strings;
//    strings.addString(mainifs, tableFixed,
//                      0x800112E8 - mainExeBaseAddr);
    
    strings.addComment("Location name labels");
    readGenericMainPtrTableRev(mainifs, strings, tableFixed,
                            0x1064E4, 0x1066EC);
    
    strings.addComment("Naming screen, save/load menus");
    readGenericMainPtrTableRev(mainifs, strings, tableFixed,
                            0x11502C - (11 * 4), 0x11502C);
    {
      Yuna2GenericString str;
      str.type = Yuna2GenericString::type_genericLine;
      str.content = "#SETSIZE(192, 3)";
      strings.strings.push_back(str);
    }
    readGenericMainPtrTableRev(mainifs, strings, tableFixed,
                            0x114FAC, 0x11502C - (11 * 4));
    {
      Yuna2GenericString str;
      str.type = Yuna2GenericString::type_genericLine;
      str.content = "#SETSIZE(-1, -1)";
      strings.strings.push_back(str);
    }
    
    
    strings.addComment("Default names for player-nameable stuff");
    strings.addSetNotCompressible(true);
    readGenericMainPtrTable(mainifs, strings, tableFixed,
                            0x11502C, 0x115074);
    strings.addSetNotCompressible(false);
    
//    Yuna2TranslationSheet scriptSheet;
    std::ofstream ofs("script/orig/spec_system.txt");
    strings.exportToSheet(scriptSheet, ofs, "system_");
//    scriptSheet.exportCsv("script/orig/script_system.csv");
  }
  
  //=======================================
  // read hardcoded SJIS strings
  //=======================================
  
  {
    Yuna2GenericStringSet strings;
    
    strings.addMarker("dict_section_start");
      strings.addComment("Item names");
      readGenericMainPtrTable(mainifs, strings, tableSjis,
                              0x1138F4, 0x113BDC);
    strings.addMarker("dict_section_end");
    
    strings.addComment("Yuna2 Community building names");
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x113BDC, 0x113C14);
    
    strings.addComment("Item descriptions and use messages");
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x113C14, 0x113F70);
    
    strings.addComment("Default Pom names + something");
    strings.addSetNotCompressible(true);
    for (int i = 0; i < 18; i++) {
//      strings.addString(mainifs, tableSjis,
//                        0x7A1D + (0x80 * i));
      strings.addOverwriteString(mainifs, tableSjis,
                        0x7A1D + (0x80 * i));
    }
    strings.addSetNotCompressible(false);
    
    strings.addComment("?");
//    strings.addString(mainifs, tableSjis,
//                      0x8418);
//    strings.addString(mainifs, tableSjis,
//                      0x8424);
    strings.addSetNotCompressible(true);
    strings.addOverwriteString(mainifs, tableSjis,
                      0x8418);
    strings.addOverwriteString(mainifs, tableSjis,
                      0x8424);
    strings.addSetNotCompressible(false);
    
    strings.addComment("Lulu default name (dupe, gets overwritten)");
//    strings.addString(mainifs, tableSjis,
//                      0x11BC84);
    strings.addSetNotCompressible(true);
    strings.addOverwriteString(mainifs, tableSjis,
                      0x11BC84);
    strings.addSetNotCompressible(false);
    
    strings.addComment("Pom occupations");
//    readGenericMainPtrTable(mainifs, strings, tableSjis,
//                            0x116278, 0x1162C0);
    // FIXME: the last entry in this table, 王様,
    // is in some way not valid.
    // it occupies memory that is overwritten with the last 4 bytes
    // of Lulu's name (max 12 bytes) during gameplay.
    // presumably, it is not used (or the game somehow gets away with it).
    // exclude for now.
//    readGenericMainPtrTable(mainifs, strings, tableSjis,
//                            0x116278, 0x1162BC);
    // the pointers at 0x1162A4 and 0x1162B0 correspond to overwrite strings.
    // we must not add them (otherwise, the strings will be both auto-inserted
    // and overwritten, with poor results)
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x116278, 0x1162A4);
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x1162A8, 0x1162B0);
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x1162B4, 0x1162BC);
    
//    strings.addComment("some building names for some reason...");
//    strings.addString(mainifs, tableSjis,
//                      0x9CC8);
//    strings.addString(mainifs, tableSjis,
//                      0x9CD4);
//    strings.addString(mainifs, tableSjis,
//                      0x9CE0);
//    strings.addString(mainifs, tableSjis,
//                      0x9CEC);
    
    strings.addComment("some building names and stuff...");
    for (int i = 0; i < 14; i++) {
      mainifs.seek(0x9BB0 + (i * 0x14));
      int offset = mainifs.readu32le() - mainExeBaseAddr;
      strings.addString(mainifs, tableSjis,
                        offset);
    }
    
    strings.addComment("Header for tip messages");
    strings.addString(mainifs, tableSjis,
                      0xA164);
    
    strings.addComment("Tip messages");
    strings.addString(mainifs, tableSjis,
                      0x115A28);
    strings.addString(mainifs, tableSjis,
                      0x115AB8);
    strings.addString(mainifs, tableSjis,
                      0x115B74);
    strings.addString(mainifs, tableSjis,
                      0x115BD0);
    strings.addString(mainifs, tableSjis,
                      0x115C60);
    strings.addString(mainifs, tableSjis,
                      0x115D0C);
    strings.addString(mainifs, tableSjis,
                      0x115D8C);
    strings.addString(mainifs, tableSjis,
                      0x115E3C);
    strings.addString(mainifs, tableSjis,
                      0x115E98);
    strings.addString(mainifs, tableSjis,
                      0x115F50);
    strings.addString(mainifs, tableSjis,
                      0x115FB4);
    
    strings.addComment("Game over menu");
    readGenericMainPtrTable(mainifs, strings, tableSjis,
                            0x1064CC, 0x1064E4);
    
//    Yuna2TranslationSheet scriptSheet;
    std::ofstream ofs("script/orig/spec_sjis.txt");
    strings.exportToSheet(scriptSheet, ofs, "sjis_");
//    scriptSheet.exportCsv("script/orig/script_sjis.csv");
  }
  
  //=======================================
  // add placeholders for new strings
  //=======================================
  
  {
    Yuna2GenericStringSet strings;

    Yuna2GenericString blankStr;
    blankStr.type = Yuna2GenericString::type_string;
    blankStr.offset = 0;
    blankStr.size = -1;
        
    strings.addComment("NEW: Ranks for Pom Community");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
        
    strings.addComment("NEW: pluralizing suffix for trading cards");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
        
    strings.addComment("NEW: game over message");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
        
    strings.addComment("NEW: extra name screen strings");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
        
    strings.addComment("NEW: name screen confirmation concat strings");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
        
    strings.addComment("NEW: inventory plural messages");
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    strings.strings.push_back(blankStr);
    blankStr.offset++;
    
//    Yuna2TranslationSheet scriptSheet;
    std::ofstream ofs("script/orig/spec_new.txt");
    strings.exportToSheet(scriptSheet, ofs, "new_");
  }
  
  //========================================================================
  // ENDING CREDITS
  //========================================================================
  
  //=======================================
  // existing content
  //=======================================
  
  {
    Yuna2GenericStringSet strings;
        
    strings.addComment("ending credits");
    
    endifs.seek(0x14);
    readGenericStringBlockPtrOvr(endifs, strings, tableEnd,
                           0x14, 0xA10);
    readGenericStringBlockPtrOvr(endifs, strings, tableEnd,
                           0x1AE28, 0x1AEE8);
    
    std::ofstream ofs("script/orig/spec_end.txt");
    strings.exportToSheet(scriptSheet, ofs, "end_");
  }
  
  //=======================================
  // add placeholders for new strings
  //=======================================
  
  {
    Yuna2GenericStringSet strings;

    Yuna2GenericString blankStr;
    blankStr.type = Yuna2GenericString::type_string;
    blankStr.offset = 0;
    blankStr.size = -1;
        
    strings.addComment("NEW: placeholders for new credits strings");
    
    for (int i = 0; i < 32; i++) {
      strings.strings.push_back(blankStr);
      blankStr.offset++;
    }
    
//    Yuna2TranslationSheet scriptSheet;
    std::ofstream ofs("script/orig/spec_endnew.txt");
    strings.exportToSheet(scriptSheet, ofs, "endnew_");
  }
  
//  mapTestOfs.save("test_map.bin");
  
//  scriptSheet.exportCsv("script/orig/script_main.csv");
  scriptSheet.exportCsv("script/orig/pom_script.csv"); */
  
  return 0;
}
