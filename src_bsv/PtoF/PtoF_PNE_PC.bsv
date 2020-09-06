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

package PtoF_PNE_PC;

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
import PtoF_Extracter ::*;
import PtoF_Types	:: *;
import Extracter_Types	:: *;

interface PtoF_PNE ;
   interface Server #(Output_posit,Output_float) compute;
endinterface

module mkPtoF_PNE(PtoF_PNE);

FIFO #(Bit#(FloatWidth)) ffO <- mkFIFO;
PtoF_IFC  ptoF <- mkPtoF_Extracter;

rule rl_out;
   let ptoFOut <- ptoF.inoutifc.response.get ();
   ffO.enq(ptoFOut);
endrule
interface Server compute;
      interface Put request;
         method Action put (Output_posit p);
		ptoF.inoutifc.request.put(p); 
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface
endmodule

endpackage: PtoF_PNE_PC
