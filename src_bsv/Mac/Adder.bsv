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
// THE SOFTWARE.package Extracter_Types;

package Adder;

// --------------------------------------------------------------
// This package defines:
//
//    mkAdder: 3-stage adder which computes the sum of 2 posits
// --------------------------------------------------------------

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils :: *;
import Adder_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;

module mkAdder (Adder_IFC );
	// make a FIFO to store data at the end of each stage of the pipeline, and also for input and outputs
	FIFOF #(Inputs_a )   fifo_input_reg <- mkFIFOF;
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
	/* if scale of 1st number > scale of 2nd number
			scale of output = scale of 1st number
			new fractional value of 2nd number = fractional value of 2nd number shifted right by the difference of scale sizes to match scales 
		similarly for the other case
	*/
	// we get the value of scale_shift using signed subtraction
	// Input : scales, fractions and zf- telling if any of the number is zero
	function Tuple5#(Int#(ScaleWidthPlus1), Bit#(FracWidthMul4), Bit#(FracWidthMul4),Bit#(1),Bit#(1)) fv_calculate_scale(Int#(ScaleWidthPlus1 ) s1,Int#(ScaleWidthPlus1)s2,Bit#(FracWidthMul4)f1,Bit#(FracWidthMul4)f2, Bit#(2) zf);
		Int#(ScaleWidthPlus1) scale_shift;
		Bit#(FracWidthMul4) one = '1;// all 1s
		//1st number is zero
		if (zf == 2'b01)
			//take the special case when 1st number is zero, there will be no scale shifting & hence no rounding for 2nd number
			return tuple5(s2,'0,f2,1'b0,1'b0);
		//2nd number is zero		 
		else if (zf == 2'b10)
			//take the special case when 2nd number is zero, there will be no scale shifting & hence no rounding for 1st number
			return tuple5(s1,f1,'0,1'b0,1'b0); 
		else if (s1>s2)
			//when 1st number scale is larger than other
			begin
				scale_shift = s1-s2;// find the shift in fraction bits required
				Bit#(1) round_frac = (f2 & ~(one << scale_shift)) ==  0? 1'b0 : 1'b1;// in those shifted fraction bits if any data is lost is stored in round_frac, i.e. if all the fraction bits shifted is 0 then only the round_frac = 0
				return tuple5(s1,f1,(f2>>scale_shift),1'b0,round_frac);//send frac bits after shiting
			end
		else
			begin
				scale_shift = s2-s1;// find the shift in fraction bits required
				Bit#(1) round_frac = (f1 & ~(one << scale_shift)) ==  0? 1'b0 : 1'b1;// in those shifted fraction bits if any data is lost is stored in round_frac, i.e. if all the fraction bits shifted is 0 then only the round_frac = 0
				return tuple5(s2,(f1>>scale_shift),f2,round_frac,1'b0);//send frac bits after shiting
			end
	endfunction
	
	//This function checks if the scale value has exceeded the limits max and min set due to the restricted availability of regime bits
	// fraction bits will be shifted to take care of the scale value change due to it being bounded
	//output : bounded scale value and the shift in frac bits
	function Tuple2#(Int#(ScaleWidthPlus1), Int#(LogFracWidthPlus1)) fv_calculate_scale_shift(Int#(ScaleWidthPlus2) scale);
			Int#(ScaleWidthPlus1) maxB,minB,scale0;
			Int#(LogFracWidthPlus1) frac_change;
			//max scale value is defined here... have to saturate the scale value 
			// max value = (N-2)*(2^es) 
			// scale = regime*(2^es) + expo.... max value of regime = N-2(00...1)
			maxB = fromInteger((valueOf(PositWidth) -2)*(2**(valueOf(ExpWidth))));
			//similarly calculate the min 
		 	minB = -maxB;
			//frac_change gives the number of bits that are more or less than scale bounds so that we can shift the frac bits to not lose scale information 
			if (scale < signExtend(minB))
				begin
				frac_change = truncate(boundedMinus(scale,signExtend(minB)));// find the change in scale to bind it 
				scale0 = minB;//bound scale
				end
			else if (scale> signExtend(maxB))
				begin
				frac_change = truncate(boundedMinus(scale,signExtend(maxB)));// find the change in scale to bind it 
				scale0 = maxB;//bound scale
				end
			else
				begin
				frac_change = fromInteger(0);
				scale0 = truncate(scale);//no change
				end
			return tuple2(scale0,frac_change);

	endfunction

	// This function calculates the output scale and fractional value
	// Input : signs, scale, fracs,round_fracs
	// Output : sign, scale, fraction, round_frac, frac_change
	function Tuple5#(Bit#(1), Int#(ScaleWidthPlus1),Bit#(FracWidthMul4),Bit#(1),Int#(LogFracWidthPlus1)) fv_calculate_sum(Bit#(1) sgn1,Bit#(1)sgn2, Int#(ScaleWidthPlus1) s,Bit#(FracWidthMul4)f1,Bit#(FracWidthMul4)f2,Bit#(1) round_frac_f1,Bit#(1) round_frac_f2);
		Bit#(FracWidthMul4Plus1)frac_sum;
		Bit#(ScaleWidthPlus1) frac_shift;
		Int#(ScaleWidthPlus2) s1;
		Bit#(FracWidthMul4Plus1) mask = '1;
		//Bit#(LogFracWidthMul4Plus1) zero_one_1 = valueOf(ScaleWidthPlus1)>=valueOf(LogFracWidthMul4Plus1)?'1:extend(zero_one);
		Bit#(1) round_frac = round_frac_f1 | round_frac_f2;//now if any one is also high means that there was a frac rounding before so we check if any one had a frac rounding it will be affect in output rounding
		Bit#(FracWidthMul4) frac_trunc;

		//conditional statement order important
		if (unpack(~(sgn1^ sgn2)))//if the numbers have the same sign
			begin
			//add the fractional values since same sign of inputs
			frac_sum = extend(f1) + extend(f2);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift =  fv_frac_shit_adder_mac(frac_sum);
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by or to scale)
			s1 = boundedMinus(signExtend(s) , unpack(extend(frac_shift)-1));//this just bound till the end points we need stricter bounds to max and min value so use calculate scale shift for the bounds
			match {.scale0,.frac_change0} = fv_calculate_scale_shift(s1);//after applying stricter bound on scale
			// now we are shifting the frac_sum but left or right shifts depends since the shit takes only unsigned value so have to make the parameter positive
			if(frac_shift > 1)
				frac_trunc = truncate(frac_sum<<(frac_shift-1));//frac_truncate is frac_sum that is shifted to make msb = 1, the minus 1 is coz there is 1 hidden bit
			else
				begin
				frac_trunc = truncate(frac_sum>>(1-frac_shift));
				mask = mask << (1-frac_shift);// mask to see which bits have been shifted
				end
			Bit#(1) frac_sum_shift = (frac_sum & ~mask) ==  0? 1'b0 : 1'b1;// this checks if the bits shifted had some info.. if the frac had been rounded, also we may have the inputs already rounded. Now since we are adding the numbers the rounded of the input and the ouput would not cancel each other they will add up
			return tuple5(sgn1,scale0,frac_trunc,round_frac | frac_sum_shift,frac_change0);
			end
		//depending on which fractional size is greater	
		else if(f1>=f2)
			begin
			//subtract the fractional since different sign of inputs
			// now the 2md n 1st fraction could have been rounded
			//if both are rounded since the first number is larger ????????????????????????????????????????????????
			// if 2nd is rounded and not 1st
			frac_sum = extend(f1) - extend(f2) - extend(round_frac_f2 & ~round_frac_f1);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift =  fv_frac_shit_adder_mac(frac_sum);
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by scale) 
			s1 = boundedMinus(signExtend(s) , unpack(extend(frac_shift)-1));//this just bound till the end points we need stricter bounds to max and min value so use calculate scale shift for the bounds
			match {.scale0,.frac_change0} = fv_calculate_scale_shift(s1);//after applying stricter bound on scale
			// now we are shifting the frac_sum but left or right shifts depends since the shit takes only unsigned value so have to make the parameter positive
			if(frac_shift > 1)
				frac_trunc = truncate(frac_sum<<(frac_shift-1));//frac_truncate is frac_sum that is shifted to make msb = 1, the minus 1 is coz there is 1 hidden bit
			else
				frac_trunc = truncate(frac_sum>>(1-frac_shift));
			// sign of the input whose fractional value is greater
			return tuple5(sgn1,scale0,frac_trunc,round_frac,frac_change0);
			end
		else
			begin
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_sum = extend(f2) - extend(f1) - extend(round_frac_f1);
			// have to shift the fractional output value so that the first bit is 1(hidden bit is 1), so count the number of 0s
			frac_shift =  fv_frac_shit_adder_mac(frac_sum);
			//scale = scale + 1 (sum of hidden bit leads to an extension 1 bit) - (the number of bits the fractional bits had to be shifted will be provided by scale)
			s1 = boundedMinus(signExtend(s) , unpack(extend(frac_shift)-1));//this just bound till the end points we need stricter bounds to max and min value so use calculate scale shift for the bounds
			match {.scale0,.frac_change0} = fv_calculate_scale_shift(s1);//after applying stricter bound on scale
			// now we are shifting the frac_sum but left or right shifts depends since the shit takes only unsigned value so have to make the parameter positive
			if(frac_shift > 1)
				frac_trunc = truncate(frac_sum<<(frac_shift-1));//frac_truncate is frac_sum that is shifted to make msb = 1, the minus 1 is coz there is 1 hidden bit
			else
				frac_trunc = truncate(frac_sum>>(1-frac_shift));
			// sign of the input whose fractional value is greater
			return tuple5(sgn2,scale0,frac_trunc,round_frac,frac_change0);
			end
	endfunction


	// --------
        // Pipeline stages
	// stage_0: INPUT STAGE
	rule stage_0;
		//dIn reads the values from input pipeline register 
      		let dIn = fifo_input_reg.first;  fifo_input_reg.deq;
		// data to be stored in stored in fifo that will be used in stage 0
                let stage0_regf = Stage0_a {
			nan_flag : fv_check_for_nan(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2,dIn.nanflag1,dIn.nanflag2),
			zero_infinity_flag : fv_check_for_z_i(dIn.zero_infinity_flag1,dIn.zero_infinity_flag2),
			sign1 : dIn.sign1,
			scale1 : dIn.scale1,
			frac1 : dIn.frac1,// fraction already has the hidden bit in the quire
			round_frac_f1 : dIn.round_frac_f1,
			sign2 : dIn.sign2,
			scale2 : dIn.scale2,
			frac2 : extend({1'b1,dIn.frac2})<<valueOf(FracWidthMul4MinusFracWidthMinus1),//adding the hidden bit and extendng
			round_frac_f2 : dIn.round_frac_f2,
			zero_flag : dIn.zero_infinity_flag1 == ZERO ? 2'b01 : ( dIn.zero_infinity_flag2 == ZERO ? 2'b10 : 2'b00)};
   		fifo_stage0_reg.enq(stage0_regf);
		`ifdef RANDOM_PRINT
		$display(" dIn.frac1 %b dIn.frac2 %b",dIn.frac1,dIn.frac2);
		$display(" dIn.scale1 %b dIn.scale2 %b",dIn.scale1,dIn.scale2);
		`endif
   	endrule


	// STAGE 1: Calculating scale
	rule stage_1;
		//dIn reads the values from pipeline register stored from previous stage
		let dIn = fifo_stage0_reg.first;  fifo_stage0_reg.deq;
		// call function to get output fractional value after having matched the scale values for addition, and also if the frac has been rounded
		match{ .scale0, .frac10, .frac20, .round_frac_f10, .round_frac_f20} = fv_calculate_scale(dIn.scale1,dIn.scale2,dIn.frac1,dIn.frac2,dIn.zero_flag);
		// data to be stored in stored in fifo that will be used in stage 1		
		let stage1_regf = Stage1_a {
			nan_flag : dIn.nan_flag,
			zero_infinity_flag : dIn.zero_infinity_flag,
			scale : scale0,
			sign1 : dIn.sign1,
			frac1 : frac10,
			sign2 : dIn.sign2,
			frac2 : frac20,
			round_frac_f1 : round_frac_f10 | dIn.round_frac_f1,//check if there is any further rounding
			round_frac_f2 : round_frac_f20 | dIn.round_frac_f2};
			`ifdef RANDOM_PRINT
			$display("scale0 %b",scale0);
			$display("dIn.frac1 %b dIn.frac2 %b",frac10,frac20);
			$display("round_frac_f1 %b round_frac_f2 %b",round_frac_f10,round_frac_f20);
			`endif
		fifo_stage1_reg.enq(stage1_regf);
	endrule

	 
	//STAGE 2 -- OUTPUT and sum & shifting of fraction
	rule stage_2;
		//dIn reads the values from pipeline register stored from previous stage
		let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
		//calculate sum calculates the addition of fraction
		match{ .sign0,.scale0, .frac0, .round_frac0, .frac_change0} = fv_calculate_sum(dIn.sign1,dIn.sign2,dIn.scale,dIn.frac1,dIn.frac2,dIn.round_frac_f1, dIn.round_frac_f2);
		// data to be stored in stored in fifo that will be used in output
		// for zero infinity flag: have to recheck the output after the computations
		// number = zero if frac  = 0	

	PositType zero_infinity_flag0 = ((frac0 == 0 && round_frac0 == 1'b0 && dIn.zero_infinity_flag == REGULAR) ? ZERO :dIn.zero_infinity_flag);//????? check msb
		Bit#(LogFracWidthMul4Plus1) a = pack(fromInteger(valueOf(FracWidthMul4MinusFracWidthMinus1))+abs(signExtend(frac_change0)));
		Bit#(FracWidthMul4) mask1 = ~('1<<a-1);
		Bit#(FracWidthPlus1) frac_truncate = frac_change0<=0?truncate(frac0>>a):'1;
		let output_regf = Outputs_a {
			nan_flag : dIn.nan_flag,
			zero_infinity_flag : zero_infinity_flag0,
			scale : scale0,
			sign : sign0,
			frac : msb(frac_truncate) ==0?truncate(frac_truncate>>1):truncate(frac_truncate),
			// Frac_truncate is of size FWQ-1, we want the output of size FW;if the frac_change <0 that means the scale was actually less than min so we shift the frac bits right by frac_change to save the information, if frac_change>0 means we have scale more than max.. if we have to round this number we use scale = max and frac = max  
			truncated_frac_msb : zero_infinity_flag0 == ZERO ? 1'b0 :(frac_change0<=0?frac0[a-1]:1'b1),// so using the fraction bits shifted in the prev statement we see the msb of bits rounded; now if the output is 0 msb is set to 0
			truncated_frac_zero : zero_infinity_flag0 == ZERO ? 1'b1 : (frac_change0<=0? ~round_frac0 & ((frac0 & mask1) == 0? 1'b1:1'b0):1'b0)};// so using the fraction bits shifted and used in the prev statement we see the rest of bits rounded are all zero or not; now if the output is 0 all frac bits are 0 so value set to 1
		`ifdef RANDOM_PRINT
		$display("sign0",sign0);
		$display("frac0 %b",frac0>>(fromInteger(valueOf(FracWidthMul4MinusFracWidthMinus1))));
		$display("frac %b frac_change0 %b dIn.frac1 %b dIn.frac2 %b",frac0,frac_change0,dIn.frac1,dIn.frac2);
		$display("scale0 %b",scale0);
		$display("dIn.scale %b",dIn.scale);
		$display(" truncated_frac_msb %b truncated_frac_zero %b",output_regf.truncated_frac_msb,output_regf.truncated_frac_zero);
		`endif
		fifo_output_reg.enq(output_regf);
	endrule	
		
        interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);
endmodule

endpackage: Adder

