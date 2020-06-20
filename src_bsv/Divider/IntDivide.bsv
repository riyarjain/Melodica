package IntDivide;

import FIFO        :: *;
import GetPut       :: *;
import ClientServer :: *;
import Posit_User_Types :: *;
import Posit_Numeric_Types :: *;

typedef FracWidthPlus1 Denom_bits;
typedef TAdd#(TSub#(Numer_bits,Denom_bits),1) Quo_bits;
typedef FracWidthPlus1Mul2Plus1 Numer_bits;
typedef Denom_bits Rem_bits;


typedef struct	{Bit#(Denom_bits) numerator;
		Bit#(Denom_bits) denominator;} Input_intdiv deriving(Bits,FShow);

typedef struct	{Bit#(Quo_bits) quotient;
		Bit#(1) truncated_frac_msb;
		Bit#(1) truncated_frac_zero;} Output_intdiv deriving(Bits,FShow);

interface IntDivide ;
	interface Server #(Input_intdiv,Output_intdiv) inoutifc;
endinterface

typedef enum { Div_START, Div_LOOP1, Div_LOOP2, Div_DONE} DivState
   deriving (Eq, Bits, FShow);


module mkIntDivide (IntDivide);

	FIFO #(Output_intdiv) fifo_output_reg <- mkFIFO;

	Reg #(DivState)  rg_state     <- mkReg (Div_START);
	Reg #(Bit #(Numer_bits))  rg_numer    <- mkRegU;
	Reg #(Bit #(Denom_bits))  rg_denom    <- mkRegU;
	Reg #(Bit #(Numer_bits))  rg_denom2    <- mkRegU;
	Reg #(Bit #(Quo_bits))  rg_n         <- mkRegU;
	Reg #(Bit #(Quo_bits))  rg_quo       <- mkRegU;


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
								  truncated_frac_msb : msb(rem_truncate),
								  truncated_frac_zero : pack((rem_truncate<<1) == 0)});
			`ifdef RANDOM_PRINT
			$display("Division complete");
			$display("quo %b",quo);
			`endif	
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
		`ifdef RANDOM_PRINT
			$display("rg_numer %b",rg_numer);
			$display("rg_denom %b",rg_denom);
			$display("rg_quo %h",rg_quo);
		`endif	
	endrule

interface Server inoutifc;
      interface Put request;
         method Action put (Input_intdiv p) if (rg_state == Div_START || rg_state == Div_DONE );
		let dIn = p;
		let numer = dIn.numerator;	
		let denom = dIn.denominator;
		if(denom == 0)
			begin
				rg_quo   <= '1;        // all bits set
				// Rem_bits is rg_numer
				rg_state <= Div_DONE;
				fifo_output_reg.enq(Output_intdiv{quotient : rg_quo,
								  truncated_frac_msb : 1'b0,
								  truncated_frac_zero : 1'b1});
				`ifdef RANDOM_PRINT
				$display("Division complete");
				`endif	
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
		`ifdef RANDOM_PRINT
			$display("rg_numer %b",rg_numer);
			$display("rg_denom %b",rg_denom);
			$display("rg_quo %h",rg_quo);
		`endif

   endmethod
      endinterface
      interface Get response = toGet (fifo_output_reg);
   endinterface
endmodule

endpackage: IntDivide
