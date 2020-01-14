package Pipeline_reg_N;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Bit#(ScaleWidthPlus1) scale;
		Bit#(FracWidth) frac;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Input_value_n deriving(Bits,FShow);
//Input_value is the data received from user
//Input_value consists of sign of posit, zero and infinity flag, NaN flag, scale bits, fraction field
//of the fraction bits that were truncated due to size reduction, truncated_frac_msb gives the MSB of the truncated bits and truncated_frac_zero checks if all the other bits(other than msb) of the trucated fraction are zero or not: if all bits are zero the  truncated_frac_zero = 1
typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Bit#(PositWidthMinus1) k;
		Bit#(ExpWidth) expo;
		Bit#(FracWidth) frac;
		UInt#(BitsPerPositWidth) no_of_bit_k;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Stage0_n deriving(Bits,FShow);
//Stage0_n consists of sign of posit, zero and infinity flag, NaN flag, regime field, exponent field, fraction field, number of bits in regime field
typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Bit#(PositWidthMinus1) k_expo;
		Bit#(FracWidth) frac;
		UInt#(BitsPerPositWidth) no_of_bit_k;
		UInt#(BitsPerPositWidth) shift_1;
		Bit#(1) flag_endcase;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Stage1_n deriving(Bits,FShow);
//Stage1_n is the data available at the end of second pipeline
//Stage1_n consists of sign of posit, zero and infinity flag, NaN flag, regime and exponent field combined, fraction field, number of bits in regime field
//

typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Bit#(PositWidthMinus1) k_expo_frac;} Stage2_n deriving(Bits,FShow);
//Stage2_n is the data available at the end of second pipeline
//Stage2_n consists of sign of posit, zero and infinity flag, NaN flag, regime and exponent and fraction field combined

typedef struct {Bit#(1) nan_flag;
		Bit#(PositWidth) out_posit;} Output_posit_n deriving(Bits,FShow);
//Output_posit is the data available at the end of second pipeline
//Output_posit consists of  NaN flag, posit as output

//module mkPipeline_reg #(Int#() n) (Empty);

endpackage: Pipeline_reg_N
