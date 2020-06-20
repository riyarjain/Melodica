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

package Adder_fused_op;

// --------------------------------------------------------------
// This package defines:
//
//    mkAdder: 3-stage adder which computes the sum of 2 posits
// --------------------------------------------------------------

// Library imports
import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Adder_Types_fused_op :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Multiplier_Types_fma ::*;
import Common_Fused_Op :: *;

module mkAdder (Adder_IFC );
   	FIFOF #(Stage0_a )  fifo_stage0_reg <- mkFIFOF;
   	FIFOF #(Bit#(QuireWidth) )  fifo_output_reg <- mkFIFOF;


	// --------
        // Pipeline stages
	//STAGE 1 -- rounding and special cases
	rule stage_1;
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		Bit#(1) flag_truncated_frac = (lsb(dIn.sum_calc) & dIn.q2_truncated_frac_zero) | dIn.q2_truncated_frac_notzero;
		let sign0 = msb(dIn.sum_calc);
		Bit#(2) truncated_frac = flag_truncated_frac == 1'b0 ? 2'b00 : {sign0,flag_truncated_frac};
		Int#(QuireWidth) sum_calc = boundedPlus(dIn.sum_calc,signExtend(unpack(truncated_frac)));
		Bit#(QuireWidthMinus1) sum_calc_unsigned = truncate(pack(sum_calc));
		Bit#(1) all_bits_0 = ~reduceOr(sum_calc_unsigned);

		PositType zero_infinity_flag0 = ((all_bits_0 & ~sign0) == 1'b1) && dIn.q1_zero_infinity_flag == REGULAR && dIn.q2_zero_infinity_flag == REGULAR  ? ZERO : REGULAR;
		let d = Quire {
			sign : sign0,
			//taking care of corner cases for nan flag 
			nan_flag : all_bits_0 & sign0 | dIn.q2_nan_flag | pack(dIn.q1_zero_infinity_flag == INF || dIn.q2_zero_infinity_flag == INF),
			//also include the case when fraction bit msb = 0
			zero_infinity_flag : zero_infinity_flag0,
			carry_int_frac : sum_calc_unsigned };
		if (d.nan_flag == 1'b1)
			fifo_output_reg.enq({1'b1,'0});
		else if(d.zero_infinity_flag == ZERO)
			fifo_output_reg.enq('0);
		else
   			fifo_output_reg.enq({d.sign,d.carry_int_frac});
	endrule

interface Server inoutifc;
      interface Put request;
         method Action put (Inputs_a p);
		//dIn reads the values from input pipeline register 
      		let dIn = p;
		// now we have do signed sum of the values since the numbers are basiclly integer.fractions
		Int#(QuireWidth) sum_calc = boundedPlus(unpack({dIn.q1.sign,dIn.q1.carry_int_frac}),dIn.q2.quire_md);
		//to see if 
                let stage0_regf = Stage0_a {
			sum_calc : sum_calc,
			q2_truncated_frac_zero : dIn.q2.truncated_frac_msb & dIn.q2.truncated_frac_zero,
			q2_truncated_frac_notzero : dIn.q2.truncated_frac_msb & ~(dIn.q2.truncated_frac_zero),
			q1_zero_infinity_flag : dIn.q1.zero_infinity_flag,
			q2_zero_infinity_flag : dIn.q2.zero_infinity_flag,
			q2_nan_flag : dIn.q2.nan_flag};
		 fifo_stage0_reg.enq(stage0_regf);
		`ifdef RANDOM_PRINT
			$display("dIn.q1.sign %b dIn.q1.carry_int_frac %b",dIn.q1.sign,dIn.q1.carry_int_frac);
			$display("dIn.q2.quire_md %b",dIn.q2.quire_md);
		`endif
		

   endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule

endpackage: Adder_fused_op

