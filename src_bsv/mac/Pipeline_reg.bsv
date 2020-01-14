package Pipeline_reg;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
typedef struct {Bit#(PositWidth) posit_inp;
	} Input_posit deriving(Bits,FShow);
//Input_posit is the data received from user
//Input_posit consists of nPositWidth bit input and value of es
typedef struct {PositType zero_infinity_flag;
		Bit#(1) sign;
		Bit#(PositWidthMinus1) new_inp0;} Stage0 deriving(Bits,FShow);
//Stage0 is the data available at the end of first pipeline
//Stage0 consists of zero flag, infinity flag, sign of posit, reduced new input got after removing the sign bit
typedef struct {PositType zero_infinity_flag;
		Bit#(1) sign;
		Int#(RegimeWidth) k;
		Bit#(PositWidthMinus3) new_inp1;
		UInt#(Iteration) iteration;} Stage1 deriving(Bits,FShow);
//Stage1 is the data available at the end of second pipeline
//Stage1 consists of zero flag, infinity flag, sign of posit, regime value,
// reduced new input got after removing the sign bit and 2 bit for bits for regime field,
// iteration gives the location in the input till where the data has been interpreted
typedef struct {PositType zero_infinity_flag;
		Bit#(1) sign;
		Int#(TAdd#(RegimeWidth,ExpWidth)) k_scale ;
		Bit#(ExpWidth) expo;
		Bit#(FracWidth) frac;} Stage2 deriving(Bits,FShow);
//Stage2 is the data available at the end of second pipeline
//Stage2 consists of zero flag, infinity flag, sign of posit, k value, exponent value, fraction value

typedef struct {PositType zero_infinity_flag;
		Bit#(1) sign;
		Int#(ScaleWidthPlus1) scale;
		Bit#(FracWidth) frac;} Output_posit deriving(Bits,FShow);
//Output_posit is the data available at the end of second pipeline
//Output_posit consists of zero flag, infinity flag, sign of posit, scale value, fraction value

//module mkPipeline_reg #(Int#() n) (Empty);

endpackage: Pipeline_reg
