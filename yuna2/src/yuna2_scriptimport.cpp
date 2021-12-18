#include "yuna2/Yuna2TranslationSheet.h"
//#include "psx/PsxPalette.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TFileManip.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TParse.h"
#include "util/TThingyTable.h"
#include <string>
#include <iostream>
#include <sstream>

using namespace std;
using namespace BlackT;
using namespace Pce;

Yuna2TranslationSheet scriptSheet;
//TThingyTable tableStd;

// HACK: we had *immense* difficulty deciding on a pom speech tic
// look for these tags in brackets (i.e. "[Myo]"/"[myo]")
//const std::string pomTicMarkerUpper = "Myo";
//const std::string pomTicMarkerLower = "myo";
// and substitute them for these without the brackets
//const std::string pomTicUpper = "Myo";
//const std::string pomTicLower = "myo";

std::string getNumStr(int num) {
  std::string str = TStringConversion::intToString(num);
  while (str.size() < 2) str = string("0") + str;
  return str;
}

std::string getHexWordNumStr(int num) {
  std::string str = TStringConversion::intToString(num,
    TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 4) str = string("0") + str;
  return string("$") + str;
}

/*std::string doSubstitutions(std::string str) {
  TBufStream ifs;
  ifs.writeString(str);
  ifs.seek(0);
  
  std::ostringstream ofs;
  while (!ifs.eof()) {
    char next = ifs.get();
    if (next == '[') {
      int basePos = ifs.tell();
      std::string value;
      bool valid = false;
      while (!ifs.eof())  {
        char nextnext = ifs.get();
        if (nextnext == ']') {
          valid = true;
          break;
        }
        value += nextnext;
      }
      
      if (!valid) {
        ofs.put(next);
        ifs.seek(basePos);
        continue;
      }
      
      if (value.compare(pomTicMarkerUpper) == 0) {
        ofs << pomTicUpper;
      }
      else if (value.compare(pomTicMarkerLower) == 0) {
        ofs << pomTicLower;
      }
      else {
        ofs.put(next);
        ifs.seek(basePos);
      }
    }
    else {
      ofs.put(next);
    }
  }
  
  return ofs.str();
} */

void importScript(string basename, bool substitutionsOn = false) {
  TBufStream ifs;
  ifs.open((string("script/") + basename).c_str());
  
  TBufStream ofs;
  while (!ifs.eof()) {
    std::string line;
    ifs.getLine(line);
    
    TBufStream lineIfs;
    lineIfs.writeString(line);
    lineIfs.seek(0);
    
    bool success = false;
    
    TParse::skipSpace(lineIfs);
    if (TParse::checkChar(lineIfs, '#')) {
      TParse::matchChar(lineIfs, '#');
      
      std::string name = TParse::matchName(lineIfs);
      TParse::matchChar(lineIfs, '(');
      
      for (unsigned int i = 0; i < name.size(); i++) {
        name[i] = toupper(name[i]);
      }
      
      if (name.compare("IMPORT") == 0) {
        std::string id = TParse::matchString(lineIfs);
//        cerr << id << endl;
        
        Yuna2TranslationSheetEntry str = scriptSheet.getStringEntryById(id);
        
//        if (substitutionsOn) {
//          str.stringContent = doSubstitutions(str.stringContent);
//        }
        
        // HACK: ignore "empty" cells for now
        if (!str.stringContent.empty()) {
          ofs.writeString(str.stringPrefix);
          ofs.put('\n');
          ofs.writeString(str.stringContent);
          ofs.put('\n');
          ofs.writeString(str.stringSuffix);
          ofs.put('\n');
        }
        
        TParse::matchChar(lineIfs, ')');
        success = true;
      }
    }
    
    if (!success) {
      ofs.writeString(line);
      ofs.put('\n');
    }
  }
  
  std::string outname = (string("out/scripttxt/") + basename).c_str();
  TFileManip::createDirectoryForFile(outname.c_str());
  ofs.save(outname.c_str());
}

int main(int argc, char* argv[]) {
  if (argc < 1) {
    cout << "Yuna 2 script importer" << endl;
    cout << "Usage: " << argv[0]
      << endl;
    return 0;
  }
  
  scriptSheet = Yuna2TranslationSheet();
//  scriptSheet.importCsv("script/script_main.csv");
  scriptSheet.importCsv("script/script_main.csv");
  importScript("spec_main.txt");
  
  scriptSheet = Yuna2TranslationSheet();
//  scriptSheet.importCsv("script/script_system.csv");
  scriptSheet.importCsv("script/script_battle.csv");
  importScript("spec_battle.txt");
  
  scriptSheet = Yuna2TranslationSheet();
  scriptSheet.importCsv("script/script_scene.csv");
  importScript("spec_scene.txt");
  
  return 0;
}
