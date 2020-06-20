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
// THE SOFTWARE.package Extracter_Types;

package Mul_PNE_PC;

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
import Multiplier	:: *;
import Extracter_Types	:: *;
import Normalizer_Types	:: *;
import Multiplier_Types	:: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;

interface Mul_PNE ;
   interface Server #(InputTwoExtractPosit,Input_value_n) compute;
endinterface



//
// Module definition
module mkMul_PNE (Mul_PNE );
FIFO #(Input_value_n) ffO <- mkFIFO;
// Extractor
Multiplier_IFC  multiplier <- mkMultiplier;

rule rl_connect2;
   let mulOut <- multiplier.inoutifc.response.get();
   ffO.enq(Input_value_n {
	sign: mulOut.sign,
 	zero_infinity_flag: mulOut.zero_infinity_flag ,
	nan_flag: mulOut.nan_flag,
	scale :  pack(mulOut.scale),
	frac : mulOut.frac,
	truncated_frac_msb : mulOut.truncated_frac_msb,
	truncated_frac_zero : mulOut.truncated_frac_zero});
endrule

interface Server compute;
      interface Put request;
         method Action put (InputTwoExtractPosit p);
		let extOut1 = p.posit_inp_e1;
		   let extOut2 = p.posit_inp_e2;
		   multiplier.inoutifc.request.put (Inputs_m {
			sign1: extOut1.sign,
			nanflag1: 1'b0,
		 	zero_infinity_flag1: extOut1.zero_infinity_flag ,
			scale1 : extOut1.scale,
			frac1 : extOut1.frac,
			sign2: extOut2.sign,
			nanflag2: 1'b0,
		 	zero_infinity_flag2: extOut2.zero_infinity_flag ,
			scale2 : extOut2.scale,
			frac2 : extOut2.frac});
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface


endmodule
endpackage

// -----------------------------------------------------------------


