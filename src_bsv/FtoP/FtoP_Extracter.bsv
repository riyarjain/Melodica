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

package FtoP_Extracter;

// --------------------------------------------------------------
// This package defines:
//
//    mkFtoP_Extracter:extracter which extracts the float to get posit
// --------------------------------------------------------------


import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils :: *;
import FtoP_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Normalizer_Types	:: *;
import Normalizer ::*;

module mkFtoP_Extracter (FtoP_IFC );
	Normalizer_IFC   normalizer <- mkNormalizer;
	FIFOF #(Bit#(FloatWidth) )   fifo_input_reg <- mkFIFOF;
   	FIFOF #(Stage0_fp )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Output_posit_n )  fifo_output_reg <- mkFIFOF;
	function Bit#(1) fv_check_nan(Bit#(FloatExpWidth) expo_f,Bit#(FloatFracWidth) frac_f);
		if(expo_f == '1 && frac_f != 0)
			return 1'b1;
		else
			return 1'b0;
	endfunction

	function PositType fv_check_ziflag(Bit#(FloatExpWidth) expo_f,Bit#(FloatFracWidth) frac_f);
		if(expo_f == '1 && frac_f == 0)
			return INF;
		else if(expo_f == 0 && frac_f == 0)
			return ZERO;
		else
			return REGULAR;
	endfunction

	//This function checks if the scale value has exceeded the limits max and min set due to the restricted availability of regime bits
	// fraction bits will be shifted to take care of the scale value change due to it being bounded
	//output : bounded scale value and the shift in frac bits
	function Tuple2#(Int#(ScaleWidthPlus1), Int#(LogFracWidthPlus1)) fv_calculate_scale_shift(Int#(FloatExpWidth) scale);
		
			Int#(ScaleWidthPlus1) maxB,minB,scale1;
			Int#(FloatExpWidth) frac_change;
			Int#(LogFracWidthPlus1) frac_change_bounded;
			//max scale value is defined here... have to saturate the scale value 
			// max value = (N-2)*(2^es) 
			// scale = regime*(2^es) + expo.... max value of regime = N-2(00...1)
			maxB = fromInteger((valueOf(PositWidth) -2)*(2**(valueOf(ExpWidth))));
			//similarly calculate the min 
		 	minB = -maxB;
			//frac_change gives the number of bits that are more or less than scale bounds so that we can shift the frac bits to not lose scale information
			Int#(LogFracWidthPlus1) max_frac = unpack({1'b0,'1});
			Int#(LogFracWidthPlus1) min_frac = unpack({1'b1,extend(1'b1)});
			Int#(FloatExpWidth) max_frac_extend = signExtend(max_frac);
			Int#(FloatExpWidth) min_frac_extend = signExtend(min_frac);				
			if (scale<extend(minB))
				begin
				frac_change = truncate(scale - extend(minB));// find the change in scale to bind it
				scale1 = minB;//bound scale
				frac_change_bounded = truncate(max(frac_change,min_frac_extend));
				end
			else if (scale>extend(maxB))
				begin
				frac_change = truncate(scale - extend(maxB));// find the change in scale to bind it
				scale1 = maxB;//bound scale
				frac_change_bounded = truncate(min(frac_change,max_frac_extend));
				end
			else
				begin
				frac_change_bounded = fromInteger(0);
				scale1 = truncate(scale);//no change
				end
			return tuple2(scale1,frac_change_bounded);

	endfunction
	
	function Tuple3#(Bit#(FracWidth), Bit#(1), Bit#(1)) fv_calculate_frac(Bit#(FloatFracWidth) frac);
		`ifdef (FloatFracWidth >= FracWidth)
			let a_frac_truncate = valueOf(FloatFracWidthMinusFracWidth);
			Bit#(1) truncated_frac_msb = a_frac_truncate > 0 ? frac[a_frac_truncate-1]:1'b0;
			Bit#(1) truncated_frac_zero = a_frac_truncate > 1 ? pack(unpack(frac[a_frac_truncate-2:0]) ==  0):1'b1;
			return tuple3(frac[valueOf(FloatFracWidthMinus1):a_frac_truncate],truncated_frac_msb,truncated_frac_zero);
		`else
			Bit#(FloatFracWidth) frac_extend= frac[valueOf(FloatFracWidthMinus1):0];
			return tuple3({frac_extend,'0},1'b0,1'b1);
		`endif
			
	endfunction
	// stage_0: INPUT STAGE. Checks for special cases. 
	rule stage_0;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_input_reg.first;  fifo_input_reg.deq;
		Bit#(FloatExpWidth) expo_f_unsigned = (dIn[valueOf(FloatExpoBegin):valueOf(FloatFracWidth)]);
		Int#(FloatExpWidthPlus1) expo_f = unpack({0,expo_f_unsigned});
		Bit#(FloatFracWidth) frac_f = truncate(dIn);
		Bit#(1) sign_f = msb(dIn);
		Int#(FloatExpWidthPlus1) floatBias_int = fromInteger(valueOf(FloatBias));
		Int#(FloatExpWidth) expo_minus_floatBias = truncate(expo_f-floatBias_int);
		match{.scale0, .frac_change0} = fv_calculate_scale_shift(expo_minus_floatBias);
		match{.frac0,.truncated_frac_msb0,.truncated_frac_zero0} = fv_calculate_frac(frac_f); 
		let stage0_regf = Stage0_fp {
			//carrying sign bit fordward
			sign : sign_f ,
			//carrying zero and infinity flag forward
                        zero_infinity_flag : fv_check_ziflag(expo_f_unsigned,frac_f) ,
			nan_flag : fv_check_nan(expo_f_unsigned,frac_f),
			//scale = k_scale + exponent field (base 2)
			scale : scale0,
			//carrying fraction bits fordward
			frac_change : frac_change0,
			frac : frac0,
			truncated_frac_msb : truncated_frac_msb0,
			truncated_frac_zero : truncated_frac_zero0};
	`ifdef RANDOM_PRINT
		$display("sign_f %b expo_f_unsigned %b frac_f %b",sign_f,expo_f_unsigned,frac_f);
		$display("expo_minus_floatBias %b scale0 %b frac_change0 %b ",expo_minus_floatBias,scale0,frac_change0);
		$display("");
	`endif
		fifo_stage0_reg.enq(stage0_regf);
	endrule
	
	rule stage_2;
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		Bit#(FracWidthPlus1) frac = {1,dIn.frac};  
		let truncated_frac_zero = dIn.frac_change < 0 ? pack(unpack(frac[abs(dIn.frac_change):0]) ==  0): (dIn.frac_change == 0 ?1'b1: 1'b0);					
		normalizer.inoutifc.request.put (Input_value_n {
		sign: dIn.sign,
	 	zero_infinity_flag: dIn.zero_infinity_flag ,
		nan_flag: dIn.nan_flag,
		scale : pack(dIn.scale) ,
		frac : dIn.frac_change < 0 ?truncate(frac>>abs(dIn.frac_change)+1): (dIn.frac_change == 0 ? truncate(frac) : '1),
		truncated_frac_msb : dIn.frac_change < 0 ? frac[abs(dIn.frac_change)+1]: (dIn.frac_change == 0 ?dIn.truncated_frac_msb: 1'b1),
		truncated_frac_zero : ~dIn.truncated_frac_msb & dIn.truncated_frac_zero & truncated_frac_zero});
	endrule

	rule rl_out;
	   let normOut <- normalizer.inoutifc.response.get ();
	   fifo_output_reg.enq(normOut);
	endrule
interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);
endmodule

endpackage: FtoP_Extracter