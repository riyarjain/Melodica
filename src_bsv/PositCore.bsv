package PositCore;

// Library imports
import FIFOF        :: *;
import FIFO        :: *;
import GetPut       :: *;
import ClientServer :: *;

// Project imports
import Normalizer_Types :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import FDP_PNE_Quire_PC :: *;
import FtoP_PNE_PC :: *;
import PtoF_PNE_PC :: *;
import PositToQuire_PNE_PC :: *;
import QuireToPosit_PNE_PC :: *;
import FloatingPoint :: *;
import Cur_Cycle  :: *;

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

typedef enum {FMA_P, FCVT_P_S, FCVT_S_P, FCVT_P_R, FCVT_R_P} PositCmds
deriving (Bits, Eq, FShow);

typedef Tuple4 #(FloatU, FloatU, RoundMode, PositCmds) Posit_Req;

interface PositCore_IFC;
   interface Server #(Posit_Req, Fpu_Rsp) server_core;
endinterface

(* synthesize *)
module mkPositCore #(Bit #(4) verbosity) (PositCore_IFC);

	Reg #(Bit#(QuireWidth))  rg_quire   <- mkReg(0);
	FDP_PNE_Quire       fdp             <- mkFDP_PNE_Quire(rg_quire);	
	PositToQuire_PNE    ptoq            <- mkPositToQuire_PNE(rg_quire);
	QuireToPosit_PNE    qtop            <- mkQuireToPosit_PNE(rg_quire);	
	FtoP_PNE            ftop            <- mkFtoP_PNE;	
	PtoF_PNE            ptof            <- mkPtoF_PNE;	

	FIFO #(PositCmds) opcode <- mkFIFO;

	FIFO #(Posit_Req) ffI <- mkFIFO;
	FIFO #(Fpu_Rsp) ffO <- mkFIFO;
	
	rule rl_fdp(tpl_4(ffI.first) == FMA_P);
		fdp.compute.request.put((InputTwoPosit{posit_inp1 : tpl_1(ffI.first).P,posit_inp2 : tpl_2(ffI.first).P}));
		opcode.enq(tpl_4(ffI.first));
		ffI.deq;
                if (verbosity > 1)
                   $display (  "%0d: %m: rl_fdp: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first))
                             , fshow (tpl_1(ffI.first).P)
                             , fshow (tpl_2(ffI.first).P));
	endrule
	
	rule rl_ptof(tpl_4(ffI.first) == FCVT_S_P);
		ptof.compute.request.put(tpl_1(ffI.first).P);
		opcode.enq(tpl_4(ffI.first));
		ffI.deq;
                if (verbosity > 1)
                   $display (  "%0d: %m: rl_ptof: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first))
                             , fshow (tpl_1(ffI.first).P));
	endrule

	rule rl_ftop(tpl_4(ffI.first) == FCVT_P_S);
		let a = tpl_1(ffI.first).S;
		Bit#(FloatWidth) f = {pack(a.sign),a.exp,a.sfd};
		ftop.compute.request.put(f);
		opcode.enq(tpl_4(ffI.first));
		ffI.deq;
                if (verbosity > 1)
                   $display (  "%0d: %m: rl_ftop: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first))
                             , fshow (f));
	endrule

	rule rl_ptoq(tpl_4(ffI.first) == FCVT_R_P);
		ptoq.compute.request.put(tpl_1(ffI.first).P);
		opcode.enq(tpl_4(ffI.first));
		ffI.deq;
                if (verbosity > 1)
                   $display (  "%0d: %m: rl_ptoq: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first))
                             , fshow (tpl_1(ffI.first).P));
	endrule
	
	rule rl_qtop(tpl_4(ffI.first) == FCVT_P_R);
		qtop.compute.request.put(?);
		opcode.enq(tpl_4(ffI.first));
		ffI.deq;
                if (verbosity > 1)
                   $display (  "%0d: %m: rl_qtop: "
                             , cur_cycle
                             , fshow (tpl_4(ffI.first)));
	endrule

	rule rl_out;
		let op = opcode.first; opcode.deq;
		let excep = FloatingPoint::Exception{invalid_op : False, divide_0: False, overflow: False, underflow: False, inexact : False};
		//FloatU posit_out;
		if(op == FMA_P)
			begin
				let a <- fdp.compute.response.get();
				FloatU posit_out = tagged P 0;
				ffO.enq(tuple2(posit_out,excep));
			end
		else if(op == FCVT_R_P)
			begin
				let a <- ptoq.compute.response.get();
				FloatU posit_out = tagged P 0;
				ffO.enq(tuple2(posit_out,excep));
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
				let out_pf <- ftop.compute.response.get();
				excep.invalid_op = out_pf.nan_flag == 1'b1;
				excep.overflow = out_pf.zero_infinity_flag == INF;
				excep.underflow = out_pf.zero_infinity_flag == ZERO && out_pf.rounding;
				excep.inexact = out_pf.rounding;
				FloatU posit_out = tagged P out_pf.out_posit;
				ffO.enq(tuple2(posit_out,excep));
			end
		else if(op == FCVT_P_R)
			begin
				let out_pf <- qtop.compute.response.get();
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
                   $display (  "%0d: %m: rl_out: ", cur_cycle, fshow(op));
	endrule
interface server_core = toGPServer (ffI,ffO);

endmodule
endpackage
