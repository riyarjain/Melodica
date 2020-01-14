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
