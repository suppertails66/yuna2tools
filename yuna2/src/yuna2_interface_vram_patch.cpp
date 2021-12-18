#include "yuna2/Yuna2Cmp.h"
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

using namespace std;
using namespace BlackT;
using namespace Pce;

int boxNumLines = 4;
int boxNumPatternRows = boxNumLines * 2;
int boxTilemapDataBaseOffset = 0x19C4;
int boxPatternsPerLine = 0x1B+1;
int boxTilemapDataRowByteSep = 0x80;
int boxBaseTile = 0x6E0;
int boxPatternPalette = 0xF;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Yuna 2 interface VRAM patcher" << endl;
    cout << "Usage: " << argv[0] << " <infile> <outfile>"
      << endl;
    return 0;
  }
  
  string inFile = string(argv[1]);
  string outFile = string(argv[2]);
  
  TBufStream ifs;
  ifs.open(inFile.c_str());
  
  ifs.seek(boxTilemapDataBaseOffset);
  for (int i = 0; i < boxNumPatternRows; i++) {
    ifs.seek(boxTilemapDataBaseOffset + (i * boxTilemapDataRowByteSep));
    for (int j = 0; j < boxPatternsPerLine; j++) {
      int tileId = (boxBaseTile + (i * boxPatternsPerLine) + j);
      tileId |= (boxPatternPalette << 12);
      ifs.writeu16le(tileId);
    }
  }
  
  ifs.save(outFile.c_str());
  
  return 0;
}

