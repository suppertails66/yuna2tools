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

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Yuna 2 bitstream compressor" << endl;
    cout << "Usage: " << argv[0] << " <infile> <outfile>"
      << endl;
    return 0;
  }
  
  string inFile = string(argv[1]);
  string outFile = string(argv[2]);
  
  TBufStream ifs;
  ifs.open(inFile.c_str());
  TBufStream ofs;
  Yuna2Cmp::cmpBitstream(ifs, ofs);
  ofs.save(outFile.c_str());
  
  return 0;
}

