// HPC Lab, Department of Electrical Engineering, IIT Bombay
//make compile link link_d
//./out_d
package Fma_Tb;

// -----------------------------------------------------------------
// This package defines:
//
//    mkTestbench      : Pipeline level testbench for the PE sub-
//                     pipelines. These testbenches are meant to
//                     also run on FPGA when compiled with the
//                     -D FPGA flag
//
// -----------------------------------------------------------------

import ClientServer     :: *;
import GetPut           :: *;
import FIFO             :: *;
import LFSR             :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Normalizer_Types :: *;
import FMA_PNE_Quire ::*;

`ifdef P8
import "BDPI" fmaAdd8 = function Bit#(QuireWidth) checkoperation (Bit#(QuireWidth) in1,Bit#(PositWidth) in3, Bit#(PositWidth) in4);
`elsif P16
import "BDPI" fmaAdd16 = function Bit#(QuireWidth) checkoperation (Bit#(QuireWidth) in1,Bit#(PositWidth) in3, Bit#(PositWidth) in4);
`elsif P32
import "BDPI" fmaAdd32 = function Bit#(QuireWidth) checkoperation (Bit#(QuireWidth) in1,Bit#(PositWidth) in3, Bit#(PositWidth) in4);
`endif


`ifdef FPGA
interface FpgaLedIfc;
(* always_ready *)
method Bool chkComplete;
(* always_ready *)
method Bool completeWithErrors;
endinterface
`endif


// Number of random tests to be run
`ifdef P8
typedef 255 Num_Tests;
`elsif P16
typedef 1024 Num_Tests;
`elsif P32
typedef 4096 Num_Tests;
`endif

typedef 20 Pipe_Depth;      // Estimated pipeline depth of the PNE

// -----------------------------------------------------------------


//
// Module definition
(* synthesize *)
`ifdef FPGA
module mkTestbench (FpgaLedIfc);
`else
module mkTestbench (Empty);
`endif
// Depending on which input mode we are using, the input to the DUT will be
// from a LFSR or from a counter. The LFSR is always sized to the maximal size
`ifdef RANDOM
	LFSR  #(Bit #(32))            lfsr1          <- mkLFSR_32;
	LFSR  #(Bit #(32))            lfsr2          <- mkLFSR_32;
	LFSR  #(Bit #(32))    	      lfsr1m          <- mkLFSR_32;
	LFSR  #(Bit #(32))            lfsr2m          <- mkLFSR_32;
