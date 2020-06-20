// Copyright (c) HPC Lab, Department of Electrical Engineering, IIT Bombay
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package PositToQuire_PNE_PC;
// -----------------------------------------------------------------
// This package defines:
//
//    The different artefacts your package defines. One per line
//    with a small description per line, please.
//
// -----------------------------------------------------------------
import FIFOF        :: *;
import FIFO        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import PositToQuire_PC ::*;
import PtoQ_Types	:: *;
import Extracter_Types :: *;

interface PositToQuire_PNE ;
   interface Server #(Output_posit,Bit#(0)) compute;
endinterface

module mkPositToQuire_PNE #(Reg #(Bit#(QuireWidth))  rg_quire)(PositToQuire_PNE);

//FIFO #(Bit#(QuireWidth)) ffO <- mkFIFO;
FIFOF #(Bit#(0)) ffO <- mkFIFOF;
PositToQuire_IFC  positToquire <- mkPositToQuire(rg_quire);
rule rl_out;
   let ptoqOut <- positToquire.inoutifc.response.get ();
   ffO.enq(?);
endrule
interface Server compute;
      interface Put request;
         method Action put (Output_posit p);
		positToquire.inoutifc.request.put(p); 
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface

endmodule

endpackage: PositToQuire_PNE_PC
