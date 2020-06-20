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


package QuireToPosit_PC;

// --------------------------------------------------------------
// This package defines:
//
//    mkQuireToPosit: 3-stage pipeline that converts Quire to Posit
// --------------------------------------------------------------

// Library imports

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Normalizer_Types	:: *;
import Normalizer	:: *;
import QtoP_Types	:: *;


interface QuireToPosit_IFC;
   interface Server #(Bit#(0),Input_value_n) inoutifc;
endinterface

module mkQuireToPosit #(Reg #(Bit#(QuireWidth))  rg_quire) (QuireToPosit_IFC );
	FIFOF #(Input_value_n )  fifo_output_reg <- mkFIFOF;
	FIFOF #(Stage0_qp )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Input_value_n )  fifo_stage1_reg <- mkFIFOF;
	Int#(ScaleWidthPlus1) maxB,minB;
	//max scale value is defined here... have to saturate the scale value 
	// max value = (N-2)*(2^es) 
	// scale = regime*(2^es) + expo.... max value of regime = N-2(00...1)
	maxB = fromInteger((valueOf(PositWidth) -2)*(2**(valueOf(ExpWidth))));
	//similarly calculate the min 
	minB = -maxB;	
	
	//function checks for nan 100..00
	function Bit#(1) check_for_nan(Bit#(1) sign ,Bit#(1) all_bits_0,Bit#(1) nan_flag);
		if(sign == 1'b1 && all_bits_0 == 1'b1)
			return 1'b1;
		else
			return nan_flag;
	
	endfunction

	//function checks for zero and infinity
	function PositType check_for_zi(PositType zero_infinity_flag,Bit#(1) sign,Bit#(1) all_bits_0);
		if(sign == 1'b0 && all_bits_0 == 1'b1)
			return ZERO;
		else
			return zero_infinity_flag;
	
	endfunction


	//This function checks if the scale value has exceeded the limits max and min set due to the restricted availability of regime bits
	// fraction bits will be shifted to take care of the scale value change due to it being bounded
	//output : bounded scale value and the shift in frac bits
	function Int#(ScaleWidthPlus1) calculate_scale_shift(Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuirePlus1) scale);
			Int#(ScaleWidthPlus1) scale0;
			//frac_change gives the number of bits that are more or less than scale bounds so that we can shift the frac bits to not lose scale information 
			if (scale < signExtend(minB))
				begin
				scale0 = minB;//bound scale
				end
			else if (scale> signExtend(maxB))
				begin
				scale0 = maxB;//bound scale
				end
			else
				begin
				scale0 = truncate(scale);//no change
				end
			return scale0;

	endfunction

	// --------
        // Pipeline stages
	// stage_1: frac calculate
	rule stage_1;
		//dIn reads the values from pipeline register stored from previous stage
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		Bit#(FracWidthPlus1) frac0;
		//Bit#(1) scale_sign = msb(dIn.scale) == 1'b1 || dIn.scale == 0 ? 1'b1 : 1'b0;
		PositType zero_infinity_flag0 = ((dIn.carry_int_frac == 0 && dIn.zero_infinity_flag == REGULAR) ? ZERO :dIn.zero_infinity_flag);
		Bit#(1) truncated_frac_msb0;
		Bit#(1) truncated_frac_zero0; 
		if(dIn.scale < maxB)
			begin
				//interpret the scale to know number of frac bit shits required - this is got by the maximum available shit possible - the shift done to compensate for the scale
				UInt#(LogCarryWidthPlusIntWidthPlusFracWidthQuirePlus1)  truncate_msbZeros = unpack(pack(fromInteger(valueof(CarryWidthPlusIntWidthQuire)) - signExtend(dIn.scale) - 1));
				//shift to get the frac bits 
				let carry_int_frac_shifted =  (dIn.carry_int_frac << truncate_msbZeros);
				//interpret the frac bits from the shited quire bits
				frac0 = carry_int_frac_shifted[valueOf(QuireWidthMinus2):valueOf(QuireWidthMinus2MinusFracWidth)];
				truncated_frac_msb0 = carry_int_frac_shifted[valueOf(QuireWidthMinus3MinusFracWidth)];//check the truncated bit msb
				//get the remaining bits by truncating it to see if they are all 0's
				Bit#(QuireWidthMinus3MinusFracWidth) truncate_carry_int_frac_shifted = truncate(carry_int_frac_shifted);
				truncated_frac_zero0 = (truncate_carry_int_frac_shifted ==  0? 1'b1 : 1'b0);
			end
		else
			begin
				//the case when the value has overflown
				frac0 = '1;
				truncated_frac_msb0 = 1'b1;
				truncated_frac_zero0 = 1'b0;
			end
		// data to be stored in stored in fifo that will be used in stage 1		
		let stage1_regf = Input_value_n  {
			sign : dIn.sign,
			nan_flag : dIn.nan_flag,
			zero_infinity_flag : dIn.zero_infinity_flag,
			scale : pack(dIn.scale) ,
		 	frac : msb(frac0) == 0 ? truncate(frac0>>1):truncate(frac0),
			truncated_frac_msb :zero_infinity_flag0 == ZERO ? 1'b0 : truncated_frac_msb0,
			truncated_frac_zero : zero_infinity_flag0 == ZERO ? 1'b1 :truncated_frac_zero0};
		`ifdef RANDOM_PRINT
		`endif
		fifo_stage1_reg.enq(stage1_regf);
	endrule

	// stage_2: Normalizer
	rule stage_2;
		//normalizes the posit field
		let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
		fifo_output_reg.enq(Input_value_n {
		sign: dIn.sign,
	 	zero_infinity_flag: dIn.zero_infinity_flag ,
		nan_flag: dIn.nan_flag,
		scale : dIn.scale ,
		frac : dIn.frac,
		truncated_frac_msb : dIn.truncated_frac_msb,
		truncated_frac_zero : dIn.truncated_frac_zero});
	endrule

	


interface Server inoutifc;
      interface Put request;
         method Action put (Bit#(0) p);
		// stage_0: INPUT STAGE, scale nan ziflag calculation
		//depending on sign inteprets the rest for the bits
		Bit#(QuireWidthMinus1) carry_int_frac = rg_quire[valueOf(QuireWidthMinus2):0];
		Bit#(CarryWidthPlusIntWidthPlusFracWidthQuire) twos_complement_carry_int_frac = msb(rg_quire) == 1'b0 ? carry_int_frac : twos_complement(carry_int_frac);
		//checking underflow/overflow
		Bit#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) msbZeros = pack(countZerosMSB(twos_complement_carry_int_frac));
		//checulating scale based on the carry and int bits
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuirePlus1) scale_temp = boundedMinus(fromInteger(valueof(CarryWidthPlusIntWidthQuire)), (unpack(extend(msbZeros))+1));
		Bit#(1) all_bits_0 = (carry_int_frac == 0)?1'b1:1'b0;
		let stage0_regf = Stage0_qp {
			sign : msb(rg_quire),
			nan_flag : check_for_nan(msb(rg_quire),all_bits_0,1'b0),
			zero_infinity_flag : check_for_zi(REGULAR,msb(rg_quire),all_bits_0),
			scale : calculate_scale_shift(scale_temp),//calculates the scale
			carry_int_frac : twos_complement_carry_int_frac};
		fifo_stage0_reg.enq(stage0_regf);
		`ifdef RANDOM_PRINT
			$display("sign %b scale %b carry_int_frac %b",stage0_regf.sign,stage0_regf.scale,stage0_regf.carry_int_frac);
		`endif
   	endrule

   	endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule
endpackage: QuireToPosit_PC
