package Testbench;

import GetPut       :: *;
import ClientServer :: *;

import Utils ::*;
import PositCore ::*;
import Posit_Numeric_Types :: *;
import FloatingPoint :: *;

(* synthesize *)
module mkTestbench (Empty);

	PositCore_IFC pc <- mkPositCore;
	Reg #(Bit #(5)) rg_y <- mkReg (0);
	rule rl_gen;
		FloatingPoint::RoundMode round_mode = Rnd_Nearest_Even;
		PositCmds opcodes= FCVT_P_S;
		PositCore::FloatU in1 = tagged P 32'h11111111;
		PositCore::FloatU in2 = tagged P 32'h11111111;
		let inp_posit = tuple4(in1,in2,round_mode,opcodes);
		pc.server_core.request.put (inp_posit);
		$display("in1 %b in2 %b opcode %b",tpl_1(inp_posit).P,tpl_2(inp_posit).P,tpl_4(inp_posit));
		rg_y <= rg_y + 1;
   	endrule

	   rule rl_drain(rg_y < 7);
	      let z <- pc.server_core.response.get ();
		$display("out %b exception %b",tpl_1(z).P,tpl_2(z));
	   endrule

endmodule

endpackage
