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

package PNE;

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
import Extracter	:: *;
import Normalizer	:: *;
import Divider	:: *;
import Extracter_Types	:: *;
import Normalizer_Types	:: *;
import Divider_Types	:: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Utils :: *;

interface PNE ;
   interface Server #(InputTwoPosit,Output_posit_n) compute;
endinterface



//
// Module definition
module mkPNE (PNE );
FIFO #(Output_posit_n) ffO <- mkFIFO;
FIFO #(Output_posit) ffm <- mkFIFO;
// Extractor
Extracter_IFC  extracter1 <- mkExtracter;
Extracter_IFC  extracter2 <- mkExtracter;
Divider_IFC  divider <- mkDivider;
Normalizer_IFC   normalizer <- mkNormalizer;


rule rl_connect0;
   let extOut1 <- extracter1.inoutifc.response.get();
   let extOut2 <- extracter2.inoutifc.response.get();
   divider.inoutifc.request.put (Inputs_d {
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
endrule

rule rl_connect2;
   let divOut <- divider.inoutifc.response.get();
   normalizer.inoutifc.request.put (Input_value_n {
	sign: divOut.sign,
 	zero_infinity_flag: divOut.zero_infinity_flag ,
	nan_flag: divOut.nan_flag,
	scale :  pack(divOut.scale),
	frac : divOut.frac,
	truncated_frac_msb : divOut.truncated_frac_msb,
	truncated_frac_zero : divOut.truncated_frac_zero});
endrule


rule rl_out;
   let normOut <- normalizer.inoutifc.response.get ();
   ffO.enq(normOut);
endrule


interface Server compute;
      interface Put request;
         method Action put (InputTwoPosit p);
		let in_posit1 = Input_posit {posit_inp : p.posit_inp1};
   		extracter1.inoutifc.request.put (in_posit1);
   		let in_posit2 = Input_posit {posit_inp : p.posit_inp2};
   		extracter2.inoutifc.request.put (in_posit2);
         endmethod
      endinterface
      interface Get response = toGet (ffO);
   endinterface

endmodule

(* synthesize *)

module mkPNE_test (PNE );
   let _ifc <- mkPNE;
   return (_ifc);
endmodule

endpackage

// -----------------------------------------------------------------


