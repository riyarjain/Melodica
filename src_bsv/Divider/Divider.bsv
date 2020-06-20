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

package Divider;
// --------------------------------------------------------------
// This package defines:
//
// mkDivider: 3-stage posit divider
// --------------------------------------------------------------

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils :: *;
import Divider_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import IntDivide ::*;

module mkDivider (Divider_IFC );
	// make a FIFO to store 
   	FIFOF #(Outputs_d )  fifo_output_reg <- mkFIFOF;
	FIFOF #(Stage0_d )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Stage1_d )  fifo_stage1_reg <- mkFIFOF;
	//This function is used to identify nan cases
	IntDivide intDivide <- mkIntDivide;
	function Bit#(1) fv_check_for_nan(PositType z_i1, PositType z_i2,Bit#(1) nan1,Bit#(1) nan2 );
		if ((z_i1 == ZERO && z_i2 == ZERO)||(z_i2 == INF && z_i1 == INF)||(nan1 == 1'b1)||(nan2 == 1'b1))
			//nan flag = 1 when one input is infinity and other zero
			return 1'b1;
		else 
			return 1'b0;
	endfunction
	//This function is used to identify zer or infinity cases depending only on the flag value of inputs

	function PositType fv_check_for_z_i(PositType z_i1, PositType z_i2);
		if ((z_i1 == ZERO && z_i2 != ZERO) || (z_i1 != INF && z_i2 == INF))
			// if both inputs are zero then output is zero
			return ZERO;
		else if ((z_i1 == INF && z_i2 != INF) || (z_i1 != ZERO && z_i2 == ZERO))
			// if one of the inputs is infinity then output is infinity
			return INF;
		else 
			return REGULAR;
	endfunction

//This function checks if the scale value has exceeded the limits max and min set due to the restricted availability of regime bits
	// fraction bits will be shifted to take care of the scale value change due to it being bounded
	//output : bounded scale value and the shift in frac bits
	function Tuple2#(Int#(ScaleWidthPlus1), Int#(LogFracWidthPlus1)) fv_calculate_scale_shift(Int#(ScaleWidthPlus1) scale);
		
			Int#(ScaleWidthPlus1) maxB,minB;
			Int#(LogFracWidthPlus1) frac_change;
			//max scale value is defined here... have to saturate the scale value 
			// max value = (N-2)*(2^es) 
			// scale = regime*(2^es) + expo.... max value of regime = N-2(00...1)
			maxB = fromInteger((valueOf(PositWidth) -2)*(2**(valueOf(ExpWidth))));
			//similarly calculate the min 
		 	minB = -maxB; 
			//frac_change gives the number of bits that are more or less than scale bounds so that we can shift the frac bits to not lose scale information 
			if (scale<minB)
				begin
				frac_change = truncate(scale - minB);// find the change in scale to bind it
				scale = minB;//bound scale
				end
			else if (scale>maxB)
				begin
				frac_change = truncate(scale - maxB);// find the change in scale to bind it
				scale = maxB;//bound scale
				end
			else
				begin
				frac_change = fromInteger(0);
				scale = scale;//no change
				end
			return tuple2(scale,frac_change);

	endfunction
	