Reg   #(Bool)                 rgSetup        <- mkReg (False);
`endif

Reg   #(Bool)                 rgGenComplete  <- mkReg (False);

Reg   #(Bit #(QuireWidth))    rgCurInput     <- mkReg (0);
Reg   #(Bit #(PositWidth))    rgCurInput3     <- mkReg (0);
Reg   #(Bit #(PositWidth))    rgCurInput2     <- mkReg (0);

FIFO  #(Bit #(QuireWidth)) ffInputVals    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))    ffInputVals3    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))    ffInputVals2    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));

Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);
Reg   #(Bit #(QuireWidth))   rgCurOutput    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput3    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput2    <- mkReg (0);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bool)                 rgError        <- mkReg (False);

FMA_PNE_Quire            dut            <- mkPNE_test;	
Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule lfsrGenerate(!doneSet);
`ifdef RANDOM
	lfsr1.seed('h16);// to create different random series
	lfsr2.seed('h12);// to create different random series
	lfsr1m.seed('h18);// to create different random series
	lfsr2m.seed('h02);// to create different random series
`endif
	doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
`ifdef RANDOM
   // Drive input into DUT
   /*
   Bit#(QuireWidth) inPosit11 = 64'h4a49d66167828429;
   Bit#(PositWidth) inPosit33 = 0;
   Bit#(PositWidth) inPosit44 = 0;
   //*/
   ///*
`ifdef P8
   Bit#(QuireWidth) inPosit11 = extend(lfsr1.value());
`else
   Bit#(QuireWidth) inPosit11 = extend({lfsr1.value(),lfsr2.value()});
`endif 
   Bit#(PositWidth) inPosit33 = truncate(lfsr1m.value());
   Bit#(PositWidth) inPosit44 = truncate(lfsr2m.value());
   dut.compute.request.put (InputQuireTwoPosit{quire_inp : inPosit11, posit_inp1 : inPosit33, posit_inp2 : inPosit44});
   // Bookkeeping
   rgCurInput <= rgCurInput + 1;
   ffInputVals.enq (extend (inPosit11));
   ffInputVals2.enq (truncate (inPosit33));
   ffInputVals3.enq (truncate (inPosit44));
   // Prepare LFSR for the next input
   lfsr1.next ();
   lfsr2.next ();
   lfsr1m.next ();
   lfsr2m.next ();
   // Completion of test generation

   rgGenComplete <= ((rgCurInput + 1) == fromInteger (valueOf (Num_Tests)));

`else
   // Drive input into DUT
   dut.compute.request.put (InputQuireTwoPosit{quire_inp : rgCurInput,posit_inp1 : rgCurInput2, posit_inp2 : rgCurInput3});
  // dut.compute.request.put (rgCurInput);
   // Prepare for next input
	ffInputVals.enq (rgCurInput);
	ffInputVals2.enq (rgCurInput2);
	ffInputVals3.enq (rgCurInput3);
	if((rgCurInput + 1) == 0)
			begin
				rgCurInput <= 0;
				if((rgCurInput2 + 1) == 0)
					begin
						rgCurInput2 <= 0;
						rgCurInput3 <= rgCurInput3 + 10;
					end
				else
						rgCurInput2 <= rgCurInput2 + 5;
			end
		else
			rgCurInput <= rgCurInput + 1;
	end

	   // Completion of test generation
   rgGenComplete <= ((rgCurInput + 1) == 0 && (rgCurInput2 + 1) == 0 && (rgCurInput3 + 1) == 0);
`endif
endrule



// --------
//rule rlCheck (!rgChkComplete && !rgError);
rule rlCheck (!rgChkComplete && doneSet );
      let rsp <- dut.compute.response.get ();
	let input1_c = ffInputVals.first; ffInputVals.deq;
	let input3_c = ffInputVals2.first; ffInputVals2.deq;
	let input4_c = ffInputVals3.first; ffInputVals3.deq;
	let expected0 = checkoperation(input1_c,input3_c,input4_c);
   `ifdef RANDOM
      
      // Detected an error
      if (rsp != expected0) begin
         `ifdef RANDOM
	$display ("[%0d]::ERR::Quire_Input=%h::Input1=%h::Input2=%h::Expected Output=%h::Output=%h", $time, input1_c,input3_c,input4_c,expected0, rsp);
	`else RANDOM_PRINT
	$display ("[%0d]::ERR::Quire_Input=%b::Input1=%b::Input2=%b::Expected Output=%b::Output=%b", $time, input1_c,input3_c,input4_c,expected0, rsp);
	`endif
         rgError <= True;
	 wrongOut <= wrongOut+1;
         
      end
      
         rgCurOutput <= rgCurOutput + 1;

         // Completion condition
         rgChkComplete <= ((rgCurOutput + 1) == fromInteger (valueOf (Num_Tests)));
     // end

   `else
      //let expected = rgCurOutput;

      // Detected an error
      if (rsp != expected0) begin
	$display ("[%0d]::ERR::Quire_Input=%h::Input1=%h::Input2=%h::Expected Output=%h::Output=%h", $time, input1_c,input3_c,input4_c,expected0, rsp);
         rgError <= True;
	 wrongOut <= wrongOut+1;
      end
	// Next output expected
	
		if((rgCurOutput + 1) == 0)
				begin
					rgCurOutput <= 0;
					if((rgCurOutput2 + 1) == 0)
						begin
							rgCurOutput2 <= 0;
							rgCurOutput3 <= rgCurOutput3 + 1;
						end
					else
							rgCurOutput2 <= rgCurOutput2 + 1;
					end
		
		else
				rgCurOutput <= rgCurOutput + 1;
	end
	
         // Completion condition
   	rgChkComplete <= ((rgCurOutput + 1) == 0 && (rgCurOutput2 + 1) == 0 && (rgCurOutput3 + 1) == 0);
      //end
   `endif
   endrule



// --------
//rule rlFinish (rgError || rgChkComplete);
rule rlFinish ( rgChkComplete && doneSet);
	$display ("%d",wrongOut);
   if (!rgError) $display ("[%0d]::INF::No errors found.", $time);
	else $display ("[%0d]::INF::with errors found.", $time);
   $finish;
endrule


// -----------------------------------------------------------------

//
// Interfaces
`ifdef FPGA
method Bool chkComplete = rgChkComplete;
method Bool completeWithErrors = rgError;
`endif

// -----------------------------------------------------------------

endmodule
endpackage

// -----------------------------------------------------------------


