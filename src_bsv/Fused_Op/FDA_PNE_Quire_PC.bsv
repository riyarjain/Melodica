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
package FDA_PNE_Quire_PC;

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
import Normalizer_Types	:: *;
import Adder_Types_fused_op_PC 	:: *;
import Adder_fused_op_PC	:: *;
import Divider_Types_fda	:: *;
import Divider_fda	:: *;
import Common_Fused_Op :: *;

interface FDA_PNE_Quire ;
   interface Server #(InputTwoExtractPosit, Bit#(0)) compute;
endinterface

module mkFDA_PNE_Quire #(Reg #(Bit#(QuireWidth)) rg_quire)(FDA_PNE_Quire);

//FIFO #(Bit#(QuireWidth)) ffO <- mkFIFO;
FIFOF #(Bit#(0)) ffO <- mkFIFOF;
FIFO #(InputTwoExtractPosit) ffI <- mkFIFO;
//FIFO #(Bit#(QuireWidth)) fftemp <- mkFIFO;
Divider_IFC  divider <- mkDivider;
Adder_IFC  adder <- mkAdder(rg_quire);
Reg #(Bit#(1)) check_quire <- mkReg(0);
//get their extracted value and semd to multiply
rule rl_connect0;
   	let extOut1 = ffI.first.posit_inp_e1;
   	let extOut2 = ffI.first.posit_inp_e2;
	divider.inoutifc.request.put (Inputs_md {
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
	ffI.deq;
	// the fraction and scale are extended since operation is on quire
	//using signed extension for scale value
	//fraction value is normally extended but also shifted to maked the MSB the highest valued fraction bit
endrule
//get the multiply pipeline output and send to adder pipeline
rule rl_connect1(check_quire == 1'b0);
   	let divOut <- divider.inoutifc.response.get();
	adder.inoutifc.request.put(Inputs_a{q2 : divOut}); 
	check_quire <= 1'b1;
endrule
//get output from adder pipeline and send to Testbench
rule rl_out;
	let addOut <- adder.inoutifc.response.get();
	check_quire <= 1'b0;
	ffO.enq(?);
endrule
interface compute = toGPServer (ffI,ffO);
endmodule

endpackage: FDA_PNE_Quire_PC
