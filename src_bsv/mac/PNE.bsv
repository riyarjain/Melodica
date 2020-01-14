// HPC Lab, Department of Electrical Engineering, IIT Bombay

package PNE;

// -----------------------------------------------------------------
// This package defines:
//
//    The different artefacts your package defines. One per line
//    with a small description per line, please.
//
// -----------------------------------------------------------------

import ClientServer     :: *;
import GetPut           :: *;
import FIFO             :: *;
import Extracter_IFCP	:: *;
import Extracter	:: *;
import Normalizer_IFCP	:: *;
import Normalizer	:: *;
import Adder_IFCP 	:: *;
import Adder		:: *;
import Multiplier_IFCP	:: *;
import Multiplier	:: *;
import Pipeline_reg	:: *;
import Pipeline_reg_N	:: *;
import Pipeline_reg_M	:: *;
import Pipeline_reg_A 	:: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Utils :: *;
typedef 3 Pipe_Depth;      // Estimated pipeline depth of the PNE
interface PNE ;
   interface Server #(InputThreePosit,Output_posit_n) compute;
endinterface



//
// Module definition
module mkPNE (PNE );
FIFO #(InputThreePosit) ffI <- mkFIFO;
FIFO #(Output_posit) ffItemp <- mkSizedFIFO (valueOf (Pipe_Depth));
FIFO #(Output_posit_n) ffO <- mkFIFO;
//FIFO #(Output_posit) ffm <- mkFIFO;
// Extractor
Extracter_IFC  extracter1 <- mkExtracter;
Extracter_IFC  extracter2 <- mkExtracter;
Extracter_IFC  extracter3 <- mkExtracter;
Multiplier_IFC  multiplier <- mkMultiplier;
Adder_IFC  adder <- mkAdder;
Normalizer_IFC   normalizer <- mkNormalizer;


rule rl_in;
   let in_posit1 = Input_posit {posit_inp : ffI.first.posit_inp1};
   extracter1.inoutifc.request.put (in_posit1);
   let in_posit2 = Input_posit {posit_inp : ffI.first.posit_inp2};
   extracter2.inoutifc.request.put (in_posit2);
   //let in_posit3 = ffI.first.posit_inp3;
   //ffItemp.enq(in_posit3);
   let in_posit3 = Input_posit {posit_inp : ffI.first.posit_inp3};
   extracter3.inoutifc.request.put (in_posit3);
	//$display("[%0d]Input",cur_cycle);
 ffI.deq;
endrule

rule rl_connect0;
   //let in_posit3 = Input_posit {posit_inp : ffItemp.first};
   //extracter3.inoutifc.request.put (in_posit3);
   //ffItemp.deq;
   let extOut <- extracter3.inoutifc.response.get();
   ffItemp.enq(extOut);	
   let extOut1 <- extracter1.inoutifc.response.get();
   let extOut2 <- extracter2.inoutifc.response.get();
   multiplier.inoutifc.request.put (Inputs_m {
	sign1: extOut1.sign,
	nanflag1: 1'b0,
 	zero_infinity_flag1: extOut1.zero_infinity_flag ,
	scale1 : extOut1.scale,
	frac1 : extOut1.frac,
	sign2: extOut2.sign,
	nanflag2: 1'b0,
 	zero_infinity_flag2: extOut2.zero_infinity_flag ,
	scale2 : extOut2.scale,
	frac2 : extOut2.frac});
	// the fraction and scale are extended since operation is on quire
	//using signed extension for scale value
	//fraction value is normally extended but also shifted to maked the MSB the highest valued fraction bit
endrule

rule rl_connect2;
   let mulOut <- multiplier.inoutifc.response.get();
   //let extOut3 <- extracter3.inoutifc.response.get();
	//$display("[%0d]Input1",cur_cycle);
   let extOut3 = ffItemp.first;
   ffItemp.deq;
	adder.inoutifc.request.put (Inputs_a {
	sign1: mulOut.sign,
	nanflag1: mulOut.nan_flag,
 	zero_infinity_flag1: mulOut.zero_infinity_flag ,
	scale1 : mulOut.scale,
	frac1 : mulOut.frac,
	round_frac_f1 : mulOut.truncated_frac_msb | ~mulOut.truncated_frac_zero,
	sign2: extOut3.sign,
	nanflag2: 1'b0,
 	zero_infinity_flag2: extOut3.zero_infinity_flag ,
	scale2 : extOut3.scale,
	frac2 : extOut3.frac,
	round_frac_f2 : 1'b0});
endrule

rule rl_connect3;
   let addOut <- adder.inoutifc.response.get();
   normalizer.inoutifc.request.put (Input_value_n {
	sign: addOut.sign,
 	zero_infinity_flag: addOut.zero_infinity_flag ,
	nan_flag: addOut.nan_flag,
	scale :  pack(addOut.scale),
	frac : addOut.frac,
	truncated_frac_msb : addOut.truncated_frac_msb,
	truncated_frac_zero : addOut.truncated_frac_zero});
endrule

//truncated_frac_msb :value of MSB lost to see if its more than or less than half
//truncated_frac_zero : check if res of  the frac bits are zero to check equidistance

rule rl_out;
   let normOut <- normalizer.inoutifc.response.get ();
   ffO.enq(normOut);
$display("				[%0d]Output",cur_cycle);
endrule


interface compute = toGPServer (ffI,ffO);


endmodule

(* synthesize *)

module mkPNE_test (PNE );
   let _ifc <- mkPNE;
   return (_ifc);
endmodule

endpackage

// -----------------------------------------------------------------


