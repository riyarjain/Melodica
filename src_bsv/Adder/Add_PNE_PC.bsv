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


package Add_PNE_PC;

// -----------------------------------------------------------------
// This package defines:
//
//    The different artefacts your package defines. One per line
//    with a small description per line, please.
//
// -----------------------------------------------------------------

import ClientServer     :: *;
import GetPut           :: *;
import FIFO             :: *;
import Extracter_Types	:: *;
import Normalizer_Types	:: *;
import Adder_Types	:: *;
import Adder		:: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
interface Add_PNE ;
   interface Server #(InputTwoExtractPosit,Input_value_n) compute;
endinterface

//
// Module definition
module mkAdd_PNE (Add_PNE );
FIFO #(Input_value_n) ffO <- mkFIFO;
Adder_IFC  adder1 <- mkAdder;

rule rl_connect2;
   let addOut1 <- adder1.inoutifc.response.get();
   ffO.enq(Input_value_n {
	sign: addOut1.sign,
 	zero_infinity_flag: addOut1.zero_infinity_flag ,
	nan_flag: addOut1.nan_flag,
	scale :  pack(addOut1.scale),
	frac : addOut1.frac,
	truncated_frac_msb : addOut1.truncated_frac_msb,
	truncated_frac_zero : addOut1.truncated_frac_zero});
endrule

interface Server compute;
      interface Put request;
         method Action put (InputTwoExtractPosit p);
		let extOut1 = p.posit_inp_e1;
		let extOut2 = p.posit_inp_e2;
		adder1.inoutifc.request.put (Inputs_a {
			sign1: extOut1.sign,
			nanflag1: 1'b0,
		 	zero_infinity_flag1: extOut1.zero_infinity_flag ,
			scale1 : extOut1.scale,
			frac1 : extOut1.frac ,
			sign2: extOut2.sign,
			nanflag2: 1'b0,
		 	zero_infinity_flag2: extOut2.zero_infinity_flag ,
			scale2 : extOut2.scale,
			frac2 : extOut2.frac});
			ffI.deq;
         endmethod
      endinterface
      interface Get response = toGet (ffO);
   endinterface

endmodule

endpackage

// -----------------------------------------------------------------


