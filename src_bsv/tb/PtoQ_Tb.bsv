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
// THE SOFTWARE.package Extracter_Types;
package PtoQ_Tb;

// -----------------------------------------------------------------
// This package defines:
//
//    mkTestbench      : Pipeline level testbench for the PE sub-
//                     pipelines. These testbenches are meant to
//                     also run on FPGA when compiled with the
//                     -D FPGA flag
//
// -----------------------------------------------------------------
import  Vector        :: *;
import FIFO        :: *;
import GetPut       :: *;
import ClientServer :: *;

import Utils ::*;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import PositToQuire_PNE ::*;
import LFSR             :: *;
import "BDPI" quireToPosit16  = function Bit#(PositWidth) checkoperation (Bit#(64) in1,Bit#(64) in1)	;

// Number of random tests to be run
`ifdef P8
typedef 255 Num_Tests;
`elsif P16
typedef 1024 Num_Tests;
`elsif P32
typedef 4096 Num_Tests;
`endif

typedef 20 Pipe_Depth;      // Estimated pipeline depth of the PNE

(* synthesize *)
`ifdef FPGA
module mkTestbench (FpgaLedIfc);
`else
module mkTestbench (Empty);
`endif

`ifdef RANDOM
LFSR  #(Bit #(PositWidth))            lfsr1          <- mkLFSR_16;
`endif

Reg   #(Bit #(PositWidth))   rgCurInput     <- mkReg (0);
FIFO  #(Bit #(PositWidth))   ffInputVals    <- mkSizedFIFO (valueOf (
                                                   TAdd# (Pipe_Depth,2)));
Reg   #(Bool)                 rgGenComplete  <- mkReg (False);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bit #(PositWidth))   rgCurOutput    <- mkReg (0);
Reg   #(Bool)                 rgError        <- mkReg (False);
Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);

PositToQuire_PNE            dut            <- mkPNE_test;

Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule lfsrGenerate(!doneSet);
	`ifdef RANDOM
		lfsr1.seed('h03);// to create different random series
	`endif
		doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
	`ifdef RANDOM
		// Drive input into DUT
		//let inPosit11 = 16'b1000000000000010;
		let inPosit11 = lfsr1.value();
		dut.compute.request.put (truncate (inPosit11));

		rgCurInput <= rgCurInput + 1;
		ffInputVals.enq (truncate (inPosit11));

		lfsr1.next ();
		rgGenComplete <= ((rgCurInput + 1) == fromInteger (valueOf (Num_Tests)));

	`else
		dut.compute.request.put (truncate (rgCurInput));
		ffInputVals.enq (truncate (rgCurInput));
		rgCurInput <= rgCurInput + 1;
		rgGenComplete <= ((rgCurInput + 1)==0);

	`endif
endrule

rule rlPrint (!rgChkComplete && doneSet );
	let rsp <- dut.compute.response.get ();	
	Vector#(2, Bit#(QuireWidthBy2)) v_64 = unpack (rsp);
	let input1_c = ffInputVals.first; ffInputVals.deq;
	let expected = checkoperation(v_64[1],v_64[0]);
	if (input1_c != expected) begin
		 $display ("[%0d]::ERR::Input=%b::Expected Output=%b::Output=%b", $time, input1_c,expected, rsp);
		 rgError <= True;
		 wrongOut <= wrongOut+1;
         
     	 end
	`ifdef RANDOM
		rgChkComplete <= ((rgCurOutput + 1) == fromInteger (valueOf (Num_Tests)));
	`else
   		rgChkComplete <= ((rgCurOutput + 1)==0);
	`endif
	rgCurOutput <= rgCurOutput + 1;
endrule

rule rlFinish ( rgChkComplete && doneSet);
	$display ("%d",wrongOut);
   if (!rgError) $display ("[%0d]::INF::No errors found.", $time);
	else $display ("[%0d]::INF::with errors found.", $time);
   $finish;
endrule
endmodule


endpackage
