package Testbench;

// ================================================================
// BSV Library imports

import GetPut       :: *;
import ClientServer :: *;
import FIFO 	    :: *;
import Vector       :: *;

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
      let data_in = Wrapper_in_req {data1:32'h0, data2: 32'h6, rg_sel:  3'b111, reg_d: 5'b00011, opcode: 7'h8, val_pro: 1'b1};   //data to be sent to wrapper via ROC
      wrap.serverCPU.request.put(data_in);  // send data via ROCC only if positcore ready

   endrule



   rule read_from_ROCC;						//rule to send data back to flute from accelerator via ROCC
      let data_out<-wrap.serverCPU.response.get();  		// get output from wrapper
      if(data_out.val_acc==1) begin  				// consider data valid, only if value bit sent by wrapper is high
        $display("output=%b, exception=%b, quire=%h", data_out.result_melodica.P, data_out.exception, data_out.quire);
      end
        $finish;
   endrule

   
  
   rule mem_block;
     let req <- wrap.clientMEM.request.get();

 function Action fa_reqToMem(Bit#(64) memdata);  //function to send data to positaccel from memory
   return
        action

	   if(req.load_store == 1'b0) begin   //This is dummy condition. Actual condition will be "if tag/index bit match (data in cache)"  send valid bit 1.
   	let mem_rsp = Mem_Rsp {vdata_load1:memdata, valid:1'b1};
	wrap.clientMEM.response.put(mem_rsp);
     end

     else begin        // if data not available in cache send valid bit 0 so that new address is not updated and no new request is sent
    	let mem_rsp = Mem_Rsp {vdata_load1:memdata, valid: 1'b0};
        wrap.clientMEM.response.put(mem_rsp);    
     end

        endaction;        
   endfunction

   if (req.addr1 % 8 == 0 && req.load_store == 1'b0) begin   //double word (64 bit) aligned address and if its load instruction
	case(req.addr1)                //function call if address matches send corresponding 2 consecutive 32 bit posits (64 bits)
	   32'h0: fa_reqToMem(64'h1);
	   32'h8: fa_reqToMem(64'h2);
	   32'h10: fa_reqToMem(64'h3);
	   32'h18: fa_reqToMem(64'h4);
	   32'h20: fa_reqToMem(64'h5);
	   32'h28: fa_reqToMem(64'h6);
	   default: fa_reqToMem(64'h0);             
	endcase
   end
 
   
endrule
    
 
endmodule
// ================================================================
endpackage



