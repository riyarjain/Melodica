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

package Multiplier_Types_fma;

import GetPut       :: *;
import ClientServer :: *;
import FShow :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;
import Common_Fused_Op :: *;


typedef struct {Bit#(1) nan_flag;
		PositType ziflag;
		Bit#(1) sign;
		Int#(ScaleWidthPlus2) scale;
		Bit#(FracWidthPlus1Mul2) frac;} Stage0_m deriving(Bits,FShow);


interface Multiplier_IFC;
   interface Server #(Inputs_md,Outputs_md) inoutifc;
endinterface

endpackage: Multiplier_Types_fma
