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

package Normalizer;

// --------------------------------------------------------------
// This package defines:
//
//    mkNormalizer: 4-stage normalizer which composes the
//    different posit fields into a posit word
// --------------------------------------------------------------

// Library imports
import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

// Project imports
import Normalizer_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;


module mkNormalizer (Normalizer_IFC);

    // make a FIFO to store data at the end of each stage of the pipeline, and also for input and outputs
    FIFOF #(Input_value_n )   fifo_input_reg <- mkFIFOF;
    FIFOF #(Output_posit_n )  fifo_output_reg <- mkFIFOF;
    FIFOF #(Stage0_n )  fifo_stage0_reg <- mkFIFOF;
    FIFOF #(Stage1_n )  fifo_stage1_reg <- mkFIFOF;
    FIFOF #(Stage2_n )  fifo_stage2_reg <- mkFIFOF;

    // Posit# (N, ES)
    Integer es_int = valueOf(ExpWidth);
    Integer n_int = valueOf(PositWidth);
    Integer n_1_int = valueOf(PositWidthMinus1);
    UInt#(BitsPerPositWidth) n_2_int = fromInteger(n_int-2);

    // this function is used to construct the regime field
    // depending on the value you add those many number of zeros
    // or one with a bit flip at the end
    function Tuple2#(Bit#(PositWidthMinus1),UInt#(BitsPerPositWidth)) fv_calculate_regime (Bit#(ScaleWidthMinusExpWidthPlus1) a);
        Bit#(PositWidthMinus1) one = extend(1'b1);//000000000...001
        Bit#(PositWidthMinus1) k;
        UInt#(BitsPerPositWidth) n1;

        if(a[valueOf(ScaleWidthMinusExpWidth)] == 1'b1)
            // if first bit is 1 that means the number is negative
            // so the value has to negated and will be denoted
            // by leading number of zeros            
            begin
                n1 = truncate(unpack(twos_complement(a)));
                k = one<<(n_2_int-n1);//0000..010...0
            end
        else 
            // if first bit is 0 that means the value denotes the leading number of ones        
            begin
                n1 = boundedPlus(truncate(unpack(a)),1);
                k = (~('1>>n1));//111...11000..00
            end
        return tuple2(k,n1);
    endfunction

    // this function is used to give output for special case i.e.
    // give all zeros for zero_infinity flag = 10(zero) and give
    // first bit 1 and others zeros for zero_infinity flag =
    // 01(infinity) 
    function Bit#(PositWidth) fv_outp_z_i(PositType z_i);
    Bit#(PositWidth) one = extend(1'b1);
    if(z_i == INF)
        return one<<n_1_int;
    else return '0;
    endfunction

    // This function is used to give final output by taking twos
    // complement of the whole number if the sign bit is 1 
    function Bit#(PositWidth) fv_outp_sign(Bit#(PositWidthMinus1) a, Bit#(1) s);
    if(s == 1)
        return {1'b1,twos_complement(a)};
    else return {1'b0,a};
    endfunction
    
    // This function determines the mask that will be used for the
    // exponent depending on the number of bits available for
    // exponent input: n_2_k: number of bits left for exponent and
    // fraction, exponent value
    // output: shift: the bits the exponent has to shift to be
    // placed just after regime, shift_new :shift in fraction bits
    // to accomodate any overflow of exponent , mask : to see whoch
    // exponent bits are to be used
    function Tuple3#(UInt#(BitsPerPositWidth),Bit#(ExpWidthPlus1), Bit#(ExpWidth)) fv_expo_window_mask (UInt#(BitsPerPositWidth) n_2_k,Bit#(ExpWidth) expo);
        let es_bit = fromInteger(es_int);
        Bit#(ExpWidthPlus1) one = extend(1'b1);
        Bit#(ExpWidth) expo_new = expo;
        UInt#(BitsPerPositWidth) shift;
        Bit#(ExpWidthPlus1) shift_new;
        if(n_2_k<es_bit)//if the number of bits available is less than the maximum number of bits the exponent can use
            begin
                shift = 0;// dont shift the exponent, it will be placed at the last
                Bit#(ExpWidth) mask_e = '1>>(es_bit - n_2_k);//mask_e tells which bits of exponent are overlapping with regime field due to less number of bits available for exponent
                if((expo & mask_e) == 0)//if the overlap bits are 0 i.e. dont hold any information
                    begin
                    shift_new = 0;//n_2_k se shift expo
                    expo_new = expo >> n_2_k;// use all exponent bits
                    end
                else
                     
                    begin
                    shift_new = extend(twos_complement(expo));//use the complement of the value of exponent since we are increasing or decreasing the regime by 1 as required, as round off of exponent as can be seen in the mask 
                    expo_new = truncate(one<<n_2_k) & expo;//any of the overlap bits is 1 ????????????(es)>1???
                    end
            end
        else
            begin
                shift = n_2_k-es_bit;//shift the es bits to place them just after the regime field
                shift_new = 0;//no change in fraction bits
                expo_new = expo;//use all exponent bits
            end
        return tuple3(shift,shift_new,expo_new);
    endfunction

    // ------------
    // Here be rules ...

    // interpreting scale value into regime and exponent
    rule stage_0;
        //dIn reads the values from input pipeline register 
        let dIn = fifo_input_reg.first;  fifo_input_reg.deq;
        // data to be stored in stored in fifo that will be used in stage 0
        match { .k, .no_of_bit_k } = fv_calculate_regime(dIn.scale[valueOf(ScaleWidth):es_int]);
           //carrying exponent field forward(no bit transfered if es = 0)
        Bit#(ExpWidth) expo = (es_int == 0)??:dIn.scale[es_int-1:0];
            //this gives the number of leading bit in the regime field without bit flip
	    `ifdef RANDOM_PRINT            
		$display("dIn.frac %b",dIn.frac);
	     `endif
        // shift gives the number of bits have shifted so that the exponent bit can be directly added to the regime field
        //you shift the exponent field by 0 if the exponent field forms the last bits of the posit number
        //shift_new = the number of bits the fraction has to be shifted so as to accomodate exponent bits the unavalibility of bits to store it in the input
        //shift_new = the number of overlap bits between regime and exponent
        //mask : see which exponent to be used
        let n_2_k = (n_2_int-no_of_bit_k);
        match{.shift0, .shift_new0, .expo_masked} = fv_expo_window_mask(n_2_k,expo);
        //we bound the sum of k and expo to maximum if it exceeds
        // k + shift expo depending on available bits
        UInt#(PositWidthMinus1) uint_k_expo = boundedPlus(unpack(k) , unpack(extend(expo_masked)<<shift0));
                let stage1_regf = Stage1_n {
            //carrying sign bit forward
            sign : dIn.sign ,
            //carrying zero and infinity flag forward
            zero_infinity_flag : dIn.zero_infinity_flag,
            //carrying nan flag forward
            nan_flag : dIn.nan_flag,
            //carrying fraction field forward
            frac : truncate({(n_2_k == 0?1'b0:1'b1),dIn.frac}>>shift_new0),//1'b0 for now may have to condition it later to (1'b1 for n_2_k >0)
            //combining the regime and exponent field
            k_expo : pack(uint_k_expo),
            //this gives the shift in the number of bits for the exponent field
            shift_1 : shift0,
            // see the case where there is no available space to accomodate exponent and the there is no shift in fraction snce all frac bits will be lost
            flag_endcase : pack(n_2_k == 0 && shift_new0 == 0), 
            //carrying forward msb of truncated fraction bits
            //if there is no shift in fraction msb remains but if there is change we have to use the last bit of the frac bits lost
            truncated_frac_msb : shift_new0 == 0 ? dIn.truncated_frac_msb : dIn.frac[shift_new0-1],
            //carrying forward truncated_frac_zero
            //if there is no shift in truncated_frac_zero remains but if there is a shift we have to see the new rounded frac bits, old truncated_frac_msb and old truncated_frac_zero
            truncated_frac_zero : shift_new0 == 0 ? dIn.truncated_frac_zero :(shift_new0 == fromInteger(1) ?  dIn.truncated_frac_zero & (~dIn.truncated_frac_msb) : dIn.truncated_frac_zero & (~dIn.truncated_frac_msb) & ((unpack(dIn.frac[shift_new0-2:0]) ==  0)? 1'b1 : 1'b0)) };
            `ifdef RANDOM_PRINT
            $display("shift0 %b shift_new0 %b expo_new %b dIn.frac %b n_2_k %b expo %b truncated_frac_msb %b truncated_frac_zero %b ",shift0, shift_new0, expo_masked,dIn.frac,n_2_k,expo,stage1_regf.truncated_frac_msb,dIn.truncated_frac_zero);
            $display("k %b",k);
            $display("no_of_bit_k %b",no_of_bit_k);
            `endif
        fifo_stage1_reg.enq(stage1_regf);

    endrule

    // ------------
    // calculate rounding
    // combine regime, exponent, fraction
    rule stage_1;
        //dIn reads the values from pipeline register stored from previous stage
        let dIn = fifo_stage1_reg.first;  fifo_stage1_reg.deq;
        //shift_2 gives the shift in fraction bits
        let shift_2 = fromInteger(valueOf(FracWidth))-dIn.shift_1;
        //expo_even tells if exponent field's lsb is 0/1; see this only if #frac bits = 0; in other cases it is 1
        // see if we have even expo or odd expo
        Bit#(1) expo_even = (dIn.shift_1 == 0 ? ~(dIn.k_expo[0]) : 1'b1);
        // in rounding a few bits will be lost so depending on the bits lost we round the number 
        //flag_prev_truncate tells if the last bit lost is from truncated frac or the present frac
        //require it to round the number to nearest value
        Bit#(1) flag_prev_truncate = ((shift_2) == 0) ? dIn.truncated_frac_msb : (dIn.frac[shift_2-1]);

        // flag_equidistant tells if it is equidistant from the
        // posits that can be represented

        // check if the fraction is equidistnat or not for rounding

        // cases that need to be checked for to see if fraction
        // bits that are being truncated is equidistant or not
        // as then we have to go to the nearest even. 

        // frac bits lost in the last shifting are 
            //a) more than 1 (shift_2>1): then the msb lost(flag_prev_truncate) should be 1, all other bits truncated due to the shifting should be 0s & other bits that need to be ensured to be 0 include truncated_frac_msb should be 0 & truncated_frac_zero should be 1 and finally only is the last fraction bit being used is 1 then only we have to add 1 and round it to even  
            //b) is equal to 1(shift_2 ==1): then the msb lost(flag_prev_truncate) should be 1 & other bits that need to be ensured to be 0 include truncated_frac_msb that should be 0 & truncated_frac_zero that should be 1 and finally only is the last fraction bit being used is 1 then only we have to add 1 and round it to even 
            //c) is equal to 0(shift_2 ==0): then the msb lost(flag_prev_truncate which is also equal to truncated_frac_msb) should be 1 & other bits that need to be ensured to be 0 include truncated_frac_zero that should be 1 and finally only is the last fraction bit being used is 1 then only we have to add 1 and round it to even  
            //d) all bits(shift_1 == 0): then the msb lost(flag_prev_truncate which is also equal to truncated_frac_msb) should be 1 & other bits that need to be ensured to be 0 include truncated_frac_zero that should be 1 and finally since all fraction bits are lost then the last bit in the number will be exponent bit so we have to check if that is even or not and so decide the rounding bit 
        //case2: flag_endcase states if all expo(other than when es = 0) and frac bits are being truncated we check if the flag_prev_truncate is 0  
        //case3: when k_expo is all 1s and all frac bits are being truncated and frac and all other bits are 0 it will be equidistant even if expo bits is zero (other than when es = 0)

        Bit#(1) flag_equidistant = 1'b0;
	if(shift_2>= 0)
		if(dIn.frac[shift_2] == 1'b0 && flag_prev_truncate == 1'b1 && dIn.truncated_frac_zero == 1'b1 && expo_even == 1'b1)
			if(shift_2 == 0)
				flag_equidistant = 1'b1;
			else if(shift_2 == 1 && dIn.truncated_frac_msb == 1'b0 )
				flag_equidistant = 1'b1;
			else if(shift_2>=2 && unpack(dIn.frac[shift_2-2:0]) ==  0 && dIn.truncated_frac_msb == 1'b0)
				flag_equidistant = 1'b1;
	else if(dIn.flag_endcase == 1'b1 && flag_prev_truncate == 1'b1 && (es_int != 0)) 
		flag_equidistant = 1'b1;
	else if(dIn.k_expo == '1 && dIn.shift_1 == 0 && dIn.frac ==  0 && dIn.truncated_frac_zero == 1'b1 &&  dIn.truncated_frac_msb == 1'b0 && (es_int != 0))
		flag_equidistant = 1'b1;
	else
		flag_equidistant = 1'b0;

        //we bound the sum of k expo and frac to maximum if it exceeds
        //k_expo + shifted fraction bits + if the prev truncated bit is 1/0 - if the number is equidistant
        UInt#(PositWidthMinus1) uint_k_expo_frac = boundedPlus(unpack(dIn.k_expo +(extend(dIn.frac)>>(shift_2))-extend(flag_equidistant)),unpack(extend(flag_prev_truncate)));
        uint_k_expo_frac = uint_k_expo_frac + extend(uint_k_expo_frac == 0 && flag_equidistant == 0 ?1'b1:1'b0);
        
	Bool rounding = (flag_prev_truncate - flag_equidistant == 1'b1 || uint_k_expo_frac == 0 && flag_equidistant == 0);
        `ifdef RANDOM_PRINT
        $display("dIn.sign %b",dIn.sign);
        $display("dIn.k_expo %b dIn.frac %b uint_k_expo_frac %b dIn.flag_endcase %b",dIn.k_expo,dIn.frac,uint_k_expo_frac,dIn.flag_endcase);
        $display(" dIn.shift_1 %b shift_2 %b flag_prev_truncate %b flag_equidistant %b",dIn.shift_1,shift_2,flag_prev_truncate,flag_equidistant);
        $display(" dIn.zero_infinity_flag %b",dIn.zero_infinity_flag);
        `endif
        let output_regf = Output_posit_n {
            //carrying nan flag forward
            nan_flag : dIn.nan_flag,
            // depending on sign bit and zero_infinity_flag giving the final output
            out_posit: (dIn.zero_infinity_flag == REGULAR ? fv_outp_sign(pack(uint_k_expo_frac),dIn.sign) : fv_outp_z_i(dIn.zero_infinity_flag)),
            zero_infinity_flag : dIn.zero_infinity_flag,
	    rounding : rounding};
        fifo_output_reg.enq(output_regf);

    endrule    
    
    interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);
endmodule

endpackage: Normalizer
