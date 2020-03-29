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
import PositToQuire ::*;
import PtoQ_Types	:: *;
import Extracter_Types :: *;

interface PositToQuire_PNE ;
   interface Server #(Output_posit,Bit#(0)) compute;
endinterface

module mkPositToQuire_PNE #(Reg #(Bit#(QuireWidth))  rg_quire)(PositToQuire_PNE);

//FIFO #(Bit#(QuireWidth)) ffO <- mkFIFO;
FIFOF #(Bit#(0)) ffO <- mkFIFOF;
FIFO #(Output_posit) ffI <- mkFIFO;
PositToQuire_IFC  positToquire <- mkPositToQuire;
rule rl_in;
	positToquire.inoutifc.request.put(ffI.first); 
	ffI.deq;
endrule

rule rl_out;
   let ptoqOut <- positToquire.inoutifc.response.get ();
	rg_quire <= ptoqOut;
   ffO.enq(?);
endrule
interface compute = toGPServer (ffI,ffO);
endmodule

endpackage: PositToQuire_PNE_PC
