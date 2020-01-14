package Pipeline_reg_A;
import FShow :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;
typedef struct {Bit#(1) sign1;
		Bit#(1) nanflag1;
		PositType zero_infinity_flag1;
		Int#(ScaleWidthPlus1 ) scale1;
		Bit#(FracWidthQuire ) frac1;
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
		Bit#(FracWidthQuire ) frac1;
		Bit#(1) round_frac_f1;
		Bit#(1) sign2;
		Int#(ScaleWidthPlus1 ) scale2;
		Bit#(FracWidthQuire ) frac2;
		Bit#(1) round_frac_f2;
		Bit#(2) zero_flag;} Stage0_a deriving(Bits,FShow);
//Stage0 is the data available at the end of first pipeline
//Stage0 consists of nan_flag, zero flag(to check if any of the two nos are zero), zero-infinity flag, (sign of posit, scale , fraction,round_frac) for 2 inputs
typedef struct {Bit#(1) nan_flag;
		PositType zero_infinity_flag;
		Int#(ScaleWidthPlus1) scale;
		Bit#(1) sign1;
		Bit#(FracWidthQuire) frac1;
		Bit#(1) sign2;
		Bit#(FracWidthQuire) frac2;
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

endpackage: Pipeline_reg_A
