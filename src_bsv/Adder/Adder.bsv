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

package Adder;
// --------------------------------------------------------------
// This package defines:
//
//    mkAdder: 3-stage adder which computes the sum of 2 posits
// --------------------------------------------------------------

// Library imports
import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils :: *;
import Adder_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;

module mkAdder (Adder_IFC );
	// make a FIFO to store data at the end of each stage of the pipeline, and also for input and outputs
   	FIFOF #(Outputs_a )  fifo_output_reg <- mkFIFOF;
	FIFOF #(Stage0_a )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Stage1_a )  fifo_stage1_reg <- mkFIFOF;
	//This function is used to identify nan cases

	function Bit#(1) fv_check_for_nan(PositType z_i1, PositType z_i2,Bit#(1) nan1,Bit#(1) nan2 );
		if (z_i1 == INF && z_i2 == INF||(nan1 == 1'b1)||(nan2 == 1'b1))
			//nan flag = 1 when both inputs are infinity
			return 1'b1;
		else 
			return 1'b0;
	endfunction
	//This function is used to identify zer or infinity cases depending only on the flag value of inputs

	function PositType fv_check_for_z_i(PositType z_i1, PositType z_i2);
		if (z_i1 == ZERO && z_i2 == ZERO)
			// if both inputs are zero then output is zero
			return ZERO;
		else if (z_i1 == INF || z_i2 == INF)
			// if one of the inputs is infinity then output is infinity
			return INF;
		else 
			return REGULAR;
	endfunction

	//This function is used to define the scale of the output depending on the scale of input
	// so the input's fractional value is accordingly shifted to match the scales of the input to the output
	/* if scale of input 1 > scale of input 2
			scale of output = scale of input 1
			new fractional value of 2 = fractional value of 2 shifted right by the difference of scale sizes to match scales 
		similarly for the other case
	*/
	// we get the value of scale_shift using signed subtraction
	function Tuple3#(Int#(ScaleWidthPlus1), Bit#(FracWidthMul2Plus1), Bit#(FracWidthMul2Plus1)) fv_calculate_scale(Int#(ScaleWidthPlus1 ) s1,Int#(ScaleWidthPlus1)s2,Bit#(FracWidthMul2Plus1)f1,Bit#(FracWidthMul2Plus1)f2, Bit#(2) zf);
		Int#(ScaleWidthPlus1) scale_shift;
		if (zf == 2'b01)
			return tuple3(s2,'0,f2); 
		else if (zf == 2'b10)
			return tuple3(s1,f1,'0); 
		else if (s1>s2)
			begin
				scale_shift = s1-s2;
				return tuple3(s1,f1,(f2>>scale_shift));
			end
		else
			begin
				scale_shift = s2-s1;
				return tuple3(s2,(f1>>scale_shift),f2);
			end
	endfunction


	// This function calculates the output scale and fractional value(fraction with hidden bit)
	function Tuple3#(Bit#(1), Int#(ScaleWidthPlus1),Bit#(FracWidthMul2Plus1)) fv_calculate_sum(Bit#(1) sgn1,Bit#(1)sgn2, Int#(ScaleWidthPlus1) s,Bit#(FracWidthMul2Plus1)f1,Bit#(FracWidthMul2Plus1)f2);
		Bit#(FracWidthPlus1Mul2)frac_sign;
		Bit#(ScaleWidthPlus1) frac_shift;
		Int#(ScaleWidthPlus1) s1;
		Bit#(ScaleWidthPlus1) one_full = '1>>1; 
		//conditional statement order important
		if (unpack(~(sgn1^ sgn2)))
			//if same signed input
			begin
			//add the fractional values since same sign of inputs
			frac_sign = extend(f1) + extend(f2);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift = extend(pack(countZerosMSB(frac_sign)));
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by scale)
			s1 = (s) - unpack(extend(frac_shift)-1);// signed addition
			// msb(s1) is scale is extended beyond its limit
			//fractional bits shifted that the first bit is 1
			return tuple3(sgn1,(s1),truncate(frac_sign>>(1-frac_shift)));
			end
		//depending on which fractional size is greater	
		else if(f1>f2)
			begin
			//subtract the fractional since different sign of inputs
			frac_sign = extend(f1) - extend(f2);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift = extend(pack(countZerosMSB(frac_sign)));
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by scale)  
			s1 = (s) - unpack(extend(frac_shift)-1);
			// msb(s1) is scale is extended beyond its limit
			//fractional bits shifted that the first bit is 1
			return tuple3(sgn1,(s1),truncate(frac_sign<<(frac_shift-1)));
			end
		else
			begin
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_sign = extend(f2) - extend(f1);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift = extend(pack(countZerosMSB(frac_sign)));
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by scale)
			s1 = (s) - unpack(extend(frac_shift)-1);
			// msb(s1) is scale is extended beyond its limit
			//fractional bits shifted that the first bit is 1
			// sign of the input whose fractional value is greater
			return tuple3(sgn2,(s1),truncate(frac_sign<<(frac_shift-1)));
			end
	endfunction


 	// --------
        // Pipeline stages

	// STAGE 1: Calculating scale and addition of scale
	rule stage_1;
		//dIn reads the values from pipeline register stored from previous stage
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		// call function to get output fractional value
		match{ .scale0, .frac10, .frac20} = fv_calculate_scale(dIn.scale1,dIn.scale2,{1,dIn.frac1},{1,dIn.frac2},dIn.zero_flag);
		// data to be stored in stored in fifo that will be used in stage 1		
		let stage1_regf = Stage1_a {
			nan_flag : dIn.nan_flag,
			zero_infinity_flag : dIn.zero_infinity_flag,
			scale : scale0,
			sign1 : dIn.sign1,
			frac1 : frac10,
			sign2 : dIn.sign2,
			frac2 : frac20
			};
		`ifdef RANDOM_PRINT
			//$display("scale0 %b",scale0);
			//		$display("dIn.frac1 %b dIn.frac2 %b",frac10,frac20);
		`endif
		fifo_stage1_reg.enq(stage1_regf);
	endrule

	 
	//STAGE 2 -- OUTPUT and calculation of fraction
	rule stage_2;
		//dIn reads the values from pipeline register stored from previous stage
		let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
		match{ .sign0,.scale0, .frac0} = fv_calculate_sum(dIn.sign1,dIn.sign2,dIn.scale,dIn.frac1,dIn.frac2);
		// data to be stored in stored in fifo that will be used in output
		// for zero infinity flag: have to recheck the output after the computations
		// number = zero if hidden bit  = 0
		// number = infinity 1st bit of scale = 1 
		Bit#(FracWidthMinus1) frac_truncate_zero = truncate(frac0);		
		let output_regf = Outputs_a {
			nan_flag : dIn.nan_flag,
			zero_infinity_flag : (((msb(frac0) == 1'b0) && dIn.zero_infinity_flag == REGULAR) ? ZERO :dIn.zero_infinity_flag),
			scale : scale0,
			sign : sign0,
			frac : truncate(frac0>>valueOf(FracWidth)),
			truncated_frac_msb : frac0[valueOf(FracWidthMinus1)],
			truncated_frac_zero : ((frac_truncate_zero ==  0)? 1'b1 : 1'b0)};
		`ifdef RANDOM_PRINT
		//$display("frac %b dIn.frac1 %b dIn.frac2 %b",frac0,dIn.frac1,dIn.frac2);
		//$display("scale0 %b",scale0);
		//$display("dIn.scale %b",dIn.scale);
		`endif
		fifo_output_reg.enq(output_regf);
	endrule	
interface Server inoutifc;
      interface Put request;
         method Action put (Inputs_a p);
//dIn reads the values from input pipeline register 
      		let dIn = p;
		// data to be stored in stored in fifo that will be used in stage 0
                let stage0_regf = Stage0_a {
			nan_flag : fv_check_for_nan(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2,dIn.nanflag1,dIn.nanflag2),
			zero_infinity_flag : fv_check_for_z_i(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2),
			sign1 : dIn.sign1,
			scale1 : dIn.scale1,
			frac1 : extend(dIn.frac1)<<valueOf(FracWidth),
			sign2 : dIn.sign2,
			scale2 : dIn.scale2,
			frac2 : extend(dIn.frac2)<<valueOf(FracWidth),
			zero_flag : dIn.zero_infinity_flag1 == ZERO ? 2'b01 : ( dIn.zero_infinity_flag2 == ZERO ? 2'b10 : 2'b00)};
   		fifo_stage0_reg.enq(stage0_regf);
		//$display(" dIn.frac1 %b dIn.frac2 %b",dIn.frac1,dIn.frac2);
   endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule
	
endpackage: Adder

