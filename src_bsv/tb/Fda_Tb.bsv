// HPC Lab, Department of Electrical Engineering, IIT Bombay
//make compile link link_d
//./out_d
package Fda_Tb;

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
import FDA_PNE_Quire ::*;
import "BDPI" fdaAdd161 = function Bit#(QuireWidthBy2) checkoperation1 (Bit#(QuireWidthBy2) in1,Bit#(QuireWidthBy2) in2,Bit#(PositWidth) in3, Bit#(PositWidth) in4);
import "BDPI" fdaAdd162 = function Bit#(QuireWidthBy2) checkoperation2 (Bit#(QuireWidthBy2) in1,Bit#(QuireWidthBy2) in2,Bit#(PositWidth) in3, Bit#(PositWidth) in4);
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
LFSR  #(Bit #(32))            lfsr11          <- mkLFSR_32;
LFSR  #(Bit #(32))            lfsr22          <- mkLFSR_32;
LFSR  #(Bit #(PositWidth))    lfsr1m          <- mkLFSR_16;
LFSR  #(Bit #(PositWidth))    lfsr2m          <- mkLFSR_16;
Reg   #(Bool)                 rgSetup        <- mkReg (False);
`endif

Reg   #(Bool)                 rgGenComplete  <- mkReg (False);

Reg   #(Bit #(QuireWidthBy2)) rgCurInput     <- mkReg (0000000000000000);
Reg   #(Bit #(QuireWidthBy2)) rgCurInput1     <- mkReg (0000000010001010);
Reg   #(Bit #(PositWidth))    rgCurInput3     <- mkReg (00010000);
Reg   #(Bit #(PositWidth))    rgCurInput2     <- mkReg (0);

FIFO  #(Bit #(QuireWidthBy2)) ffInputVals    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(QuireWidthBy2)) ffInputVals1    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))    ffInputVals3    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
FIFO  #(Bit #(PositWidth))    ffInputVals2    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));

Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);
Reg   #(Bit #(QuireWidthBy2))   rgCurOutput    <- mkReg (0);
Reg   #(Bit #(QuireWidthBy2))   rgCurOutput1    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput3    <- mkReg (0);
Reg   #(Bit #(PositWidth))   rgCurOutput2    <- mkReg (0);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bool)                 rgError        <- mkReg (False);

FDA_PNE_Quire            dut            <- mkPNE_test;	
Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule lfsrGenerate(!doneSet);
`ifdef RANDOM
	lfsr1.seed('h16);// to create different random series
	lfsr2.seed('h12);// to create different random series
	lfsr11.seed('h04);// to create different random series
	lfsr22.seed('h11);// to create different random series
	lfsr1m.seed('h18);// to create different random series
	lfsr2m.seed('h02);// to create different random series
`endif
	doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
`ifdef RANDOM
   // Drive input into DUT
   /*
   //let inPosit11 = 64'hd3703af7c4bfa67e;
   //let inPosit22 = 64'h70a14b36b12fe9c8;
   let inPosit11 = 64'h0000000000000000;
   let inPosit22 = 64'h0000000000000000;
   let inPosit33 = 16'h187b;
   let inPosit44 = 16'h1111;
   //*/
   ///*
   Bit#(QuireWidthBy2) inPosit11 = {lfsr1.value(),lfsr11.value()};
   Bit#(QuireWidthBy2) inPosit22 = {lfsr2.value(),lfsr22.value()};
   Bit#(PositWidth) inPosit33 = lfsr1m.value();
   Bit#(PositWidth) inPosit44 = lfsr2m.value();
   //*/
   dut.compute.request.put (InputQuireTwoPosit{quire_inp : {inPosit11,inPosit22},posit_inp1 : inPosit33, posit_inp2 : inPosit44});
   // Bookkeeping
   rgCurInput <= rgCurInput + 1;
   ffInputVals.enq (truncate (inPosit11));
   ffInputVals1.enq (truncate (inPosit22));
   ffInputVals2.enq (truncate (inPosit33));
   ffInputVals3.enq (truncate (inPosit44));
   // Prepare LFSR for the next input
   lfsr1.next ();
   lfsr2.next ();
   lfsr11.next ();
   lfsr22.next ();
   lfsr1m.next ();
   lfsr2m.next ();
   // Completion of test generation

   rgGenComplete <= ((rgCurInput + 1) == fromInteger (valueOf (Num_Tests)));

`else
   // Drive input into DUT
   dut.compute.request.put (InputQuireTwoPosit{quire_inp : {rgCurInput,rgCurInput1},posit_inp1 : rgCurInput2, posit_inp2 : rgCurInput3});
  // dut.compute.request.put (rgCurInput);
   // Prepare for next input
	ffInputVals.enq (rgCurInput);
	ffInputVals1.enq (rgCurInput1);
	ffInputVals2.enq (rgCurInput2);
	ffInputVals3.enq (rgCurInput3);
	if((rgCurInput + 1) == 0)
	begin
		if((rgCurInput1 + 1) == 0)
			begin
				rgCurInput1 <= 0;
				if((rgCurInput2 + 1) == 0)
					begin
						rgCurInput2 <= 0;
						rgCurInput3 <= rgCurInput3 + 10;
					end
				else
						rgCurInput2 <= rgCurInput2 + 5;
			end
		else
			rgCurInput1 <= rgCurInput1 + 15;
	end
	else
		rgCurInput <= rgCurInput + 1;

	   // Completion of test generation
   rgGenComplete <= ((rgCurInput + 1) == 0 && (rgCurInput1 + 1) == 0 && (rgCurInput2 + 1) == 0 && (rgCurInput3 + 1) == 0);
`endif
endrule



// --------
//rule rlCheck (!rgChkComplete && !rgError);
rule rlCheck (!rgChkComplete && doneSet );
      let rsp <- dut.compute.response.get ();
	let input1_c = ffInputVals.first; ffInputVals.deq;
	let input2_c = ffInputVals1.first; ffInputVals1.deq;
	let input3_c = ffInputVals2.first; ffInputVals2.deq;
	let input4_c = ffInputVals3.first; ffInputVals3.deq;
	let expected0 = checkoperation1(input1_c,input2_c,input3_c,input4_c);
	let expected1 = checkoperation2(input1_c,input2_c,input3_c,input4_c);
   `ifdef RANDOM
      
      // Detected an error
      if (rsp != {expected0,expected1}) begin
         `ifdef RANDOM
	$display ("[%0d]::ERR::Input=%h::Input2=%h::Input3=%h::Input4=%h::Expected Output=%b::Output=%b", $time, input1_c,input2_c,input3_c,input4_c,{expected0,expected1}, rsp);
	`else RANDOM_PRINT
	$display ("[%0d]::ERR::Input=%b::Input2=%b::Input3=%b::Input4=%b::Expected Output=%b::Output=%b", $time, input1_c,input2_c,input3_c,input4_c,{expected0,expected1}, rsp);
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
      if (rsp != {expected0,expected1}) begin
	$display ("[%0d]::ERR::Input=%h::Input2=%h::Input3=%h::Input4=%h::Expected Output=%b::Output=%b", $time, input1_c,input2_c,input3_c,input4_c,{expected0,expected1}, rsp);
         rgError <= True;
	 wrongOut <= wrongOut+1;
      end
	// Next output expected
	if((rgCurOutput + 1) == 0)
	begin
		if((rgCurOutput1 + 1) == 0)
				begin
					rgCurOutput1 <= 0;
					if((rgCurOutput2 + 1) == 0)
						begin
							rgCurOutput2 <= 0;
							rgCurOutput3 <= rgCurOutput3 + 1;
						end
					else
							rgCurOutput2 <= rgCurOutput2 + 1;
					end
		
		else
				rgCurOutput1 <= rgCurOutput1 + 1;
	end
	else
		rgCurOutput <= rgCurOutput + 1;
         // Completion condition
   	rgChkComplete <= ((rgCurOutput + 1) == 0 && (rgCurOutput1 + 1) == 0 && (rgCurOutput2 + 1) == 0 && (rgCurOutput3 + 1) == 0);
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


