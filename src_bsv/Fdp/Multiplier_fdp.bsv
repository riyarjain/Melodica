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

package Multiplier_fdp;

// --------------------------------------------------------------
// This package defines:
//
// mkMultiplier: 2-stage posit multiplier
// --------------------------------------------------------------

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Multiplier_Types_fdp :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;


module mkMultiplier (Multiplier_IFC );
	// make a FIFO to store 
        FIFOF #(Inputs_m )   fifo_input_reg <- mkFIFOF;
   	FIFOF #(Outputs_m )  fifo_output_reg <- mkFIFOF;
	FIFOF #(Stage0_m )  fifo_stage0_reg <- mkFIFOF;
	//This function is used to identify nan cases

	function Bit#(1) check_for_nan(PositType z_i1, PositType z_i2,Bit#(1) nan1,Bit#(1) nan2 );
		if ((z_i1 == INF && z_i2 == ZERO)||(z_i2 == INF && z_i1 == ZERO)||(nan1 == 1'b1)||(nan2 == 1'b1))
			//nan flag = 1 when one input is infinity and other zero
			return 1'b1;
		else 
			return 1'b0;
	endfunction
	//This function is used to identify zer or infinity cases depending only on the flag value of inputs

	function PositType check_for_z_i(PositType z_i1, PositType z_i2);
		if (z_i1 == ZERO && z_i2 == ZERO)
			// if both inputs are zero then output is zero
			return ZERO;
		else if (z_i1 == INF || z_i2 == INF)
			// if one of the inputs is infinity then output is infinity
			return INF;
		else 
			return REGULAR;
	endfunction
	//This function finds the product of the fraction bits
	function Tuple2#(Bit#(1), Bit#(FracWidthPlus1Mul2)) calculate_product_frac(Bit#(1) sgn1,Bit#(1)sgn2,Bit#(FracWidthPlus1)f1,Bit#(FracWidthPlus1)f2);
		Bit#(FracWidthPlus1Mul2)frac_product;
		//frac_product gives the product of the two fractions
		// its size = sum of sizes of input fractions = FracWidth + 1 + FracWidth + 1 
		frac_product = extend(f1) * extend(f2);
		//Sign is given by the xor of the two signs
		//sign = 1 if negative number
		//if any of the input numbers are 0 then the msb of the fraction will be 0 so the sign of number will be 0 ()since answer of the number is 0
		return tuple2((sgn1 ^ sgn2) & msb(f1) & msb(f2),frac_product); 
	endfunction
	
	//This function finds the sum of the scale bits since the scale value has 2^scale contribution in the product
	function Int#(ScaleWidthPlus2) calculate_sum_scale(Int#(ScaleWidthPlus1 ) s1,Int#(ScaleWidthPlus1)s2);
			Int#(ScaleWidthPlus2) scale;
			//Scale is calculated as the sum of the respective scale
			scale = signExtend(s1)+signExtend(s2);
			return scale;
	endfunction

	//This function will be used to get the carry-Int-Frac value from the scale and frac value got from multiplying the values
	function Tuple4#(Bit#(IntWidthQuirePlusFracWidthQuire),Bit#(CarryWidthQuire),Bit#(1),Bit#(1)) calculate_frac_int(Bit#(FracWidthPlus1Mul2) f, Int#(ScaleWidthPlus2) s);
		Bit#(IntWidthQuirePlusFracWidthQuire) f_new = extend(f);
		//first two bits of fraction are integer bits so if scale = 0 we have to shift fract left by FWQ-FW*2
		//Thus frac_shift = FWQ-FW*2 + scale(signed sum)
		// if input scale is negative beyond and extent s.t fracshift < 0
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_neg_temp = abs(signExtend(s)) - fromInteger(valueOf(FracWidthQuire));//scale_neg_temp = abs(s)-FWQ
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_neg = scale_neg_temp + fromInteger(valueOf(FracWidthMul2));//frac_shift = scale_neg = abs(s) - (FWQ-FW*2)
		// if input scale is negative beyond and extent s.t fracshift > 0
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_pos = signExtend(s) + fromInteger(valueOf(FracWidthQuireMinusFracWidthMul2));// frac_shift = scale_pos = s + FWQ-FW*2
		Bit#(1) truncated_frac_msb = 1'b0;
		Bit#(1) truncated_frac_zero = 1'b1;
		Bit#(2) carry = 2'b00;
		if(msb(s) == 1'b1 && scale_neg>0)
			begin
				f_new = f_new>>scale_neg;// if frac_shift < -(FWQ-FW*2) the scale will be shifted right and we will lose frac bits since the maximum available shift = FWQ-FW*2
				truncated_frac_msb = scale_neg>0 ? f[scale_neg-1] : 1'b0;//in the truncated bits see the msb
				Bit#(IntWidthQuirePlusFracWidthQuire) mask1 = ~('1>>scale_neg-1);
				truncated_frac_zero = scale_neg>1 ? ((extend(f) & mask1) == 0 ? 1'b1 : 1'b0) :1'b1;////in the truncated bits see the leftover bits other than msb
			end 
		else
			begin
				f_new = f_new<<scale_pos;// right shift to accomodate the scale
				if(scale_neg_temp+2>0)
					//carry = extend(f[valueOf(FracWidthMul2Plus1):valueOf(FracWidthMul2)]);
					carry = truncate(f>>(fromInteger(valueOf(FracWidthMul2))-scale_neg_temp));
					// nuw we can have over flow from the integer bits if the scale is large
					//total shift = S_pos, carry starts at SWQ+FWQ, so spos>SWQ+FWQ gives condition for carry
			end	
		return tuple4(f_new,extend(carry),truncated_frac_msb,truncated_frac_zero);
	endfunction
			


	// --------
        // Pipeline stages
	// stage_0: INPUT STAGE and scale calculation
	rule stage_0;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_input_reg.first;  fifo_input_reg.deq;
		// data to be stored in stored in fifo that will be used in stage 0
		//see the corner cases due to zero infinity flag
		let ziflag = check_for_z_i(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2);
		//to see what the hidden bit of each fraction bit will be thus sending that bit for product that can be seen as the two bits of zero flag
		let zero_flag = dIn.zero_infinity_flag1 == ZERO ? 2'b01 : ( dIn.zero_infinity_flag2 == ZERO ? 2'b10 : 2'b11);
		let scale0 = calculate_sum_scale(dIn.scale1,dIn.scale2);
		// calling function to get product of fractions
		match{ .sign0, .frac0} = calculate_product_frac(dIn.sign1,dIn.sign2,{zero_flag[1],dIn.frac1},{zero_flag[0],dIn.frac2});
		//calling function to get sum of scale
		
                let stage0_regf = Stage0_m {
			//taking care of corner cases for nan flag 
			nan_flag : check_for_nan(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2,dIn.nanflag1,dIn.nanflag2),
			//also include the case when fraction bit msb = 0
			ziflag : ziflag,
			sign : sign0,
			scale : scale0,
			frac : frac0};
   		fifo_stage0_reg.enq(stage0_regf);
		`ifdef RANDOM_PRINT
			$display("zero_infinity_flag %b",stage0_regf.ziflag);
			$display("sign0 %b",sign0);
			$display("scale0 %h frac0 %h",scale0,frac0);
		`endif
   	endrule

	//stage_1: fraction calculation
	rule stage_1;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		// data to be stored in stored in fifo that will be used in stage 1
		match{.int_frac0,.carry0,.truncated_frac_msb0,.truncated_frac_zero0} = calculate_frac_int(dIn.frac,dIn.scale);
		//carry bit extended
		Bit#(CarryWidthQuire) carry = extend(carry0);
		//the Quire value is signed extend
		Bit#(QuireWidth) twos_complement_carry_int_frac = dIn.sign == 1'b0 ? {dIn.sign,carry,int_frac0} : {dIn.sign,twos_complement({carry,int_frac0})};
		//taking care of corner cases for zero infinity flag
		PositType zero_infinity_flag0 = twos_complement_carry_int_frac == 0 && dIn.ziflag == REGULAR ? ZERO :dIn.ziflag;
		let output_regf = Outputs_m {
		nan_flag : dIn.nan_flag,
		//also include the case when fraction bit msb = 0
		zero_infinity_flag : zero_infinity_flag0,
		quire_mul : unpack(twos_complement_carry_int_frac),			
		truncated_frac_msb : truncated_frac_msb0,//zero_infinity_flag0 == ZERO ? 1'b0 : 
		truncated_frac_zero : truncated_frac_zero0};//zero_infinity_flag0 == ZERO ? 1'b1 :
		`ifdef RANDOM_PRINT
			$display("int_frac0 %h carry0 %h",int_frac0,carry0);
			$display("twos_complement_carry_int_frac %h",twos_complement_carry_int_frac);
		`endif
   		fifo_output_reg.enq(output_regf);
	endrule

interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);
endmodule

endpackage: Multiplier_fdp


