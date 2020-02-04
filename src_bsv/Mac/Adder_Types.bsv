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

package Adder_Types;

import GetPut       :: *;
import ClientServer :: *;
import FShow :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;
typedef struct {Bit#(1) sign1;
		Bit#(1) nanflag1;
		PositType zero_infinity_flag1;
		Int#(ScaleWidthPlus1 ) scale1;
		Bit#(FracWidthMul4 ) frac1;
		Bit#(1) round_frac_f1;
		Bit#(1) sign2;
		Bit#(1) nanflag2;
		PositType zero_infinity_flag2;
		Int#(ScaleWidthPlus1 ) scale2;
		Bit#(FracWidth ) frac2;
		Bit#(1) round_frac_f2;} Inputs_a deriving(Bits,FShow);
//Input_posit is the data received from user
//Input_posit consists of zero, nan, zero-infinity flag, sign of posit, scale , fraction, round_frac(if frac has been rounded earlier) bit for 2 inputs
typedef struct {Bit#(1) nan_flag;
		PositType zero_infinity_flag;
		Bit#(1) sign1;
		Int#(ScaleWidthPlus1 ) scale1;
		Bit#(FracWidthMul4 ) frac1;
		Bit#(1) round_frac_f1;
		Bit#(1) sign2;
		Int#(ScaleWidthPlus1 ) scale2;
		Bit#(FracWidthMul4 ) frac2;
		Bit#(1) round_frac_f2;
		Bit#(2) zero_flag;} Stage0_a deriving(Bits,FShow);
//Stage0 is the data available at the end of first pipeline
//Stage0 consists of nan_flag, zero flag(to check if any of the two nos are zero), zero-infinity flag, (sign of posit, scale , fraction,round_frac) for 2 inputs
typedef struct {Bit#(1) nan_flag;
		PositType zero_infinity_flag;
		Int#(ScaleWidthPlus1) scale;
		Bit#(1) sign1;
		Bit#(FracWidthMul4) frac1;
		Bit#(1) sign2;
		Bit#(FracWidthMul4) frac2;
		Bit#(1) round_frac_f1;
		Bit#(1) round_frac_f2;} Stage1_a deriving(Bits,FShow);
//Stage1 is the data available at the end of second pipeline
//Stage1 consists of nan_flag, zero-infinity flag, scale , (sign of posit, fraction,rounf_frac) for 2 inputs

typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Int#(ScaleWidthPlus1 ) scale;
		Bit#(FracWidth) frac;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Outputs_a deriving(Bits,FShow);
//Output_posit is the data available at the end of second pipeline
//Output_posit consists of zero-infinity flag, sign of posit, scale value, fraction value,msb truncated frac,rest of the truncated frac is zero or not

//module mkPipeline_reg #(Int#() n) (Empty);

interface Adder_IFC ;
   interface Server #(Inputs_a,Outputs_a) inoutifc;
endinterface

endpackage
