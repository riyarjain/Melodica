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

package Adder_Types;

import GetPut       :: *;
import ClientServer :: *;
import FShow :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;
import Multiplier_Types ::*;
typedef struct {Quire q1;
		Outputs_m q2;} Inputs_a deriving(Bits,FShow);
//Input_posit is the data received from user

typedef struct {Int#(QuireWidth) sum_calc;
		Bit#(1) q2_truncated_frac_zero;
		Bit#(1) q2_truncated_frac_notzero;
		PositType q1_zero_infinity_flag;
		PositType q2_zero_infinity_flag;
		Bit#(1) q2_nan_flag;} Stage0_a deriving(Bits,FShow);

interface Adder_IFC ;
   interface Server #(Inputs_a,Bit#(QuireWidth)) inoutifc;
endinterface

endpackage: Adder_Types
