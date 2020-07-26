// Copyright (c) HPC Lab, Department of Electrical Engineering, IIT Bombay
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


package PtoF_Tb;

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
import PtoF_PNE              :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
`ifdef P8
import "BDPI" Posit8Tofloat =  function Bit#(FloatWidth) checkoperation (Bit#(PositWidth) in1)	;
`elsif P16
import "BDPI" Posit16Tofloat =  function Bit#(FloatWidth) checkoperation (Bit#(PositWidth) in1);
`elsif P32
import "BDPI" Posit32Tofloat  = function Bit#(FloatWidth) checkoperation (Bit#(PositWidth) in1)	;

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
LFSR  #(Bit #(PositWidth))            lfsr1          <- mkLFSR_32;
Reg   #(Bool)                 rgSetup        <- mkReg (False);
`endif

Reg   #(Bool)                 rgGenComplete  <- mkReg (False);

Reg   #(Bit #(PositWidth))   rgCurInput     <- mkReg (0);

//`ifdef RANDOM
FIFO  #(Bit #(PositWidth))   ffInputVals    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
//`endif
Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);
Reg   #(Bit #(FloatWidth))   rgCurOutput    <- mkReg (0);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bool)                 rgError        <- mkReg (False);

PtoF_PNE            dut            <- mkPNE_test;	
Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule lfsrGenerate(!doneSet);
`ifdef RANDOM
	lfsr1.seed('h08);// to create different random series
`endif
	doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
`ifdef RANDOM
   // Drive input into DUT
   //let inPosit11 = 32'b00000000000000000000000000000011;
   let inPosit11 = lfsr1.value();
   dut.compute.request.put (truncate (inPosit11));

   // Bookkeeping
   rgCurInput <= rgCurInput + 1;
   ffInputVals.enq (truncate (inPosit11));
   // Prepare LFSR for the next input
   lfsr1.next ();
   // Completion of test generation

   rgGenComplete <= ((rgCurInput + 1) == fromInteger (valueOf (Num_Tests)));

`else
   // Drive input into DUT
   dut.compute.request.put (truncate (rgCurInput));
   // Prepare for next input
	ffInputVals.enq (truncate (rgCurInput));
	rgCurInput <= rgCurInput + 1;
   // Completion of test generation
   rgGenComplete <= ((rgCurInput + 1) == 0);
`endif
endrule



// --------
//rule rlCheck (!rgChkComplete && !rgError);
rule rlCheck (!rgChkComplete && doneSet );
      let rsp <- dut.compute.response.get();
	let input1_c = ffInputVals.first; ffInputVals.deq;
	let expected = checkoperation(input1_c);
   `ifdef RANDOM
      
      // Detected an error
      if (rsp != expected) begin
         $display ("[%0d]::ERR::Input=%b::Expected Output=%b::Output=%b", $time, input1_c,expected, rsp);
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
      if (rsp != expected) begin
         $display ("[%0d]::ERR::Input=%b::Expected Output=%b::Output=%b", $time, input1_c,expected, rsp);
         rgError <= True;
	 wrongOut <= wrongOut+1;
      end

         // Next output expected
		rgCurOutput <= rgCurOutput + 1;
         // Completion condition
         rgChkComplete <= ((rgCurOutput + 1) == 0);
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


