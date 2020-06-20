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

package QuireToPosit_PNE_PC;

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
import QuireToPosit_PC ::*;
import QtoP_Types	:: *;
import Normalizer_Types	:: *;
import Normalizer	:: *;

interface QuireToPosit_PNE ;
   interface Server #(Bit#(0),Input_value_n) compute;
endinterface

module mkQuireToPosit_PNE #(Reg #(Bit#(QuireWidth)) rg_quire)(QuireToPosit_PNE);

//FIFO #(Bit#(QuireWidth)) ffI <- mkFIFO;
FIFO #(Input_value_n) ffO <- mkFIFO;
QuireToPosit_IFC  quireToPosit1 <- mkQuireToPosit(rg_quire);
rule rl_out;
   let qToPOut <- quireToPosit1.inoutifc.response.get ();
   ffO.enq(qToPOut);
endrule
interface Server compute;
      interface Put request;
         method Action put (Bit#(0) p);
		let in_quire = rg_quire;
		quireToPosit1.inoutifc.request.put(?); 
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface
endmodule


endpackage: QuireToPosit_PNE_PC
