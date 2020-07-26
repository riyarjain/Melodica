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

//ouput of adder is QUireWidth.. that is directly connected to output
package FMA_PNE_Quire;

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
import Extracter_Types	:: *;
import Extracter	:: *;
import Normalizer_Types	:: *;
import Normalizer	:: *;
import Adder_Types_fused_op 	:: *;
import Adder_fused_op		:: *;
import Multiplier_Types_fma	:: *;
import Multiplier_fma	:: *;
import Common_Fused_Op :: *;

interface FMA_PNE_Quire ;
   interface Server #(InputQuireTwoPosit,Bit#(QuireWidth)) compute;
endinterface

module mkFMA_PNE_Quire(FMA_PNE_Quire);
FIFO #(Bit#(QuireWidth)) ffO <- mkFIFO;
FIFO #(Bit#(QuireWidth)) fftemp <- mkFIFO;
Extracter_IFC  extracter1 <- mkExtracter;
Extracter_IFC  extracter2 <- mkExtracter;
Multiplier_IFC  multiplier <- mkMultiplier;
Adder_IFC  adder <- mkAdder;
//get their extracted value and semd to multiply
rule rl_connect0;
   	let extOut1 <- extracter1.inoutifc.response.get();
   	let extOut2 <- extracter2.inoutifc.response.get();
	multiplier.inoutifc.request.put (Inputs_md {
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
	// the fraction and scale are extended since operation is on quire
	//using signed extension for scale value
	//fraction value is normally extended but also shifted to maked the MSB the highest valued fraction bit
endrule
//get the multiply pipeline output and send to adder pipeline
rule rl_connect1;
   	let mulOut <- multiplier.inoutifc.response.get();
   	let in_quire = fftemp.first;

	adder.inoutifc.request.put(Inputs_a{q1 : Quire{sign : msb(in_quire),
						    zero_infinity_flag : REGULAR,
						    nan_flag : 1'b0,
						    carry_int_frac : in_quire[valueOf(QuireWidthMinus2):0]} , q2 : mulOut}); 
	fftemp.deq;
endrule
//get output from adder pipeline and send to Testbench
rule rl_out;
	let addOut <- adder.inoutifc.response.get ();
		ffO.enq(addOut);
endrule
interface Server compute;
      interface Put request;
         method Action put (InputQuireTwoPosit p);
		let in_quire = p.quire_inp;
		let in_posit1 = Input_posit {posit_inp : p.posit_inp1};
	   	extracter1.inoutifc.request.put (in_posit1);
	   	let in_posit2 = Input_posit {posit_inp : p.posit_inp2};
	   	extracter2.inoutifc.request.put (in_posit2);
		fftemp.enq(in_quire);
         endmethod
      endinterface
   interface Get response = toGet (ffO);
endinterface
endmodule

(* synthesize *)
module mkPNE_test (FMA_PNE_Quire);
   let _ifc <- mkFMA_PNE_Quire;
   return (_ifc);
endmodule
endpackage: FMA_PNE_Quire
