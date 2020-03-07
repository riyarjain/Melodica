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
	// function checks if float is nan if exponent = 11..11, fraction > 00...000
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

	// --------
        // Pipeline stages
	// stage_0: INPUT STAGE, interpret float and calculate exponent and frac 
	rule stage_0;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_input_reg.first;  fifo_input_reg.deq;
		//get sign, exponent and fraction bits
		Bit#(FloatExpWidth) expo_f_unsigned = (dIn[valueOf(FloatExpoBegin):valueOf(FloatFracWidth)]);
		Int#(FloatExpWidthPlus1) expo_f = unpack({0,expo_f_unsigned});
		Bit#(FloatFracWidth) frac_f = truncate(dIn);
		Bit#(1) sign_f = msb(dIn);
		//calculate scale after subtracting bias
		Int#(FloatExpWidthPlus1) floatBias_int = fromInteger(valueOf(FloatBias));
		Int#(FloatExpWidth) expo_minus_floatBias = truncate(expo_f-floatBias_int);
		//calculate scale for posits and frac shift due to restrictions on scale sizes
		match{.scale0, .frac_change0} = fv_calculate_scale_shift_fp(expo_minus_floatBias);
		//calculate fraction shifts and truncated bits
		match{.frac0,.truncated_frac_msb0,.truncated_frac_zero0} = fv_calculate_frac_fp(frac_f); 
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

	// stage_1: truncate frac bits	
	rule stage_1;
		//dIn reads the values from input pipeline register 
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		//add hidden bit
		Bit#(FracWidthPlus1) frac = {1,dIn.frac}; 
		//if the truncated bits are zero or not 
		//if frac change < 0 then frac bits lost but if >0 then basically frac is maximum since scale is already maximum 
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

	// stage_2: normalizer	
	rule rl_out;
		//normalize the values got after interpreting the float
		let normOut <- normalizer.inoutifc.response.get ();
		fifo_output_reg.enq(normOut);
	endrule
interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);
endmodule

endpackage: FtoP_Extracter
