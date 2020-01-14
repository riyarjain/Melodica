// HPC Lab, Department of Electrical Engineering, IIT Bombay
//make compile link link_d
//./out_d
package Testbench;

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
import PNE              :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Pipeline_reg_N :: *;
import Utils :: *;
import "BDPI" positMAC16  = function Bit#(PositWidth) checkoperation (Bit#(PositWidth) in1, Bit#(PositWidth) in2, Bit#(PositWidth) in3)	;
`ifdef FPGA
interface FpgaLedIfc;
(* always_ready *)
method Bool chkComplete;
(* always_ready *)
method Bool completeWithErrors;
endinterface
`endif

`ifdef RANDOM_PRINT
typedef 100 Num_Tests;    // Number of random tests to be run
`elsif RANDOM
typedef 10000000 Num_Tests;    // Number of random tests to be run
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
LFSR  #(Bit #(PositWidth))            lfsr1          <- mkLFSR_16;
LFSR  #(Bit #(PositWidth))            lfsr2           <- mkLFSR_16;
LFSR  #(Bit #(PositWidth))            lfsr3           <- mkLFSR_16;
Reg   #(Bool)                 rgSetup        <- mkReg (False);
`endif

Reg   #(Bool)                 rgGenComplete  <- mkReg (False);

Reg   #(Bit #(PositWidth))   rgCurInput     <- mkReg (0000000000000100);
Reg   #(Bit #(PositWidth))   rgCurInput1     <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurInput2     <- mkReg (0000000000000100);
//`ifdef RANDOM
FIFO  #(Bit #(PositWidth))   ffInputVals    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))   ffInputVals1    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))   ffInputVals2    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
//`endif
//`endif
Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput1    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput2    <- mkReg (0);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bool)                 rgError        <- mkReg (False);

PNE            dut            <- mkPNE_test;	
Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule lfsrGenerate(!doneSet);
`ifdef RANDOM
	lfsr1.seed('h01);// to create different random series
	lfsr2.seed('h01);
	lfsr3.seed('h10);
`endif
	doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
`ifdef RANDOM
   // Drive input into DUT
   /*
   let inPosit11 = 16'b0000001111101000;
   let inPosit22 = 16'b0001000000000000;
   let inPosit33 = 16'b0001011011110101;
   //*/
   ///*
   let inPosit11 = lfsr1.value();
   let inPosit22 = lfsr2.value();
   let inPosit33 = lfsr3.value();
   //*/
$display("[%0d]Input tb",cur_cycle);
   dut.compute.request.put (InputThreePosit{posit_inp1 : truncate (inPosit11),posit_inp2 : truncate (inPosit22), posit_inp3 : truncate (inPosit33)});

   // Bookkeeping
   rgCurInput <= rgCurInput + 1;
   ffInputVals.enq (truncate (inPosit11));
   ffInputVals1.enq (truncate (inPosit22));
   ffInputVals2.enq (truncate (inPosit33));
   // Prepare LFSR for the next input
   lfsr1.next ();
   lfsr2.next ();
   lfsr3.next ();
   // Completion of test generation

   rgGenComplete <= ((rgCurInput + 1) == fromInteger (valueOf (Num_Tests)));

`else
   // Drive input into DUT
   dut.compute.request.put (InputThreePosit{posit_inp1 : truncate (rgCurInput),posit_inp2 : truncate (rgCurInput1) ,posit_inp3 : truncate (rgCurInput2) });
   // Prepare for next input
	ffInputVals.enq (truncate (rgCurInput));
   	ffInputVals1.enq (truncate (rgCurInput1));
   	ffInputVals2.enq (truncate (rgCurInput2));
	if((rgCurInput2 + 1) == 0)
			begin
				rgCurInput2 <= 0;
				if((rgCurInput1 + 1) == 0)
					begin
						rgCurInput1 <= 0;
						rgCurInput <= rgCurInput + 1;
					end
				else
					begin
						rgCurInput1 <= rgCurInput1 + 1;
					end
				end
	else
		begin
			rgCurInput2 <= rgCurInput2 + 1;
		end



   // Completion of test generation
   rgGenComplete <= ((rgCurInput + 1) == 0 && (rgCurInput1 + 1) == 0 && (rgCurInput2 + 1) == 0);
`endif
endrule



// --------
//rule rlCheck (!rgChkComplete && !rgError);
rule rlCheck (!rgChkComplete && doneSet );
      let rsp <- dut.compute.response.get ();
      let input1_c = ffInputVals.first; ffInputVals.deq;
      let input2_c = ffInputVals1.first; ffInputVals1.deq;
      let input3_c = ffInputVals2.first; ffInputVals2.deq;
      let expected = checkoperation(input1_c,input2_c,input3_c);
   `ifdef RANDOM
      
      // Detected an error
      if (rsp.out_posit != expected) begin
         $display ("[%0d]::ERR::Input=%b::Input2=%b::Input3=%b::Expected Output=%b::Output=%b", $time, input1_c,input2_c,input3_c,expected, rsp.out_posit);
         rgError <= True;
	 wrongOut <= wrongOut+1;
         
      end
      $display("[%0d]Output tb",cur_cycle);
         rgCurOutput <= rgCurOutput + 1;
		//$display("rgCurOutput %b",rgCurOutput);
         // Completion condition
         rgChkComplete <= ((rgCurOutput + 1) == fromInteger (valueOf (Num_Tests)));
     // end

   `else
      //let expected = rgCurOutput;

      // Detected an error
      if (rsp.out_posit != expected) begin
         $display ("[%0d]::ERR::Input=%b::Input2=%b::Input3=%b::Expected Output=%b::Output=%b", $time, input1_c,input2_c,input3_c,expected, rsp.out_posit);
         rgError <= True;
	 wrongOut <= wrongOut+1;
      end

         // Next output expected
	if((rgCurOutput2 + 1) == 0)
			begin
				rgCurOutput2 <= 0;
				if((rgCurOutput1 + 1) == 0)
					begin
						rgCurOutput1 <= 0;
						rgCurOutput <= rgCurOutput + 1;
					end
				else
					begin
						rgCurOutput1 <= rgCurOutput1 + 1;
					end
				end
	else
		begin
			rgCurOutput2 <= rgCurOutput2 + 1;
		end

         // Completion condition
   	rgChkComplete <= ((rgCurOutput + 1) == 0 && (rgCurOutput1 + 1) == 0 && (rgCurOutput2 + 1) == 0);
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


