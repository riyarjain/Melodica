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

package Common_Fused_Op;

// --------------------------------------------------------------
// This package defines:
//
//common functions between fma and fda
// --------------------------------------------------------------

import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;

typedef struct {Bit#(1) sign1;
		Bit#(1) nanflag1;
		PositType zero_infinity_flag1;
		Int#(ScaleWidthPlus1 ) scale1;
		Bit#(FracWidth ) frac1;
		Bit#(1) sign2;
		Bit#(1) nanflag2;
		PositType zero_infinity_flag2;
		Int#(ScaleWidthPlus1 ) scale2;
		Bit#(FracWidth ) frac2;} Inputs_md deriving(Bits,FShow);
//Input_posit is the data received from user
//Input_posit consists of zero flag, infinity flag, sign of posit, scale , fraction for 2 inputs

typedef struct {PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Int#(QuireWidth) quire_md;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;
		} Outputs_md deriving(Bits,FShow);
//Output_posit is the data available at the end of second pipeline
//Output_posit consists of zero flag, infinity flag, sign of posit, scale value, fraction value

	//This function finds the sum of the scale bits since the scale value has 2^scale contribution in the product
	function Int#(ScaleWidthPlus2) calculate_sum_scale(Int#(ScaleWidthPlus1 ) s1,Int#(ScaleWidthPlus1)s2);
			Int#(ScaleWidthPlus2) scale;
			//Scale is calculated as the sum of the respective scale
			scale = signExtend(s1)+signExtend(s2);
			return scale;
	endfunction

	//This function will be used to get the carry-Int-Frac value from the scale and frac value got from multiplying the values
	function Tuple4#(Bit#(IntWidthQuirePlusFracWidthQuire),Bit#(CarryWidthQuire),Bit#(1),Bit#(1)) calculate_frac_int(Bit#(t) f, Int#(ScaleWidthPlus2) s, Bit#(1) truncated_frac_msb_in, Bit#(1) truncated_frac_zero_in)
provisos (Add#(a__,t,TAdd#(FracWidthQuire,2)), Add#(b__,CarryWidthQuire,t), Add#(c__,t,IntWidthQuirePlusFracWidthQuire));
		let frac_width = valueOf(t) - 2;
		Bit#(IntWidthQuirePlusFracWidthQuire) f_new = extend(f);
		//first two bits of fraction are integer bits so if scale = 0 we have to shift fract left by FWQ-(FW*2 or (no_of_frac_bits_input - 2))
		//Thus frac_shift = FWQ-(FW*2 or (no_of_frac_bits_input - 2)) + scale(signed sum)
		// if input scale is negative beyond and extent s.t fracshift < 0
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_neg_temp = abs(signExtend(s)) - fromInteger(valueOf(FracWidthQuire));//scale_neg_temp = abs(s)-FWQ
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_neg = scale_neg_temp + fromInteger(frac_width);//frac_shift = scale_neg = abs(s) - (FWQ-(FW*2 or (no_of_frac_bits_input - 2)))
		// if input scale is negative beyond and extent s.t fracshift > 0
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_pos = signExtend(s) + fromInteger(valueOf(FracWidthQuire)-frac_width);// frac_shift = scale_pos = s + FWQ-(FW*2 or (no_of_frac_bits_input - 2))
		Bit#(1) truncated_frac_msb = truncated_frac_msb_in;
		Bit#(1) truncated_frac_zero = ~truncated_frac_msb_in & truncated_frac_zero_in;
		Bit#(CarryWidthQuire) carry = '0;
		if(msb(s) == 1'b1 && scale_neg>0)
			begin
				f_new = f_new>>scale_neg;// if frac_shift < -(FWQ-(FW*2 or (no_of_frac_bits_input - 2))) the scale will be shifted right and we will lose frac bits since the maximum available shift = FWQ-(FW*2 or (no_of_frac_bits_input - 2))
				truncated_frac_msb = scale_neg>0 ? f[scale_neg-1] : 1'b0;//in the truncated bits see the msb
				Bit#(IntWidthQuirePlusFracWidthQuire) mask1 = ~('1>>scale_neg-1);
				truncated_frac_zero = scale_neg>1 ? ((extend(f) & mask1) == 0 ? 1'b1 : 1'b0) :1'b1;////in the truncated bits see the leftover bits other than msb
			end 
		else
			begin
				f_new = f_new<<scale_pos;// right shift to accomodate the scale
				if(scale_neg_temp+2>0)
					//carry = extend(f[valueOf(FracWidthMul2Plus1):valueOf(FracWidthMul2)]);
					carry = truncate(f>>(fromInteger(frac_width)-scale_neg_temp));
					// nuw we can have over flow from the integer bits if the scale is large
					//total shift = S_pos, carry starts at SWQ+FWQ, so spos>SWQ+FWQ gives condition for carry
			end	
		return tuple4(f_new,carry,truncated_frac_msb,truncated_frac_zero);
	endfunction
			

endpackage: Common_Fused_Op
