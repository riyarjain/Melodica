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
import Vector           :: *;
import Posit_Numeric_Types :: *;
import Posit_User_Types :: *;
import Normalizer_Types :: *;
import FMA_PNE_Quire ::*;


`ifdef P8
import "BDPI" c_fmaAdd8 = function Bit#(QuireWidth) c_reference_fma (Bit#(QuireWidth) q, Bit#(PositWidth) p1, Bit#(PositWidth) p2);
`endif
`ifdef P16
import "BDPI" c_fmaAdd16 = function Bit #(QuireWidth) c_reference_fma (Bit #(QuireWidth) q, Bit#(PositWidth) p1, Bit#(PositWidth) p2);
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
typedef 4096 Num_Tests;
`elsif P32
typedef 4096 Num_Tests;
`endif

typedef 20 Pipe_Depth;      // Estimated pipeline depth of the PNE

// -----------------------------------------------------------------

// 32-bit LFSR is the widest lfsr available. So we will use
// multiple of them to generate the quire
typedef TDiv#(QuireWidth, 32) QuireWidthInWords;

//
// Module definition
(* synthesize *)
`ifdef FPGA
module mkTestbench (FpgaLedIfc);
`else
module mkTestbench (Empty);
`endif
   // Depending on which input mode we are using, the input to the
   // DUT will be from a LFSR or from a counter. The LFSR is
   // always sized to the maximal size
   FIFO #(InputQuireTwoPosit) ff_dut_inputs <- mkSizedFIFO (valueOf (TAdd #(Pipe_Depth, 2)));
   Reg #(Bit #(16)) rg_num_ins <- mkReg (0);
   Reg #(Bit #(16)) rg_num_outs <- mkReg (0);
   Reg #(Bool) rgGenComplete  <- mkReg (False);

`ifdef RANDOM
   Vector #(QuireWidthInWords, LFSR #(Bit #(32))) qlfsr <- replicateM(mkLFSR_32);
   Vector #(2, LFSR #(Bit #(32))) plfsr <- replicateM (mkLFSR_32);
`else
   Reg #(Bit #(QuireWidth)) rg_ctr_quire <- mkReg ('h12345678123456781234567812345678);
   Reg #(Bit #(PositWidth)) rg_ctr_posit_1 <- mkReg (0);
   Reg #(Bit #(PositWidth)) rg_ctr_posit_2 <- mkReg (0);
`endif

Reg   #(Bit#(TAdd#(PositWidth,PositWidth)))   wrongOut    <- mkReg (0);
Reg   #(Bool)                 rgChkComplete  <- mkReg (False);
Reg   #(Bool)                 rgError        <- mkReg (False);

FMA_PNE_Quire            dut            <- mkPNE_test;	
Reg #(Bool) doneSet <-mkReg(False);
// -----------------------------------------------------------------

rule rl_init (!doneSet);
`ifdef RANDOM
   Bit #(32) seed = 'h12345678;
   for (Integer i=0; i<valueOf (QuireWidthInWords); i=i+1) begin
      qlfsr[i].seed (seed);
      seed = seed << 1;
   end
   for (Integer i=0; i<2; i=i+1) begin
      plfsr[i].seed (seed);
      seed = seed << 1;
   end
`endif
   doneSet<= True;
endrule

rule rlGenerate (!rgGenComplete && doneSet);
`ifdef RANDOM
   // Form the quire from the constituent lfsrs
   Bit# (QuireWidth) inQuire = 0;
   for (Integer i=0; i<valueOf (QuireWidthInWords); i=i+1) begin
      inQuire = inQuire | ((extend (qlfsr[i].value)) << (i*32));
      qlfsr [i].next;
   end
   for (Integer i=0; i<2; i=i+1) plfsr [i].next;

   let dut_in = InputQuireTwoPosit {
        quire_inp : inQuire
      , posit_inp1 : truncate (plfsr[0].value)
      , posit_inp2 : truncate (plfsr[1].value)};
   
`else
   // Drive input into DUT
   let dut_in = InputQuireTwoPosit {
        quire_inp : rg_ctr_quire
      , posit_inp1 : rg_ctr_posit_1
      , posit_inp2 : rg_ctr_posit_2};

   // prepare for next set of inputs
   rg_ctr_quire <= rg_ctr_quire + 1;
   rg_ctr_posit_1 <= rg_ctr_posit_1 + 1;
   rg_ctr_posit_2 <= rg_ctr_posit_2 + 1;
`endif

   // drive the input into the DUT
   dut.compute.request.put (dut_in);

   // Bookkeeping
   ff_dut_inputs.enq (dut_in);
   rg_num_ins <= rg_num_ins + 1;

   // Completion of test generation
   rgGenComplete <= ((rg_num_ins + 1) == fromInteger (valueOf (Num_Tests)));

endrule


// --------
//rule rlCheck (!rgChkComplete && !rgError);
rule rlCheck (!rgChkComplete && doneSet );
   let rsp <- dut.compute.response.get ();
   let dut_in = ff_dut_inputs.first; ff_dut_inputs.deq;
   let expected = c_reference_fma (
        dut_in.quire_inp
      , dut_in.posit_inp1
      , dut_in.posit_inp2);

   // Detected an error
   if (rsp != expected) begin
      $display (
           "[%0d]::ERR::(Q-IN=%h::P1-IN=%h::P2-IN=%h) -> (REF=%h)"
         , $time, dut_in.quire_inp, dut_in.posit_inp1,dut_in.posit_inp2, expected);
      $display (
           "[%0d]::ERR::(Q-IN=%h::P1-IN=%h::P2-IN=%h) -> (DUT=%h)"
         , $time, dut_in.quire_inp, dut_in.posit_inp1,dut_in.posit_inp2, rsp);
      $display ("--------");
      rgError <= True;
      wrongOut <= wrongOut+1;
   end
      
   rg_num_outs <= rg_num_outs + 1;

   // Completion condition
   rgChkComplete <= ((rg_num_outs + 1) == fromInteger (valueOf (Num_Tests)));
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


