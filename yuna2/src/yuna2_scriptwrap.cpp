//#include "psx/PsxPalette.h"
#include "yuna2/Yuna2ScriptReader.h"
#include "yuna2/Yuna2LineWrapper.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include <cctype>
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <fstream>

//const static int textCharsStart = 0x10;

using namespace std;
using namespace BlackT;
using namespace Pce;

TThingyTable table;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Yuna 2 script wrapper" << endl;
    cout << "Usage: " << argv[0] << " <infile> <outfile>"
      << " [tablefile] [widthfile] [textcharsstart]" << endl;
    return 0;
  }
  
  string infile = string(argv[1]);
  string outfile = string(argv[2]);
  
  string tableName = "table/yuna2_en.tbl";
  if (argc >= 4) tableName = string(argv[3]);
  
  string fontWidthFileName = "out/font/fontwidth.bin";
  if (argc >= 5) fontWidthFileName = string(argv[4]);
  
  int textCharsStart = 0x10;
  if (argc >= 6)
    textCharsStart = TStringConversion::stringToInt(string(argv[5]));
  
  TThingyTable table;
//  table.readSjis(tableName.c_str());
  table.readUtf8(tableName.c_str());
  
  // wrap script
  {
    // read size table
    Yuna2LineWrapper::CharSizeTable sizeTable;
    {
      TBufStream ifs;
      ifs.open(fontWidthFileName.c_str());
      int pos = 0;
      while (!ifs.eof()) {
        sizeTable[textCharsStart + (pos++)] = ifs.readu8();
      }
    }
    
    {
      TBufStream ifs;
      ifs.open((infile).c_str());
      
      TLineWrapper::ResultCollection results;
      Yuna2LineWrapper(ifs, results, table, sizeTable)();
      
      if (results.size() > 0) {
        TOfstream ofs(outfile.c_str());
        for (int i = 0; i < results.size(); i++) {
          ofs.write(results[i].str.c_str(), results[i].str.size());
        }
      }
    }
  }
  
  return 0;
}

