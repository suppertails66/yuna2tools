#include "yuna2/Yuna2ScriptOp.h"
#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TByte.h"
#include "util/TParse.h"
#include "exception/TGenericException.h"
#include <vector>
#include <map>
#include <cctype>
#include <iostream>
#include <fstream>

using namespace BlackT;

namespace Pce {


Yuna2ScriptOp::Yuna2ScriptOp()
  : opcode(0xFF),
    unknown(0xFF),
    stackArgFlags(0x00),
    offset(-1) { }

void Yuna2ScriptOp::read(BlackT::TStream& ifs) {
  params.clear();

  opcode = ifs.readu8();
  if (opcode >= 0x54) {
    throw TGenericException(T_SRCANDLINE,
                            "Yuna2ScriptOp::read()",
                            std::string("Illegal opcode ")
                            + TStringConversion::intToString(opcode,
                                TStringConversion::baseHex)
                            + " at offset "
                            + TStringConversion::intToString(ifs.tell(),
                                TStringConversion::baseHex));
  }
  
  int paramCount = (ifs.readu8() & 0xF0) >> 4;
  unknown = ifs.readu8();
  stackArgFlags = ifs.readu8();
  
  for (int i = 0; i < paramCount; i++) {
    params.push_back(ifs.readu16le());
  }
}


}