//This function finds the sum of the scale bits since the scale value has 2^scale contribution in the product
	function Tuple2#(Int#(ScaleWidthPlus1), Int#(LogFracWidthPlus1)) fv_calculate_sum_scale(Int#(ScaleWidthPlus1 ) s1,Int#(ScaleWidthPlus1)s2,Bit#(1) frac_shift);
			Int#(ScaleWidthPlus1) scale;
			//Scale is calculated as the sum of the respective scale
			// bounded the value to prevent wrap around
			// we also add the fraction bit shift(the shift was done to get msb =1) to accomodate more frac bits
			scale = boundedMinus(boundedPlus(s1,s2) , unpack(extend(frac_shift)));
			// now we bound the scale further to bound its value between min and max
			return fv_calculate_scale_shift(scale);
			//Scale_bound a;
			//a.scale = boundedMinus(boundedPlus(s1,s2) , unpack(extend(frac_shift)-1));
			//return a.scale ; 
	endfunction
	
	// --------
        // Pipeline stages
	
	//stage_1: scale calculation
	rule stage_1;
		let div_out <- intDivide.inoutifc.response.get();
		Bit#(1) fracshift = truncate(pack(countZerosMSB(div_out.quotient)));
		Bit#(FracWidthPlus3) frac = extend(div_out.quotient << fracshift);
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		// data to be stored in stored in fifo that will be used in stage 1
		//calling function to get sum of scale
		match{.scale0, .frac_change0} = fv_calculate_sum_scale(dIn.scale1,-dIn.scale2,fracshift);
		//taking care of corner cases for zero infinity flag
                let stage1_regf = Stage1_d {
			//taking care of corner cases for nan flag 
			nanflag :dIn.nanflag,
			//also include the case when fraction bit msb = 0
			zero_infinity_flag : (((frac == 0 && (div_out.truncated_frac_zero & (~div_out.truncated_frac_msb)) == 1'b1) && dIn.ziflag == REGULAR) ? ZERO :dIn.ziflag),
			sign : dIn.sign,
			scale : scale0,
			//truncate to remove the hidden bit
			// shift to get the sum to smaller value
			// shift by frac_change to accomodate the overflow of scale 
			frac : frac,
			truncated_frac_msb : div_out.truncated_frac_msb,
			truncated_frac_zero : div_out.truncated_frac_zero,
			frac_change : frac_change0};
		`ifdef RANDOM_PRINT
			$display("div_out.quotient %b div_out.quotient << fracshift %b fracshift %b frac %b",div_out.quotient,div_out.quotient << fracshift,fracshift,frac);
			$display("scale0 %b frac_change0 %b",scale0,frac_change0);
			$display("truncated_frac_msb %b truncated_frac_zero %b",div_out.truncated_frac_msb,div_out.truncated_frac_zero);
		`endif
   		fifo_stage1_reg.enq(stage1_regf);

   	endrule
	
	// stage_2 : output stage 
	rule output_stage;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
		// data to be stored in stored in fifo that will be used in output
		//to see what the hidden bit of each fraction bit will be thus sending that bit for product
                let output_regf = Outputs_d {
			sign : dIn.sign,
			zero_infinity_flag : dIn.zero_infinity_flag,
			nan_flag : dIn.nanflag,
			scale : dIn.scale,
			frac : dIn.frac_change < 0 ?truncate(dIn.frac>>abs(dIn.frac_change)+3): (dIn.frac_change == 0 ? truncate(dIn.frac>>(abs(dIn.frac_change)+2)) : '1),
			truncated_frac_msb : dIn.frac_change < 0 ? dIn.frac[abs(dIn.frac_change)+2]: (dIn.frac_change == 0 ?dIn.frac[abs(dIn.frac_change)+1] : 1'b1),
			truncated_frac_zero : (dIn.frac_change < 0 ? ((unpack(dIn.frac[abs(dIn.frac_change)+1:0]) ==  0) ? 1'b1 : 1'b0): (dIn.frac_change == 0 ?((unpack(dIn.frac[abs(dIn.frac_change):0]) ==  0) ? 1'b1 : 1'b0) : 1'b0)) & dIn.truncated_frac_zero & (~dIn.truncated_frac_msb)};
   		fifo_output_reg.enq(output_regf);
		`ifdef RANDOM_PRINT
			$display("frac %b",output_regf.frac);
			$display("truncated_frac_msb %b truncated_frac_zero %b",output_regf.truncated_frac_msb,output_regf.truncated_frac_zero);
		`endif
   	endrule


interface Server inoutifc;
      interface Put request;
         method Action put (Inputs_d p);
		//dIn reads the values from input pipeline register 
      		let dIn = p;
		// data to be stored in stored in fifo that will be used in stage 0
		//to see what the hidden bit of each fraction bit will be thus sending that bit for product
		let zero_flag = dIn.zero_infinity_flag1 == ZERO ? 2'b01 : ( dIn.zero_infinity_flag2 == ZERO ? 2'b10 : 2'b11);
		// calling function to get product of fractions
		intDivide.inoutifc.request.put (Input_intdiv{numerator : {zero_flag[1],dIn.frac1},denominator : {zero_flag[0],dIn.frac2}});
		//calling function to get sum of scale
		//taking care of corner cases for zero infinity flag
		let ziflag = fv_check_for_z_i(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2);
                let stage0_regf = Stage0_d {
			//taking care of corner cases for nan flag 
			nanflag : fv_check_for_nan(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2,dIn.nanflag1,dIn.nanflag2),
			//also include the case when fraction bit msb = 0
			ziflag : ziflag,
			sign : dIn.sign1 ^ dIn.sign2,
			scale1 : dIn.scale1,
			scale2 : dIn.scale2};
   		fifo_stage0_reg.enq(stage0_regf);

   endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule

endpackage: Divider


