package PositAccel;

// ================================================================
// BSV Library imports


import GetPut       :: *;
import ClientServer :: *;
import FIFO         :: *;
import FShow        :: *;

// ================================================================
// Project imports
import FloatingPoint       :: *;
import Accel_Defines       :: *;
import PositCore           :: *;
import Posit_Numeric_Types :: *;
import Utils               :: *;
import Posit_User_Types    :: *;

// ================================================================
//tuples for PositCore

typedef Tuple4 #(PositCore::FloatU, PositCore::FloatU, RoundMode, PositCore::PositCmds) Wrapper_out_req;  //tuple to send data to posit core (as positcore takes input as tuple)
typedef Tuple3 #(PositCore::FloatU, FloatingPoint::Exception, Bit#(QuireWidth)) Wrapper_out_res;          //tuple to receive data from posit core (as positcore gives output as tuple)

// ================================================================
typedef enum {ROCC_REQ, ROCC_RSP} AccelState deriving (Bits, Eq, FShow);


//ROCC: Data transfer occurs only if reciever gives ready signal high and sender give data with value value bit high (stating it to be valid) simultaneously

// ================================================================
//PositAccel interface

interface Wrapper_IFC; 
   interface Server #(Wrapper_in_req,Wrapper_in_res)  serverCPU; //server  interface for PositAccel to take data from processor
endinterface

// ================================================================

(* synthesize *)
module mkPositAccel(Wrapper_IFC);

   FIFO #(Wrapper_in_req) ff_ROCCReq <- mkFIFO;    //FIFO to receive data from flute
   FIFO #(Wrapper_in_res) ff_ROCCRsp <- mkFIFO;    //FIFO to send back data to flute        
   Reg #(AccelState) rg_state <- mkReg (ROCC_REQ); // Accelerator top state vector
   PositCore_IFC pos <- mkPositCore(2);      	   //instantiate positcore 	

   // =============================================================
   // BEHAVIOR
   
   Wrapper_in_req roccReq = ff_ROCCReq.first;     //Read the struct from ROCC into PositAccel
   function Action fa_reqToPositCore (PositCmds cmd);  //function to send data to posit core with argument as funct7 from flute
   return
        action
	  RoundMode round_mode = Rnd_Nearest_Even;  //rounding to nearest even: can be changed by flute but as of now its fixed in posit core
	  FloatU in1 = tagged P roccReq.data1;   //convert data to FloatU for positcore to use
      	  FloatU in2 = tagged P roccReq.data2;   //convert data to FloatU for positcore to use
              if(roccReq.rg_sel==3'b111 && roccReq.val_pro==1)begin   //address bits of custom instruction (as per ROCC) stating rs1,rs2,rd are of processor and val_pro (value bit from processor stating valid data)
                let acc_input = tuple4(in1, in2, round_mode, cmd);       //tuple for positcore
                pos.server_core.request.put(acc_input);                  //Send to positcore
              end                            
        endaction;        
   endfunction


   rule rl_ROCCReq (rg_state == ROCC_REQ); //rule to read data sent by flute via ROCC into PositAccel
      rg_state <= ROCC_RSP;
      $display("operand 1=%b, operand 2=%b, control bit=%b,value=%b",roccReq.data1,roccReq.data2,roccReq.opcode,roccReq.val_pro);
  
      //decode the command (funct7) and do function call with posit command
      case(roccReq.opcode)             
            f7_fma_p   : fa_reqToPositCore(FMA_P); 
            f7_fda_p   : fa_reqToPositCore(FDA_P);
            f7_fms_p   : fa_reqToPositCore(FMS_P);
            f7_fds_p   : fa_reqToPositCore(FDS_P);
            f7_fcvt_p_s: fa_reqToPositCore(FCVT_P_S);
            f7_fcvt_s_p: fa_reqToPositCore(FCVT_S_P);
            f7_fcvt_p_r: fa_reqToPositCore(FCVT_P_R);
            f7_fcvt_r_p: fa_reqToPositCore(FCVT_R_P);
            default    : fa_reqToPositCore(FMA_P);
      endcase
   endrule
   

   rule rl_ROCCRsp (rg_state == ROCC_RSP);         //rule to write back from PositAccel to flute via ROCC
      let acc_output <- pos.server_core.response.get ();
      let r_destination = ff_ROCCReq.first.reg_d;           // to read destination register 
      let data_out = Wrapper_in_res {result_melodica:tpl_1(acc_output),      exception:tpl_2(acc_output), quire:tpl_3(acc_output), reg_d:r_destination,  val_acc:1'b1};                                    // struct to be sent to flute
                               
      ff_ROCCRsp.enq(data_out);       //enq in FIFO of server
      ff_ROCCReq.deq;
      rg_state <= ROCC_REQ;
   endrule

   // =============================================================
   // INTERFACE

   interface Server serverCPU = toGPServer(ff_ROCCReq, ff_ROCCRsp);            
   //server connection with flute to receive data from flute

endmodule
// ================================================================

endpackage
