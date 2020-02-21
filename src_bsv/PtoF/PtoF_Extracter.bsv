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

package PtoF_Extracter;

// --------------------------------------------------------------
// This package defines:
//
//    mkFtoP_Extracter:extracter which extracts the float to get posit
// --------------------------------------------------------------

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils :: *;
import PtoF_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Extracter_Types	:: *;
import Extracter ::*;

module mkPtoF_Extracter (PtoF_IFC );

	Extracter_IFC   extracter <- mkExtracter;
	FIFOF #(Input_posit)   fifo_input_reg <- mkFIFOF;
   	FIFOF #(Stage0_pf )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Bit#(FloatWidth))  fifo_output_reg <- mkFIFOF;

	//This function checks if the scale value has exceeded the limits max and min set due to the restricted availability of regime bits
	// fraction bits will be shifted to take care of the scale value change due to it being bounded
	//output : bounded scale value and the shift in frac bits
	function Tuple2#(Int#(FloatExpWidth), Int#(LogFloatFracWidthPlus1)) fv_calculate_scale_shift(Int#(ScaleWidthPlus1) scale);
		
			Int#(FloatExpWidth) maxB,minB,scale1;
			Int#(ScaleWidthPlus1) frac_change;
			Int#(LogFloatFracWidthPlus1) frac_change_bounded;
			//max scale value is defined here... have to saturate the scale value 
			// max value = (N-2)*(2^es) 
			// scale = regime*(2^es) + expo.... max value of regime = N-2(00...1)
			maxB = fromInteger(valueOf(FloatBias));
			//similarly calculate the min 
		 	minB = -fromInteger(valueOf(FloatBias));
			//frac_change gives the number of bits that are more or less than scale bounds so that we can shift the frac bits to not lose scale information
			Int#(LogFloatFracWidthPlus1) max_frac = unpack({1'b0,'1});
			Int#(LogFloatFracWidthPlus1) min_frac = unpack({1'b1,zeroExtend(1'b1)});
			Int#(ScaleWidthPlus1) max_frac_extend = signExtend(max_frac);
			Int#(ScaleWidthPlus1) min_frac_extend = signExtend(min_frac);				
			if (extend(scale)<minB)
				begin
				frac_change = truncate(extend(scale) - (minB));// find the change in scale to bind it
				scale1 = minB;//bound scale
				frac_change_bounded = truncate(max(frac_change,min_frac_extend));
				end
			else if (extend(scale)>(maxB))
				begin
				frac_change = truncate(extend(scale) - (maxB));// find the change in scale to bind it
				scale1 = maxB;//bound scale
				frac_change_bounded = truncate(min(frac_change,max_frac_extend));
				end
			else
				begin
				frac_change_bounded = fromInteger(0);
				scale1 = signExtend(scale);//no change
				end
			return tuple2(scale1,frac_change_bounded);

	endfunction
	
	function Tuple3#(Bit#(FloatFracWidth), Bit#(1), Bit#(1)) fv_calculate_frac(Bit#(FracWidth) frac);
		//`ifdef (FracWidth >= FLoatFracWidth)
			let a_frac_truncate = valueOf(FracWidthMinusFloatFracWidth);
			Bit#(1) truncated_frac_msb = a_frac_truncate > 0 ? frac[a_frac_truncate-1]:1'b0;
			Bit#(1) truncated_frac_zero = a_frac_truncate > 1 ? pack(unpack(frac[a_frac_truncate-2:0]) ==  0):1'b1;
			return tuple3(frac[valueOf(FracWidthMinus1):a_frac_truncate],truncated_frac_msb,truncated_frac_zero);
		//`else
			//Bit#(FracWidth) frac_extend= frac[valueOf(FracWidthMinus1):0];
			//return tuple3({frac_extend,'0},1'b0,1'b1);
		//`endif
			
	endfunction

	rule stage_0;
		//dIn reads the values from input pipeline register 
		extracter.inoutifc.request.put (fifo_input_reg.first);
		fifo_input_reg.deq;
	endrule

	rule stage_1;
		let extOut <- extracter.inoutifc.response.get ();
		match{.scale0, .frac_change0} = fv_calculate_scale_shift(extOut.scale);
		match{.frac0,.truncated_frac_msb0,.truncated_frac_zero0} = fv_calculate_frac(extOut.frac);
		let stage0_regf = Stage0_pf {
			//carrying sign bit fordward
			sign : extOut.sign ,
			//carrying zero and infinity flag forward
                        zero_infinity_flag : extOut.zero_infinity_flag ,
			//scale = k_scale + exponent field (base 2)
			scale : scale0,
			//carrying fraction bits fordward
			frac_change : frac_change0,
			frac : frac0,
			truncated_frac_msb : truncated_frac_msb0,
			truncated_frac_zero : truncated_frac_zero0};
		`ifdef RANDOM_PRINT
			$display("sign %b extOut.scale %b extOut.frac %b",extOut.sign,extOut.scale,extOut.frac);
			$display("frac0 %b scale0 %b frac_change0 %b ",frac0,scale0,frac_change0);
		`endif
		fifo_stage0_reg.enq(stage0_regf);	
	endrule

	rule stage_2;
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		Bit#(FloatFracWidthPlus1) frac = {1,dIn.frac}; 
		let truncated_frac_zero = dIn.frac_change < 0 ? ~dIn.truncated_frac_msb & pack(unpack(frac[abs(dIn.frac_change):0]) ==  0): (dIn.frac_change == 0 ?dIn.truncated_frac_zero: 1'b0);
		let truncated_frac_msb = dIn.frac_change < 0 ? frac[abs(dIn.frac_change)+1]: (dIn.frac_change == 0 ?dIn.truncated_frac_msb: 1'b1);
		Int#(FloatExpWidthPlus1) scale_f =signExtend(dIn.scale);
		Int#(FloatExpWidthPlus1) floatBias_int = fromInteger(valueOf(FloatBias));
		Bit#(FloatExpWidth) scale_plus_bias = truncate(pack(scale_f+floatBias_int));
		Bit#(FloatFracWidth) frac_f = dIn.frac_change < 0 ?truncate(frac>>abs(dIn.frac_change)+1): (dIn.frac_change == 0 ? truncate(frac) : '1);
		Bit#(FloatWidth) float_no= {dIn.sign,scale_plus_bias,frac_f};
		Bit#(1) add_round =(~(truncated_frac_zero) | lsb(frac_f)) & (truncated_frac_msb);
		Bit#(FloatFracWidth) frac_zero = 0;
		float_no = dIn.zero_infinity_flag == ZERO ? 0 : dIn.zero_infinity_flag == INF ? {'1,frac_zero} : (float_no+extend(add_round)) ;
		`ifdef RANDOM_PRINT
			$display("scale_f %b scale_plus_bias %b frac_f %b",scale_f,scale_plus_bias,frac_f);
			$display("float_no %b add_round %b ",float_no,add_round);
			$display("truncated_frac_zero %b truncated_frac_msb %b lsbfrac_f %b",truncated_frac_zero,truncated_frac_msb,lsb(frac_f));
		`endif
		fifo_output_reg.enq(float_no);	
	
	endrule
	
	interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);

endmodule
endpackage: PtoF_Extracter
