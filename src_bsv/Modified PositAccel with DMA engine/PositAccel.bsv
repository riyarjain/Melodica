package PositAccel;

// ================================================================
// BSV Library imports


import GetPut       :: *;
import ClientServer :: *;
import FIFO         :: *;
import FShow        :: *;
import Vector 	    :: *;
//import FIFOF        :: *;
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
typedef Vector #(6, Reg#(Bit#(PositWidth))) Vec_op;      //vector to store memory words

// ================================================================
typedef enum {ROCC_REQ, ROCC_RSP, ROCC_MEM_REQ} AccelState deriving (Bits, Eq, FShow);         


//ROCC: Data transfer occurs only if reciever gives ready signal high and sender give data with value value bit high (stating it to be valid) simultaneously

// ================================================================
//PositAccel interface

interface Wrapper_IFC; 
   interface Server #(Wrapper_in_req,Wrapper_in_res)  serverCPU; //server interface for PositAccel to take data from processor
   interface Client #(Mem_Req, Mem_Rsp) clientMEM;               //client interface for Memory interface
endinterface

// ================================================================

(* synthesize *)
module mkPositAccel(Wrapper_IFC);

   FIFO #(Wrapper_in_req) ff_ROCCReq <- mkFIFO;    //FIFO to receive data from flute
   FIFO #(Wrapper_in_res) ff_ROCCRsp <- mkFIFO;    //FIFO to send back data to flute   
   FIFO #(Mem_Req) ff_MemReq <- mkFIFO; 	   //FIFO to send memory request
   FIFO #(Mem_Rsp) ff_MemRsp <- mkFIFO;            //FIFO to receive memory response
   Vec_op vd1 <- replicateM(mkRegU);			   // vector 1
   Vec_op vd2 <- replicateM(mkRegU);		           //vector 2 
   Reg #(AccelState) rg_state <- mkReg (ROCC_REQ);    // Accelerator top state vector
   Reg #(Bit#(PositWidth)) addr1 <- mkRegU;    	      // to store address of memory

 
   Reg #(Bit#(32)) w_cnt <- mkReg(0);	           // to store the word count(dynamic)
   Reg #(Bit#(32)) w_cnt_original <- mkReg(0);	   // to store the word count(constant)
   Reg #(Bit#(1)) crg[2] <- mkCReg(2,1'b1);        //to store valid bit received from memory
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
		rg_state <= ROCC_RSP;                              //change state only if val_pro is high
				    
            end 
        endaction;        
   endfunction



   rule rl_ROCCReq (rg_state == ROCC_REQ); 		      //rule to read data sent by flute via ROCC into PositAccel
      addr1 <= roccReq.data1;         		              //irrepective of mem function store the address to save a cycle if its actually mem func
      w_cnt_original <= roccReq.data2;			      //irrepective of mem function, store the count_unchanged to save a cycle if its actually mem func		
      w_cnt <= roccReq.data2;		       		      //irrepective of mem function, store the count_changing to save a cycle if its actually mem func
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
            f7_mem     : rg_state <= ROCC_MEM_REQ;        // change state to ROCC_MEM_REQ if opcode is mem func
	    default    : fa_reqToPositCore(FMA_P);
      endcase
   endrule



   rule rl_ROCCMemReq (rg_state == ROCC_MEM_REQ);   //rule to send load request to memory : crg corresponds to valid loaded data for previous address through port 1
		let mem_req = Mem_Req {addr1:addr1, load_store: 1'b0, vdata_store:0};     //send address, load signal and data to be stored (here not needed)
		if(crg[1]==1'b1) begin     //send new request only if valid data is received
     		 addr1<= addr1 + (32/4);   //updating address to load new word assuming byte organized memory (PositWidth in place of 32)
		 ff_MemReq.enq(mem_req);        
   		end
   endrule


  rule rl_ROCCMemRsp (rg_state == ROCC_MEM_REQ);         // rule to receive loaded data from memory and make 2 vectors to be sent to melodica
        Mem_Rsp mem_rsp = ff_MemRsp.first; ff_MemRsp.deq;    //resd memory response from FIFO
	if(mem_rsp.valid==1'b1) begin       //make vectors only if valid data is loaded
		if (w_cnt>=1) begin             //condition for making 2 vectors of 6 words each
			vd1[w_cnt_original-w_cnt] <= mem_rsp.vdata_load1[63:32];        //first vector holds 1st posit of 32 bits  (as of now)
                        $display("%d:data1 = %h, count= %h",cur_cycle, mem_rsp.vdata_load1[63:32], w_cnt);
			vd2[w_cnt_original-w_cnt] <= mem_rsp.vdata_load1[31:0];       // second vector holds 2nd posit of 32 bits (as of now)
                        $display("%d:data2 = %h, count= %h",cur_cycle, mem_rsp.vdata_load1[31:0], w_cnt);

		end
		else if(w_cnt == 0) begin       // condition to change state or do function call to send vectors to melodica when both vectors are formed
			$display("v11=%h, v12=%h, v13=%h, v14=%h, v15=%h, v16=%h\nv21=%h, v22=%h, v23=%h, v24=%h, v25=%h, v26=%h", vd1[0], vd1[1], vd1[2], vd1[3], vd1[4], vd1[5], vd2[0], vd2[1], vd2[2], vd2[3], vd2[4], vd2[5]);    //display vector elements
			$finish;  //finish
		end

		w_cnt <= w_cnt - 1;            // updating the wordcount left to be loaded
	end
	crg[0] <= mem_rsp.valid;            // valid bit in CREG through port 0

    endrule



   rule rl_ROCCRsp (rg_state == ROCC_RSP);         //rule to write back from PositAccel to flute via ROCC
      let acc_output <- pos.server_core.response.get ();
      let r_destination = ff_ROCCReq.first.reg_d;           // to read destination register 
      let data_out = Wrapper_in_res {result_melodica:tpl_1(acc_output), exception:tpl_2(acc_output), quire:tpl_3(acc_output), reg_d:r_destination,  val_acc:1'b1};            // struct to be sent to flute
      ff_ROCCRsp.enq(data_out);       //enq in FIFO of server
      ff_ROCCReq.deq;
      rg_state <= ROCC_REQ;
   endrule

   // =============================================================
   // INTERFACE

   interface Server serverCPU = toGPServer(ff_ROCCReq, ff_ROCCRsp);            //server connection with flute to receive data from flute
   interface Client clientMEM = toGPClient(ff_MemReq, ff_MemRsp);	      //client conection with memory
endmodule
// ================================================================

endpackage
