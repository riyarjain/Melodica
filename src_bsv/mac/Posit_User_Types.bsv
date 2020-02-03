
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

package Posit_User_Types;
import Posit_Numeric_Types :: *;

	typedef enum {REGULAR, INF, ZERO} PositType deriving(Bits, Eq, FShow);
	typedef TMul#(PositWidth,PositWidth)	QuireWidth;
	typedef TMul#(TAdd#(FracWidth,FracWidth),2)				FracWidthQuire 	;//Frac_size_quire
	typedef TAdd#(ScaleWidthPlus1,ScaleWidthPlus1)			ScaleWidthQuire ;//scale_size_quire
	typedef TAdd#(ScaleWidthPlus1,1)			ScaleWidthPlus2 ;//scale_size_quire
	typedef TAdd#(FracWidth,1)				        FracWidthPlus1 	;//Frac_size_quire
	typedef TAdd#(FracWidthQuire,1)					FracWidthQuirePlus1	;
	typedef TAdd#(FracWidthQuirePlus1,1)				FracWidthQuirePlus2	;
	typedef TAdd#(ScaleWidthQuire,1)				ScaleWidthQuirePlus1	;
	typedef TSub#(FracWidth,1)					FracWidthMinus1 	;//Frac_size_quire
	typedef TSub#(FracWidthQuire,1)					FracWidthQuireMinus1;
	typedef TSub#(FracWidthQuire,FracWidth)				FracWidthQuireMinusFracWidth;
	typedef TSub#(FracWidthQuireMinusFracWidth,FracWidth)		FracWidthQuireMinusFracWidthMul2;//FWQ-2*FW
	typedef TSub#(FracWidthQuireMinusFracWidth,1)			FracWidthQuireMinusFracWidthMinus1;
	typedef TAdd#(FracWidthQuireMinusFracWidth,1)			FracWidthQuireMinusFracWidthPlus1;
	typedef TLog#(FracWidth)					LogFracWidth;
	typedef TAdd#(LogFracWidth,1)					LogFracWidthPlus1;
	typedef TLog#(FracWidthQuire)					LogFracWidthQuire;//logFWQ+1
	typedef TAdd#(LogFracWidthQuire,1)				LogFracWidthQuirePlus1;//logFWQ+1
	typedef TAdd#(ExpWidth,1) 					ExpWidthPlus1;
	typedef struct {Bit#(PositWidth) posit_inp1;
			Bit#(PositWidth) posit_inp2;
			Bit#(PositWidth) posit_inp3;
			} InputThreePosit deriving(Bits,FShow);
	// twos_complement function is used to find the two's complement of a number of n bit
	// the function gives ouput = 2^n - x
	function Bit#(n) twos_complement(Bit#(n) x);
		//truncate from log(n-1) bits to log(n-1)-1 bits
		return (truncate((1<<(valueOf(n)+1))-x)) ;	
	endfunction



endpackage: Posit_User_Types
