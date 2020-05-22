package IntDiv;

import FIFO        :: *;
import GetPut       :: *;
import ClientServer :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;

typedef FracWidthPlus1 Denom_bits;
typedef TMul#(Denom_bits,2) Numer_bits;
typedef Denom_bits Rem_bits;
typedef TAdd#(TSub#(Numer_bits,Denom_bits),1) Quo_bits;

typedef struct	{Bit#(Denom_bits) numerator;
		Bit#(Denom_bits) denominator;} Input_intdiv deriving(Bits,FShow);

typedef struct	{Bit#(Denom_bits) quotient;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Output_intdiv deriving(Bits,FShow);

interface IntDiv ;
	interface Server #(Input_intdiv),Output_intdiv) inoutifc;
	method Action start;
endinterface

typedef enum { Div_RDY, Div_START, Div_LOOP1, Div_LOOP2, Div_DONE} DivState
   deriving (Eq, Bits, FShow);


module mkIntDiv (IntDiv);

	FIFO #(Input_intdiv) fifo_input_reg <- mkFIFO;
	FIFO #(Output_intdiv) fifo_output_reg <- mkFIFO;

	Reg #(DivState)  rg_state     <- mkReg (Div_RDY);
	Reg #(Bit #(Numer_bits))  rg_numer    <- mkRegU;
	Reg #(Bit #(Denom_bits))  rg_denom    <- mkRegU;
	Reg #(Bit #(Numer_bits))  rg_denom2    <- mkRegU;
	Reg #(Bit #(Quo_bits))  rg_n         <- mkRegU;
	Reg #(Bit #(Quo_bits))  rg_quo       <- mkRegU;

	rule rl_start_div_by_zero (rg_state == Div_START);

		let dIn = fifo_input_reg.first;
		let numer = dIn.numerator;	
		let denom = dIn.denominator;
		if(denom == 0)
			begin
				rg_quo   <= '1;        // all bits set
				// Rem_bits is rg_numer
				rg_state <= Div_DONE;
			end
		else
			begin
				rg_numer     <= {numer,'0};
	      			rg_denom     <= denom;
	      			rg_denom2    <= zeroExtend(denom);
				rg_quo       <= 0;
				rg_n         <= 1;
				rg_state     <= Div_LOOP1;
			end
		fifo_input_reg.deq;	
	endrule

	rule rl_loop1 (rg_state == Div_LOOP1);
		if (rg_denom2 <= (rg_numer >> 1))
			begin
				rg_denom2 <= rg_denom2 << 1;
				rg_n <= rg_n << 1;
      			end
      		else
	 		rg_state <= Div_LOOP2;
	endrule

	rule rl_loop2 (rg_state == Div_LOOP2);
		if (rg_numer < zeroExtend(rg_denom))
			begin
				rg_state <= Div_DONE;
				let quo = rg_quo;
				let rem = rg_numer;
				Bit#(Rem_bits) rem_truncate= truncate(rem);
				fifo_output_reg.enq(Output_intdiv{quotient : quo,
								  truncated_frac_msb : msb(rem_truncate)==1'b1,
								  truncated_frac_zero : rem_truncate[valueOf(Rem_bits)-2:0] == 0};
			end
      		else if (rg_numer >= rg_denom2)
			begin
				rg_numer <= rg_numer - rg_denom2;
				rg_quo <= rg_quo + rg_n;
			end
		else
			begin
				rg_denom2 <= rg_denom2 >> 1;
				rg_n <= rg_n >> 1;
			end
	endrule

method Action start;
      rg_state           <= Div_START;
endmethod

interface inoutifc = toGPServer (fifo_input_reg, fifo_output_reg);

endmodule

endpackage: IntDiv
