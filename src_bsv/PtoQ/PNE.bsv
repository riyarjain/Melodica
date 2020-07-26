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

package PositToQuire_PNE;
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
import Extracter ::*;

interface PositToQuire_PNE ;
   interface Server #(Bit#(PositWidth),Bit#(QuireWidth)) compute;
endinterface

module mkPositToQuire_PNE(PositToQuire_PNE);
Extracter_IFC   extracter <- mkExtracter;
FIFO #(Bit#(QuireWidth)) ffO <- mkFIFO;
PositToQuire_IFC  positToquire <- mkPositToQuire;

rule rl_connect0;
   	let extOut1 <- extracter.inoutifc.response.get();
	positToquire.inoutifc.request.put(extOut1); 
endrule

rule rl_out;
   let pToqOut <- positToquire.inoutifc.response.get ();
   ffO.enq(pToqOut);
endrule
interface Server compute;
      interface Put request;
         method Action put (Bit#(PositWidth) p);
		let in_posit1 = Input_posit {posit_inp : p};
   		extracter.inoutifc.request.put (in_posit1);
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface

endmodule

(* synthesize *)

module mkPNE_test (PositToQuire_PNE );
   let _ifc <- mkPositToQuire_PNE;
   return (_ifc);
endmodule
endpackage: PositToQuire_PNE
