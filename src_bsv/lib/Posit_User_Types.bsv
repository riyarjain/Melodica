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
	typedef TAdd#(FracWidth,FracWidth)				FracWidthMul2 		;//Frac_size_quire
	typedef TAdd#(FracWidth,1)				        FracWidthPlus1 		;//Frac_size_quire
	typedef TAdd#(FracWidthMul2,1)					FracWidthMul2Plus1	;//FracWidthMul2Plus1 = FracWidth*2 + 1
	typedef TAdd#(FracWidthMul2Plus1,1)				FracWidthPlus1Mul2	;//FracWidthPlus1Mul2 = (FracWidth+2)*2
	typedef TSub#(FracWidth,1)					FracWidthMinus1 	;//FracWidthMinus1 = FracWidth - 1
	typedef TLog#(FracWidth)					LogFracWidth		;//LogFracWidth = log(FracWidth)
	typedef TAdd#(LogFracWidth,1)					LogFracWidthPlus1	;//LogFracWidthPlus1 = LogFracWidth + 1
	typedef TAdd#(ExpWidth,1) 					ExpWidthPlus1		;//ExpWidthPlus1 = ExpWidth + 1		
	
	//MAC
	typedef TMul#(FracWidth,4)					FracWidthMul4 		;//FW*4 = FW4
	typedef TAdd#(ScaleWidthPlus1,1)				ScaleWidthPlus2 	;//ScaleWidth + 2
	typedef TAdd#(FracWidthMul4,1)					FracWidthMul4Plus1	;//FW4+1
	typedef TAdd#(FracWidthMul4Plus1,1)				FracWidthMul4Plus2	;//FW4+2
	typedef TSub#(FracWidthMul4,FracWidth)				FracWidthMul4MinusFracWidth;//FW4-FW
	typedef TSub#(FracWidthMul4MinusFracWidth,FracWidth)		FracWidthMul4MinusFracWidthMul2;//FWQ-2*FW
	typedef TSub#(FracWidthMul4MinusFracWidth,1)			FracWidthMul4MinusFracWidthMinus1;//FW4-FW-1
	typedef TAdd#(FracWidthMul4MinusFracWidth,1)			FracWidthMul4MinusFracWidthPlus1;//FW4-FW+1
	typedef TLog#(FracWidthMul4)					LogFracWidthMul4	;//logFW4
	typedef TAdd#(FracWidthMul4,1)					LogFracWidthMul4Plus1	;//logFW4+1	

	//FDP
	typedef TDiv#(TMul#(PositWidth,PositWidth),2)				QuireWidth;//QW = (PW^2)/2
	typedef TSub#(QuireWidth,2)						QuireWidthMinus2;//QW-2
	typedef TDiv#(QuireWidth,2)						QuireWidthBy2;//QW/2
	typedef TDiv#(PositWidth,2)						PositWidthBy2;//PW/2
	typedef TSub#(QuireWidthBy2,PositWidthBy2)				FracWidthQuire 	;//FWQ = QW/2 - PW/2
	typedef TSub#(PositWidth,1)						CarryWidthQuire ;//PW-1
	typedef FracWidthQuire							IntWidthQuire;//= FWQ
	typedef TSub#(QuireWidth,1)						QuireWidthMinus1;//QW-1
	typedef QuireWidthMinus1 						CarryWidthPlusIntWidthPlusFracWidthQuire;//QW-1= CWQ+FWQ+IWQ
	typedef TLog#(CarryWidthPlusIntWidthPlusFracWidthQuire)			LogCarryWidthPlusIntWidthPlusFracWidthQuire;//log(QW-1)
	typedef TSub#(FracWidthQuire,FracWidth)					FracWidthQuireMinusFracWidth;//FWQ-FW
	typedef TSub#(FracWidthQuireMinusFracWidth,FracWidth)			FracWidthQuireMinusFracWidthMul2;//FWQ-FracWidth*2
	typedef TAdd#(FracWidthQuire,IntWidthQuire)				IntWidthQuirePlusFracWidthQuire;//IWQ+FWQ

	//Q-TO-P
	typedef TAdd#(LogCarryWidthPlusIntWidthPlusFracWidthQuire,1)		LogCarryWidthPlusIntWidthPlusFracWidthQuirePlus1;
	typedef TAdd#(CarryWidthQuire,IntWidthQuire)				CarryWidthPlusIntWidthQuire;
	typedef	TSub#(QuireWidthMinus2,FracWidth) 				QuireWidthMinus2MinusFracWidth;	
	typedef	TSub#(QuireWidthMinus2MinusFracWidth,1) 			QuireWidthMinus3MinusFracWidth;

	//f-To-P
	typedef TSub#(TAdd#(FloatFracWidth,FloatExpWidth),1) 			FloatExpoBegin; //(FloatFracWidth+FloatExpWidth-1)
	typedef TAdd#(FloatExpWidth,1) 						FloatExpWidthPlus1; //(FloatExpWidth+1)
	typedef TSub#(FloatFracWidth,1) 					FloatFracWidthMinus1; //(FloatFracWidth-1)
	typedef TSub#(FloatFracWidth,FracWidth)					FloatFracWidthMinusFracWidth; //(FloatFracWidth-FracWidth)
	typedef TSub#(FloatFracWidthMinusFracWidth,1)				FloatFracWidthMinusFracWidthMinus1;
	typedef TSub#(FloatFracWidthMinusFracWidth,2)				FloatFracWidthMinusFracWidthMinus2;

	typedef struct {Bit#(PositWidth) posit_inp1;
			Bit#(PositWidth) posit_inp2;
			} InputTwoPosit deriving(Bits,FShow);

	typedef struct {Bit#(PositWidth) posit_inp1;
			Bit#(PositWidth) posit_inp2;
			Bit#(PositWidth) posit_inp3;
			} InputThreePosit deriving(Bits,FShow);

	typedef struct {Bit#(1) sign;
			Bit#(1) nan_flag;
			PositType zero_infinity_flag;
			Bit#(CarryWidthPlusIntWidthPlusFracWidthQuire) carry_int_frac;
			} Quire deriving(Bits,FShow);
	
	typedef struct {Bit#(QuireWidth) quire_inp;
			Bit#(PositWidth) posit_inp1;
			Bit#(PositWidth) posit_inp2;
			} InputQuireTwoPosit deriving(Bits,FShow);


	//generic fuction to find Two's complement for any number
	function Bit#(n) twos_complement(Bit#(n) x);
		//truncate from log(n-1) bits to log(n-1)-1 bits
		return (truncate((1<<(valueOf(n)+1))-x)) ;	
	endfunction
endpackage: Posit_User_Types
