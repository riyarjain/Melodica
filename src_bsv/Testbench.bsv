package Testbench;

import GetPut       :: *;
import ClientServer :: *;

import PositCore ::*;
import Posit_Numeric_Types :: *;
import FloatingPoint :: *;
import Utils  :: *;

(* synthesize *)
module mkTestbench (Empty);

	PositCore_IFC pc <- mkPositCore(2);
	Reg #(Bit #(5)) rg_y <- mkReg (0);
	rule rl_gen;
		FloatingPoint::RoundMode round_mode = Rnd_Nearest_Even;
		PositCmds opcodes = FMA_P;
		//FSingle f1 = fromReal(2.5);
		//FSingle f2 = fromReal(4);
		PositCore::FloatU in1 = tagged P 32'h60006000;
		PositCore::FloatU in2 = tagged P 32'h54005400;
		let inp_posit = tuple4(in1,in2,round_mode,opcodes);
		pc.server_core.request.put (inp_posit);
		$display("%0d: in1 %h in2 %h opcode %b",cur_cycle,tpl_1(inp_posit).P,tpl_2(inp_posit).P,tpl_4(inp_posit));

   	endrule

	   rule rl_drain(rg_y < 1);
	      let z <- pc.server_core.response.get ();
		$display("%0d: out %h exception %b",cur_cycle,tpl_1(z).P,tpl_2(z));
		rg_y <= rg_y + 1;
		$finish;
	   endrule

endmodule

endpackage
