package Multiplier_Types;
import FShow :: *;
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
		Bit#(FracWidth ) frac2;} Inputs_m deriving(Bits,FShow);
//Input_posit is the data received from user
//Input_posit consists of zero flag, infinity flag, sign of posit, scale , fraction for 2 inputs

typedef struct {Bit#(1) sign;
		PositType zero_infinity_flag;
		Bit#(1) nan_flag;
		Int#(ScaleWidthPlus1 ) scale;
		Bit#(FracWidthQuire) frac;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;
		} Outputs_m deriving(Bits,FShow);
//Output_posit is the data available at the end of second pipeline
//Output_posit consists of zero flag, infinity flag, sign of posit, scale value, fraction value

//module mkPipeline_reg #(Int#() n) (Empty);

interface Multiplier_IFC;
   interface Server #(Inputs_m,Outputs_m) inoutifc;
endinterface

endpackage: Multiplier_Types
