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

package PositToQuire_PC;

// --------------------------------------------------------------
// This package defines:
//
//    mkQuireToPosit: 3-stage pipeline that converts Quire to Posit
// --------------------------------------------------------------

// Library imports

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Extracter_Types	:: *;
import PtoQ_Types	:: *;

interface PositToQuire_IFC;
   interface Server #(Output_posit,Bit#(0)) inoutifc;
endinterface

module mkPositToQuire #(Reg #(Bit#(QuireWidth))  rg_quire) (PositToQuire_IFC );
	FIFOF #(Bit#(0))  fifo_output_reg <- mkFIFOF;
	FIFOF #(Output_posit )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Stage1_qp )  fifo_stage1_reg <- mkFIFOF;

	//This function will be used to get the Int-Frac value from the scale and frac value got from multiplying the values
	function Bit#(IntWidthQuirePlusFracWidthQuire) calculate_frac_int(Bit#(FracWidthPlus1) f, Int#(ScaleWidthPlus1) s);
		Bit#(IntWidthQuirePlusFracWidthQuire) f_new = extend(f);
		//first 1 bits of fraction are integer bits so if scale = 0 we have to shift fract left by FWQ-FW
		//Thus frac_shift = FWQ-FW + scale(signed sum)
		Int#(LogCarryWidthPlusIntWidthPlusFracWidthQuire) scale_pos = signExtend(s) + fromInteger(valueOf(FracWidthQuireMinusFracWidth));// frac_shift = scale_pos = s + FWQ-FW
		f_new = f_new<<scale_pos;// right shift to accomodate the scale
		return f_new;
	endfunction

	// --------
        // Pipeline stages
	// stage_2 : check special cases 
	rule stage_2;
		let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
		Bit#(CarryWidthQuire) carry = '0;
		//the Quire value is signed extend
		if(dIn.zero_infinity_flag == ZERO)
			begin
				fifo_output_reg.enq(?);
				rg_quire <= '0;
			end
		else
			begin			
				Bit#(QuireWidth) twos_complement_carry_int_frac = dIn.sign == 1'b0 ? {dIn.sign,carry,dIn.int_frac} : {dIn.sign,twos_complement({carry,dIn.int_frac})};
				rg_quire <= twos_complement_carry_int_frac;
				fifo_output_reg.enq(?);
			end

	endrule


interface Server inoutifc;
      interface Put request;
         method Action put (Output_posit p);
		// stage_1: calculate integer part of quire
		//dIn reads the values from pipeline register stored from previous stage
		let extOut = p;
		//calculate integer from scale
		let int_frac = calculate_frac_int({1'b1,extOut.frac},extOut.scale);
		let stage1_reg = Stage1_qp{sign : extOut.sign,
					   int_frac : int_frac,
					   zero_infinity_flag : extOut.zero_infinity_flag};
		fifo_stage1_reg.enq(stage1_reg);

   	endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule
endpackage: PositToQuire_PC
