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

import PtoF_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Extracter_Types	:: *;


module mkPtoF_Extracter (PtoF_IFC );


	FIFOF #(Output_posit)   fifo_input_reg <- mkFIFOF;
   	FIFOF #(Stage0_pf )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Bit#(FloatWidth))  fifo_output_reg <- mkFIFOF;

	// --------
        // Pipeline stages
	// stage_1: INPUT STAGE
	rule stage_1;
		let extOut = fifo_input_reg.first;
		fifo_input_reg.deq;
		//get extractor output
		//calculate scale for posits and frac shift due to restrictions on scale sizes
		match{.scale0, .frac_change0} = fv_calculate_scale_shift_pf(extOut.scale);
		//calculate fraction shifts and truncated bits
		match{.frac0,.truncated_frac_msb0,.truncated_frac_zero0} = fv_calculate_frac_pf(extOut.frac);
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
		//add hidden bit
		Bit#(FloatFracWidthPlus1) frac = {1,dIn.frac};
		//if the truncated bits are zero or not 
		//if frac change < 0 then frac bits lost but if >0 then basically frac is maximum since scale is already maximum  
		let truncated_frac_zero = dIn.frac_change < 0 ? ~dIn.truncated_frac_msb & pack(unpack(frac[abs(dIn.frac_change):0]) ==  0): (dIn.frac_change == 0 ?dIn.truncated_frac_zero: 1'b0);
		//the truncated bits msb
		//if frac change < 0 then frac bits lost but if >0 then basically frac is maximum since scale is already maximum 
		let truncated_frac_msb = dIn.frac_change < 0 ? frac[abs(dIn.frac_change)+1]: (dIn.frac_change == 0 ?dIn.truncated_frac_msb: 1'b1);
		Int#(FloatExpWidthPlus1) scale_f =signExtend(dIn.scale);
		Int#(FloatExpWidthPlus1) floatBias_int = fromInteger(valueOf(FloatBias));
		//calculate exponent after adding bias
		Bit#(FloatExpWidth) scale_plus_bias = truncate(pack(scale_f+floatBias_int));
		//shift fraction depending on frac change
		Bit#(FloatFracWidth) frac_f = dIn.frac_change < 0 ?truncate(frac>>abs(dIn.frac_change)+1): (dIn.frac_change == 0 ? truncate(frac) : '1);
		//concatenate sign, exponent and fraction bits
		Bit#(FloatWidth) float_no= {dIn.sign,scale_plus_bias,frac_f};
		//round the number depending on fraction bits lost
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
