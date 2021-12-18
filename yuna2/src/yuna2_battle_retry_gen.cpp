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

string asHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
//  while (str.size() < 3) str = string("0") + str;
  
  return str;
}

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Yuna 2 battle retry string pointer table generator" << endl;
    cout << "Usage: " << argv[0] << " <infile>"
      << endl;
    return 0;
  }
  
  string inFile = string(argv[1]);
  
  TBufStream ifs;
  ifs.open(inFile.c_str());
  
  ifs.seek(0x81F1 - 0x4000);
  for (int i = 0; i < 0x30; i++) {
    if ((i % 4) == 0) {
      cout << endl;
      cout << "  ; group " << i / 4 << endl;
    }
    
    int ptr = ifs.readu16le();
    cout << "  .dw battleRetryStr" << asHex(ptr) << endl;
  }
  
  return 0;
}

