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

package Extracter;

// --------------------------------------------------------------
// This package defines:
//
//    mkExtracter: 1-stage extracter which extracts the different
//    posit fields
// --------------------------------------------------------------


import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Extracter_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;

module mkExtracter (Extracter_IFC );
	// make a FIFO to store data at the end of each stage of the pipeline, and also for input and outputs
   	FIFOF #(Output_posit )  fifo_output_reg <- mkFIFOF;
	FIFOF #(Stage0 )  fifo_stage0_reg <- mkFIFOF;
	FIFOF #(Stage1 )  fifo_stage1_reg <- mkFIFOF;
	FIFOF #(Stage2 )  fifo_stage2_reg <- mkFIFOF;
	Integer es_int = valueOf(ExpWidth);
	Integer n_int = valueOf(PositWidth);

	//special case function is used to find the zero and infinity flag
	//this function gives output 10 for zero, 01 for infinity, 00 if none
	//Input is zero if all bits are 0 and infinity if the MSB is 1 and all other bits are 0
	

	function PositType fv_special_case(Bit#(PositWidth) x);
	// a checks if all bits other than MSB are 0, if thery are a = 0 else a = 1
		Bit#(1) a = (unpack(x[n_int-2:0]) ==  0 ? 1'b0 : 1'b1);
		//Check for MSB
		
		if (a == 1'b0 && x[n_int-1] == 1'b0) 
			// return 10 if all bits are 0
			return ZERO;
		else if(a == 1'b0 && x[n_int-1] == 1'b1) 
			//return 01 if MSB is 1 and other 0
			return INF;
		else return REGULAR;
			//return 00 for all other cases
	endfunction


//frac shift function is used to output the number of bits I need to shift the frac so that the the starting of the fraction is the first bit in output then it is appended with zeros
	function Bit#(FracWidth) fv_frac_shift(UInt#(Iteration) iter0);
		Bit#(FracWidth) mask = '0;

		for (Integer k = 0; k<=valueOf(FracWidth); k=k+1)
			if (k == 0 && iter0 <= fromInteger(es_int))
				mask =fromInteger(valueOf(FracWidth)-k);
			else if(iter0 == fromInteger(es_int + k))
				mask =fromInteger(valueOf(FracWidth)-k);
		return mask;
	endfunction

	// stage_0: INPUT STAGE. Checks for special cases. 
	rule stage_0;
	endrule	

   interface Server inoutifc;
      interface Put request;
         method Action put (Input_posit p);
		//dIn reads the values from input pipeline register 
      		let dIn = p;
		//output 10 for zero, 01 for infinity, 00 if none
		let zero_infinity_flag = fv_special_case(dIn.posit_inp);
		//sign bit is 0 when posit is positive else 1 when posit is negative
		let sign = dIn.posit_inp[n_int-1];
			//new input stage0 is got after removing the sign bit and finding its two's complement if posit is negative from input posit
		Bit#(PositWidthMinus1) new_inp = (sign == 0 ? dIn.posit_inp[n_int-2 : 0] : twos_complement(dIn.posit_inp[n_int-2 : 0]));

		//gives the number of leading ones in new input
		let lead_one_no = countZerosMSB(~(new_inp));
		//gives the number of leading zeros in new input
		let lead_zero_no = countZerosMSB(new_inp);
		//states if there is only regime field with leading bit 1 and no exponent & fraction field 
		let one_full_regime = (lead_one_no == fromInteger(n_int-1))?0:1; 
		//states if there is only regime field with leading bit 0 and no exponent & fraction field 
		let zero_full_regime = (lead_zero_no == fromInteger(n_int-1))?0:1; 
		//k gives the value of regime field
		//k is got depending on the leading bit, if one then (#zeros) -1 else -(#zeros)	
		Int#(RegimeWidth) k = (msb(new_inp) ==1'b1  ? unpack(extend(pack(lead_one_no))-1) : unpack(twos_complement(extend(pack(lead_zero_no)))));
			//iteration gives the value from which the exponent field starts
			//iteration = N - 1(sign) - #leading bits -1(end of regime field if u have exponent & fraction field)
		UInt#(Iteration) iteration = (msb(new_inp) == 1'b1 ? (fromInteger(n_int - 1-one_full_regime) - (lead_one_no)) : (fromInteger(n_int - 1-zero_full_regime) - (lead_zero_no)));
		//if es = 5
			// if we have more than 4 bits available we have to shift the window for the exponent field else the windows position is fixed at last and the number of bits in exponent is decided using 5 bit mask depending on the number of bits available
		Bit#(ExpWidth) expo = (iteration>=fromInteger(es_int) ? new_inp[iteration-1:iteration-fromInteger(es_int)] : (truncate(new_inp)<<(fromInteger(es_int) - iteration)));
			//the frac size bit mask is decided on the number of bits available for fraction field
		Bit#(FracWidth) frac = (truncate(new_inp) << fv_frac_shift(iteration)); 		

		let output_regf = Output_posit {
			//carrying zero and infinity flag forward
                        zero_infinity_flag : zero_infinity_flag,
			//carrying sign bit fordward
			sign : sign ,
			//k_scale = 2^(Es)*k
			//scale = k_scale + exponent field (base 2)
			scale : zero_infinity_flag == ZERO?0:((extend(k)<<es_int) + unpack(extend(expo))),
			//carrying fraction bits fordward
			frac : zero_infinity_flag == ZERO? unpack(fromInteger(0)):frac};
		fifo_output_reg.enq(output_regf);
		`ifdef RANDOM_PRINT
			$display("zero_infinity_flag %b",zero_infinity_flag);
			$display("sign %b",sign);
			$display("scale %b frac %b",output_regf.scale,output_regf.frac);
		`endif
         endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule

endpackage: Extracter


