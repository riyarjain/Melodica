//FMA FDA PtoQ QtoP FtoP PtoF
package PositCore;

// Library imports
import FIFOF        :: *;
import FIFO        :: *;
import SpecialFIFOs :: *;
import GetPut       :: *;
import ClientServer :: *;

// Project imports
import Extracter :: *;
import Normalizer :: *;
import Extracter_Types :: *;
import Normalizer_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import FMA_PNE_Quire_PC :: *;
import FDA_PNE_Quire_PC :: *;
import FtoP_PNE_PC :: *;
import PtoF_PNE_PC :: *;
import PositToQuire_PNE_PC :: *;
import QuireToPosit_PNE_PC :: *;
import FloatingPoint :: *;
import Utils  :: *;

`ifdef QUILLS
import FPU_Types :: *;
`else
// Type definitions
typedef FloatingPoint#(11,52) FDouble;
typedef FloatingPoint#(8,23)  FSingle;

typedef union tagged {
   FDouble D;
   FSingle S;
   Bit #(PositWidth) P;
   } FloatU deriving(Bits,Eq);

typedef Tuple2#( FloatU, FloatingPoint::Exception )       Fpu_Rsp;
`endif

typedef enum {FMA_P, FDA_P, FMS_P, FDS_P, FCVT_P_S, FCVT_S_P, FCVT_P_R, FCVT_R_P} PositCmds
deriving (Bits, Eq, FShow);

typedef Tuple4 #(FloatU, FloatU, RoundMode, PositCmds) Posit_Req;

interface PositCore_IFC;
   interface Server #(Posit_Req, Fpu_Rsp) server_core;
endinterface

(* synthesize *)
module mkPositCore #(Bit #(4) verbosity) (PositCore_IFC);

	Reg #(Bit#(QuireWidth))  rg_quire   <- mkReg(0);
	Reg #(Bit#(1))  rg_quire_busy   <- mkReg(0);
	FMA_PNE_Quire       fma             <- mkFMA_PNE_Quire(rg_quire);
	FDA_PNE_Quire       fda             <- mkFDA_PNE_Quire(rg_quire);		
	PositToQuire_PNE    ptoq            <- mkPositToQuire_PNE(rg_quire);
	QuireToPosit_PNE    qtop            <- mkQuireToPosit_PNE(rg_quire);	
	FtoP_PNE            ftop            <- mkFtoP_PNE;	
	PtoF_PNE            ptof            <- mkPtoF_PNE;	

	Extracter_IFC  extracter1 <- mkExtracter;
	Extracter_IFC  extracter2 <- mkExtracter;
	Normalizer_IFC   normalizer <- mkNormalizer;


        // Bypass FIFO as opcodes can be bypassed for the FCVT_P_S
        // case effectively merging rules extract_in and rl_ftop
	FIFO #(PositCmds) opcode_in <- mkBypassFIFO;
	FIFO #(Bit#(FloatWidth)) ffI_f <- mkBypassFIFO;

	FIFO #(PositCmds) opcode_norm <- mkFIFO1;
        FIFO #(Bool) need_normalize <- mkFIFO1;

	FIFO #(PositCmds) opcode_out <- mkFIFO1;

	FIFO #(Posit_Req) ffI <- mkFIFO;
	FIFO #(Fpu_Rsp) ffO <- mkFIFO;


        // Send posit values for extraction		
	rule extract_in;
		if(tpl_4(ffI.first) == FCVT_P_S)
			begin
				let a = tpl_1(ffI.first).S;
				ffI_f.enq({pack(a.sign),a.exp,a.sfd});
			end
		else if(tpl_4(ffI.first) == FDA_P || tpl_4(ffI.first) == FDS_P || tpl_4(ffI.first) == FMS_P || tpl_4(ffI.first) == FMA_P)
			begin
				let in_posit1 = Input_posit {posit_inp : tpl_1(ffI.first).P};
			   	extracter1.inoutifc.request.put (in_posit1);
				let in_posit2 = Input_posit {posit_inp : tpl_2(ffI.first).P};
				if(tpl_4(ffI.first) == FMS_P || tpl_4(ffI.first) == FDS_P)
					in_posit2 = Input_posit {posit_inp : twos_complement(tpl_2(ffI.first).P)};
			   	extracter2.inoutifc.request.put (in_posit2);
			end
		else if(tpl_4(ffI.first) == FCVT_S_P || tpl_4(ffI.first) == FCVT_R_P)
			begin
				let in_posit1 = Input_posit {posit_inp : tpl_1(ffI.first).P};
			   	extracter1.inoutifc.request.put (in_posit1);
			end
		opcode_in.enq(tpl_4(ffI.first));
		
		if (verbosity > 1)
                   $display (  "%0d: %m: rl_extract_in: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first))
                             , fshow (tpl_1(ffI.first).P)
                             , fshow (tpl_2(ffI.first).P));
		ffI.deq;
	endrule
        // depending on opcode_in send the extracted values to respective pipelines
	rule rl_fma((opcode_in.first == FMA_P || opcode_in.first == FMS_P) && rg_quire_busy == 1'b0);
		let extOut1 <- extracter1.inoutifc.response.get();
	   	let extOut2 <- extracter2.inoutifc.response.get();
		fma.compute.request.put((InputTwoExtractPosit{posit_inp_e1 : extOut1,posit_inp_e2 : extOut2}));
		opcode_out.enq(opcode_in.first);
		opcode_in.deq;
		rg_quire_busy <= 1'b1;
	endrule

	rule rl_fda((opcode_in.first == FDA_P || opcode_in.first == FDS_P) && rg_quire_busy == 1'b0);
		let extOut1 <- extracter1.inoutifc.response.get();
	   	let extOut2 <- extracter2.inoutifc.response.get();
		fda.compute.request.put((InputTwoExtractPosit{posit_inp_e1 : extOut1,posit_inp_e2 : extOut2}));
		opcode_out.enq(opcode_in.first);
		opcode_in.deq;
		rg_quire_busy <= 1'b1;                
	endrule
	
	rule rl_ptof(opcode_in.first == FCVT_S_P);
		let extOut1 <- extracter1.inoutifc.response.get();
		ptof.compute.request.put(extOut1);
		opcode_out.enq(opcode_in.first);
		opcode_in.deq;
	endrule

	rule rl_ftop(opcode_in.first == FCVT_P_S);
		ftop.compute.request.put(ffI_f.first);
		opcode_norm.enq(opcode_in.first);
		opcode_in.deq;
		ffI_f.deq;
	endrule

	rule rl_ptoq(opcode_in.first == FCVT_R_P && rg_quire_busy == 1'b0);
		let extOut1 <- extracter1.inoutifc.response.get();
		ptoq.compute.request.put(extOut1);
		opcode_out.enq(opcode_in.first);
		opcode_in.deq;
		rg_quire_busy <= 1'b1;
	endrule
	
	rule rl_qtop(opcode_in.first == FCVT_P_R && rg_quire_busy == 1'b0);
		qtop.compute.request.put(?);
		opcode_norm.enq(opcode_in.first);
		opcode_in.deq;
		rg_quire_busy <= 1'b1;
	endrule

        // normalize the values that are got as outputs from the operation pipelines
	rule rl_norm;
		let op = opcode_norm.first;
		opcode_out.enq(op);
		opcode_norm.deq;
		if(op == FCVT_P_S )
			begin
				let out_pf <- ftop.compute.response.get();
				normalizer.inoutifc.request.put (out_pf);				
                                if (verbosity > 1)
                                   $display ("%0d: %m: rl_norm: ", cur_cycle, fshow(op));
			end
		else if( op ==  FCVT_P_R)
			begin
				let out_pf <- qtop.compute.response.get();
				normalizer.inoutifc.request.put (out_pf);
				rg_quire_busy <= 1'b0;				
                                if (verbosity > 1)
                                   $display ("%0d: %m: rl_norm: ", cur_cycle, fshow(op));
			end
		else
                   $display (  "%0d: %m: rl_norm: Error Illegal Opcode", cur_cycle, fshow(op));
	
	endrule
	rule rl_out;
		let op = opcode_out.first; opcode_out.deq;
		let excep = FloatingPoint::Exception{invalid_op : False, divide_0: False, overflow: False, underflow: False, inexact : False};
		//FloatU posit_out;
		if(op == FMA_P ||op == FMS_P)
			begin
				let a <- fma.compute.response.get();
				FloatU posit_out = tagged P 0;
				ffO.enq(tuple2(posit_out,excep));
				rg_quire_busy <= 1'b0;
			end
		else if(op == FDA_P ||op == FDS_P  )
			begin
				let a <- fda.compute.response.get();
				FloatU posit_out = tagged P 0;
				ffO.enq(tuple2(posit_out,excep));
				rg_quire_busy <= 1'b0;
			end
		else if(op == FCVT_R_P)
			begin
				let a <- ptoq.compute.response.get();
				FloatU posit_out = tagged P 0;
				ffO.enq(tuple2(posit_out,excep));
				rg_quire_busy <= 1'b0;
			end
		else if(op == FCVT_S_P)
			begin
				let out_pf <- ptof.compute.response.get();
				FSingle fs = FSingle{sign : unpack(msb(out_pf)), exp : (out_pf[valueOf(FloatExpoBegin):valueOf(FloatFracWidth)]), sfd : truncate(out_pf) };
				FloatU posit_out = tagged S fs;
				ffO.enq(tuple2(posit_out,excep));
			end
		else if(op == FCVT_P_S)
			begin
				let out_pf <- normalizer.inoutifc.response.get ();
				excep.invalid_op = out_pf.nan_flag == 1'b1;
				excep.overflow = out_pf.zero_infinity_flag == INF;
				excep.underflow = out_pf.zero_infinity_flag == ZERO && out_pf.rounding;
				excep.inexact = out_pf.rounding;
				FloatU posit_out = tagged P out_pf.out_posit;
				ffO.enq(tuple2(posit_out,excep));
			end
		else if(op == FCVT_P_R)
			begin
				let out_pf <- normalizer.inoutifc.response.get ();
				excep.invalid_op = out_pf.nan_flag == 1'b1;
				excep.overflow = out_pf.zero_infinity_flag == INF;
				excep.underflow = out_pf.zero_infinity_flag == ZERO && out_pf.rounding;
				excep.inexact = out_pf.rounding;
				FloatU posit_out = tagged P out_pf.out_posit;
				ffO.enq(tuple2(posit_out,excep));
			end
		else 
                   $display (  "%0d: %m: rl_out: Error Illegal Opcode", cur_cycle, fshow(op));
			
                if (verbosity > 1)
			begin
                   		$display ("%0d: %m: rl_out: ", cur_cycle, fshow(op));
				$display ("  QUIRE: %h",rg_quire);
			end
	endrule

interface server_core = toGPServer (ffI,ffO);

endmodule
endpackage
