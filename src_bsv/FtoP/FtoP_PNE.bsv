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

package FtoP_PNE;

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
import FtoP_Extracter ::*;
import FtoP_Types	:: *;
import Normalizer_Types	:: *;
import Normalizer	:: *;

interface FtoP_PNE ;
   interface Server #(Bit#(FloatWidth),Output_posit_n) compute;
endinterface

module mkFtoP_PNE(FtoP_PNE);

FIFO #(Bit#(FloatWidth)) ffI <- mkFIFO;
FIFO #(Output_posit_n) ffO <- mkFIFO;
FtoP_IFC  fToP <- mkFtoP_Extracter;
Normalizer_IFC   normalizer <- mkNormalizer;

rule rl_in;
	fToP.inoutifc.request.put(ffI.first); 
	ffI.deq;
endrule

rule rl_connect;
   let fToPOut <- fToP.inoutifc.response.get ();
   normalizer.inoutifc.request.put (fToPOut);
endrule

rule rl_out;
   let normOut <- normalizer.inoutifc.response.get ();
   ffO.enq(normOut);
endrule
interface compute = toGPServer (ffI,ffO);
endmodule

(* synthesize *)

module mkFtoP_PNE_test (FtoP_PNE );
   let _ifc <- mkFtoP_PNE;
   return (_ifc);
endmodule
endpackage: FtoP_PNE
