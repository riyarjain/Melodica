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

package QuireToPosit_PNE;

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
import QuireToPosit ::*;
import QtoP_Types	:: *;
import Normalizer_Types	:: *;
import Normalizer	:: *;

interface QuireToPosit_PNE ;
   interface Server #(Bit#(QuireWidth),Output_posit_n) compute;
endinterface

module mkQuireToPosit_PNE(QuireToPosit_PNE);

FIFO #(Output_posit_n) ffO <- mkFIFO;
QuireToPosit_IFC  quireToPosit1 <- mkQuireToPosit;
Normalizer_IFC   normalizer <- mkNormalizer;

rule rl_connect;
   let qToPOut <- quireToPosit1.inoutifc.response.get ();
    normalizer.inoutifc.request.put (qToPOut);
endrule

rule rl_out;
   let normOut <- normalizer.inoutifc.response.get ();
   ffO.enq(normOut);
endrule
interface Server compute;
      interface Put request;
         method Action put (Bit#(QuireWidth) p);
		let in_quire = p;
		quireToPosit1.inoutifc.request.put(Quire{sign : msb(in_quire),
						    zero_infinity_flag : REGULAR,
						    nan_flag : 1'b0,
						    carry_int_frac : in_quire[valueOf(QuireWidthMinus2):0]}); 
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface
endmodule

(* synthesize *)

module mkPNE_test (QuireToPosit_PNE );
   let _ifc <- mkQuireToPosit_PNE;
   return (_ifc);
endmodule
endpackage: QuireToPosit_PNE
