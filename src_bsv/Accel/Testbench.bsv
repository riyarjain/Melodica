package Testbench;

// ================================================================
// BSV Library imports

import GetPut       :: *;
import ClientServer :: *;
import FIFO 	    :: *;

// ================================================================
// Project imports
import Accel_Defines       :: *;
import PositAccel          :: *;
import PositCore           ::*;
import Posit_Numeric_Types :: *;
import FloatingPoint 	   :: *;
import Utils 		   :: *;
import Normalizer_Types    :: *;
import Posit_User_Types    :: *;

// ================================================================
(* synthesize *)
module mkTestbench (Empty);

   Wrapper_IFC wrap <- mkPositAccel;                   //instantiate wrapper
 
   // ================================================================
   //Behaviour

   rule send_to_ROCC;		                       //rule to send data to wrapper from flute via ROCC
      let data_in = Wrapper_in_req {data1:32'h187b, data2: 32'h1234, rg_sel:  3'b111, reg_d: 5'b00011, opcode: 7'h0, val_pro: 1'b1};   //data to be sent to wrapper via ROC
      wrap.serverCPU.request.put(data_in);  // send data via ROCC only if positcore ready
   endrule



   rule read_from_ROCC;						//rule to send data back to flute from accelerator via ROCC
      let data_out<-wrap.serverCPU.response.get();  		// get output from wrapper
      if(data_out.val_acc==1) begin  				// consider data valid, only if value bit sent by wrapper is high
        $display("output=%b, exception=%b, quire=%h", data_out.result_melodica.P, data_out.exception, data_out.quire);
      end
        $finish;
   endrule


endmodule
// ================================================================
endpackage



