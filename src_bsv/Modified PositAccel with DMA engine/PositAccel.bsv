package PositAccel;

// ================================================================
// BSV Library imports


import GetPut       :: *;
import ClientServer :: *;
import FIFO         :: *;
import FShow        :: *;
import Vector 	    :: *;

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

// ===============================================================
//vector for memory data

typedef Vector #(10, Reg#(Bit#(QuireWidth))) Vec_output;  //vector to store melodica output for memory based operation
// ================================================================
//FSM

typedef enum {ROCC_REQ, ROCC_RSP, ROCC_MEM_REQ, IDEAL1} AccelState deriving (Bits, Eq, FShow);         
typedef enum {IDEAL2, MEM_FUNC1, MEM_FUNC2} MemState deriving (Bits, Eq, FShow);         

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
   PositCore_IFC pos <- mkPositCore(2);      	      //instantiate positcore 	
	
   FIFO #(Wrapper_in_req) ff_ROCCReq <- mkFIFO;       //FIFO to receive data from flute
   FIFO #(Wrapper_in_res) ff_ROCCRsp <- mkFIFO;       //FIFO to send back data to flute   
   FIFO #(Mem_Req) ff_MemReq <- mkFIFO; 	      //FIFO to send memory request
   FIFO #(Mem_Rsp) ff_MemRsp <- mkFIFO;               //FIFO to receive memory response

   FIFO #(Bit#(PositWidth)) f_data0 <-mkSizedFIFO(8);  //FIFO for memory data ; size 8 is arbitrary ( can be lesser based on melodica pipeline constraint)
   FIFO #(Bit#(PositWidth)) f_data1 <-mkSizedFIFO(8);  //FIFO for memory data ; size 8 is arbitrary ( can be lesser based on melodica pipeline constraint)
   FIFO #(Bit#(PositWidth)) f_data2 <-mkSizedFIFO(8);  //FIFO for memory data ; size 8 is arbitrary ( can be lesser based on melodica pipeline constraint)
   FIFO #(Bit#(PositWidth)) f_data3 <-mkSizedFIFO(8);  //FIFO for memory data ; size 8 is arbitrary ( can be lesser based on melodica pipeline constraint)
 
   Vec_output o <- replicateM(mkRegU);		       //Vector to store the output from melodica for memory functions

   Reg #(AccelState) rg_state <- mkReg (ROCC_REQ);    // Accelerator top state vector
   Reg #(MemState) rg_memstate <- mkReg (IDEAL2);     // Sub FSM state for memory 
   Reg #(Bit#(PositWidth)) addr1 <- mkRegU;    	      // to store address of memory
   Reg #(Bit#(PositWidth)) addr2 <- mkRegU;    	      // to store 2nd address of memory
   Reg #(Bool) flag <- mkReg(True);                   // for pingpong between address1 and address2 of the memory request
   Reg #(Bool) flag2 <- mkReg(True);  		      // for pingpong between FIFOs to store posit received in memory response
   Reg #(Bool) flag3 <- mkReg(False);                 // condition for positcore response rule for memory function
   Reg #(Bit#(32)) w_cnt <- mkReg(0);	              // to store the word count for receiving data from memory
   Reg #(Bit#(32)) w_cnt_2 <- mkReg(0);	              // to store the word count for response from posit core for memory function
   Reg #(Bit#(32)) w_cnt_ori <- mkReg(0);	      // to store the word count (keep record of initial count)
   Reg #(Bit#(32)) w_cnt_3 <- mkReg(0);	              // to store the word count for sending memory data to the posit core
   Reg #(Bit#(1)) crg[2] <- mkCReg(2,1'b1);           //to store valid bit received from memory

   // =============================================================
   // BEHAVIOR
   
   Wrapper_in_req roccReq = ff_ROCCReq.first;     	//Read the struct from ROCC into PositAccel

// ================================================================
// function to send data to posit core

   function Action fa_reqToPositCore (PositCmds cmd);  //function to send data to posit core with argument as funct7 from flute
   return
        action
	  RoundMode round_mode = Rnd_Nearest_Even;  //rounding to nearest even: can be changed by flute but as of now its fixed in posit core
	  FloatU in1 = tagged P roccReq.data1;      //convert data to FloatU for positcore to use
      	  FloatU in2 = tagged P roccReq.data2;      //convert data to FloatU for positcore to use
              if(roccReq.rg_sel==3'b111 && roccReq.val_pro==1)begin     //address bits of custom instruction (as per ROCC) stating rs1,rs2,rd are of processor and val_pro (value bit from processor stating valid data)
                let acc_input = tuple4(in1, in2, round_mode, cmd);       //tuple for positcore
                pos.server_core.request.put(acc_input);                  //Send to positcore
		rg_state <= ROCC_RSP;                                    //change state only if val_pro is high
				    
            end 
        endaction;        
   endfunction

// ================================================================
//rule to read data sent by flute via ROCC into PositAccel

   rule rl_ROCCReq (rg_state == ROCC_REQ); 		      
      addr1 <= roccReq.data1;         		              //irrepective of mem function store the address to save a cycle if its actually mem func
      addr2 <= roccReq.data1 + 4*roccReq.data2;		      //As byte organized memory
      w_cnt_2 <= roccReq.data2;			     	      //irrepective of mem function, store the count to save a cycle if its actually mem func		
      w_cnt <= roccReq.data2;		       		      //irrepective of mem function, store the count to save a cycle if its actually mem func
      w_cnt_ori <= roccReq.data2;		       	      //irrepective of mem function, store the count reference to save a cycle if its actually mem func
      w_cnt_3 <= roccReq.data2;		       		      //irrepective of mem function, store the count to save a cycle if its actually mem func
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

// ================================================================
//rule to send load request to memory : crg corresponds to valid loaded data for previous address through port 1

   rule rl_ROCCMemReq (rg_state == ROCC_MEM_REQ);   
	if(crg[0]==1'b1) begin     					//send new request only if valid data is received : crg==1
				
	 if (flag==True) begin						//condition for request for address 1
	  let mem_req = Mem_Req {addr1:addr1, load_store: 1'b0, vdata_store:0};     //send address, load signal and data to be stored (here not needed)
	  addr1<= addr1 + (32/4);   		//updating address to load new word assuming byte organized memory (PositWidth in place of 32; but it gave error)
	  ff_MemReq.enq(mem_req);		//send memory load request
          flag<=False;    			//change the flag to ping pong to address 2 for next load
	  $display("%d address 1 request sent", cur_cycle);        
   	 end
		

	if (flag==False) begin							   //condition for request for address 2
	 let mem_req = Mem_Req {addr1:addr2, load_store: 1'b0, vdata_store:0};     //send address, load signal and data to be stored (here not needed)
   	 addr2<= addr2 + (32/4);    		//updating address to load new word assuming byte organized memory (PositWidth in place of 32; but it gave error)
 	 ff_MemReq.enq(mem_req);  		//send memory load request from 2nd address
	 flag<=True;  				//change flag to ping pong to address 1
	 $display("%d address 2 request sent", cur_cycle);    
   	end
	
       end
   endrule

// ================================================================
// rule to receive loaded data from memory 

  rule rl_ROCCMemRsp (rg_state == ROCC_MEM_REQ);         
        Mem_Rsp mem_rsp = ff_MemRsp.first; ff_MemRsp.deq;    //read memory response from FIFO
	if(mem_rsp.valid==1'b1) begin      		     //proceed only if valid data is loaded
	 if (w_cnt>=2) begin             	     	     //condition for enquing received data in FIFO to be sent to posit core
	 
	  if(flag2==True) begin				     //condition for receiving address 1 data
	   f_data0.enq(mem_rsp.vdata_load1[63:32]);          //FIFO to store A1 posit
	   f_data1.enq(mem_rsp.vdata_load1[31:0]);           //FIFO to store A2 posit
           $display("%d:data1 = %h,data2 = %h, count= %h",cur_cycle, mem_rsp.vdata_load1[63:32],mem_rsp.vdata_load1[31:0], w_cnt/2);
           flag2<=False;				     // change flag to receive address 2 data
	  end
		
	  if(flag2==False) begin			     //condition for receiving address 2 data
	   f_data2.enq(mem_rsp.vdata_load1[63:32]);          //FIFO to store B1 posit 
	   f_data3.enq(mem_rsp.vdata_load1[31:0]);           //FIFO to store B2 posit
           $display("%d:data3 = %h,data4 = %h, count= %h",cur_cycle, mem_rsp.vdata_load1[63:32],mem_rsp.vdata_load1[31:0], w_cnt/2);
	   if(w_cnt==w_cnt_ori)				    //only first time change state to MEM_FUNC1 from here
	    rg_memstate <= MEM_FUNC1; 
	   w_cnt <= w_cnt - 2;            		    // updating the wordcount left to be loaded
           flag2<=True;					    // change flag to receive address 1 data
          end
         
	 end
		
 	else   
	 rg_state <= IDEAL1;				  //Change FSM1 state to IDEAl once all data is loaded from memory
	
       end

       crg[0] <= mem_rsp.valid;           		 // valid bit in CREG through port 0
    endrule   

// ================================================================
// rule to send A1-B1, A3-B3... odd pairs to posit core
 
  rule mem_func1 (rg_memstate == MEM_FUNC1);
	RoundMode round_mode = Rnd_Nearest_Even;     //rounding to nearest even: can be changed by flute but as of now its fixed in posit core
	FloatU in1 = tagged P f_data0.first;         //convert data A1 to FloatU for positcore to use
      	FloatU in2 = tagged P f_data2.first;         //convert data B1 to FloatU for positcore to use
	if(roccReq.rg_sel==3'b111 && roccReq.val_pro==1)begin   //address bits of custom instruction (as per ROCC) stating rs1,rs2,rd are of processor and val_pro (value bit from processor stating valid data)
          let acc_input_mem = tuple4(in1, in2, round_mode, FMA_P);       //tuple for positcore
          pos.server_core.request.put(acc_input_mem);                    //Send to positcore
	  rg_memstate <= MEM_FUNC2;                                      //change state for next posit pair only if val_pro is high         
	  f_data0.deq;							 	
	  f_data2.deq;
	  w_cnt_3<=w_cnt_3-1; 						//to keep count of posit pairs sent 
	  flag3 <= True;						//enable rule to receive response from melodica for memory data
	  $display("%d posit pair (odd numbered) sent to melodica", cur_cycle);
       end
				    
  	
  endrule

// ================================================================
// rule to send A2-B2, A4-B4... even pairs to posit core
 
  rule mem_func2 (rg_memstate == MEM_FUNC2);
	RoundMode round_mode = Rnd_Nearest_Even;  //rounding to nearest even: can be changed by flute but as of now its fixed in posit core
	FloatU in1 = tagged P f_data1.first;      //convert data A2 to FloatU for positcore to use
	FloatU in2 = tagged P f_data3.first;      //convert data B2 to FloatU for positcore to use
	if(roccReq.rg_sel==3'b111 && roccReq.val_pro==1)begin   //address bits of custom instruction (as per ROCC) stating rs1,rs2,rd are of processor and val_pro (value bit from processor stating valid data)
                let acc_input_mem = tuple4(in1, in2, round_mode, FMA_P);       //tuple for positcore
                pos.server_core.request.put(acc_input_mem);                    //Send to positcore
		f_data1.deq;	
		f_data3.deq; 
		w_cnt_3<=w_cnt_3-1;					       //to keep count of posit pairs sent
		if (w_cnt_3==0) 					       //if all posit pairs are sent, change to ideal state of FSM2
		   rg_memstate <= IDEAL2;
		
		else							       //else change state for next posit pair
		    rg_memstate <= MEM_FUNC1;
		$display("%d posit pair (even numbered) sent to melodica", cur_cycle);		
	      end				    
  		
  endrule

// ================================================================
// rule to receive melodica response for memory function

  rule posit_memRsp (flag3==True);
     let acc_output <- pos.server_core.response.get();       //Get response from positcore

	if (w_cnt_2>=1)  begin            		     //condition for making vectors of output
	  $display("%d %d output received from melodica", cur_cycle, w_cnt_2);
	  o[w_cnt_ori-w_cnt_2] <= tpl_3(acc_output);         //first vector holds 1st posit of 32 bits  (as of now)
	  w_cnt_2 <= w_cnt_2 - 1; 			     //decrement the count
	end 

	if(w_cnt_2 == 1) begin       			   //actual condition should be w_cnt_2==0 but since after 10th output this rule won't execute as no data will be received from positcore
	 $display("1: %h, 2: %h, 3: %h, 4: %h, 5: %h, 6: %h, 7: %h, 8: %h, 9: %h, 10: %h", o[0],o[1],o[2],o[3],o[4],o[5],o[6],o[7],o[8],o[9]);
	 ff_ROCCReq.deq;				   // deq rocc request to prevent use of ready bit
         rg_state <= ROCC_REQ;				   // change state of FSM1 from ideal to receive new ROCC request
	 flag3<= False; 				   // Disable this rule	
	 $finish; 					   //finish
	end
  endrule

// ================================================================
// rule to receive melodica response for non-memory functions and send data to flute

   rule rl_ROCCRsp (rg_state == ROCC_RSP);         
      let acc_output <- pos.server_core.response.get();	    //get response from positcore
      let r_destination = ff_ROCCReq.first.reg_d;           //to read destination register 
      let data_out = Wrapper_in_res {result_melodica:tpl_1(acc_output), exception:tpl_2(acc_output), quire:tpl_3(acc_output), reg_d:r_destination,  val_acc:1'b1};       // struct to be sent to flute
      ff_ROCCRsp.enq(data_out);      			   //enq in FIFO of server to send ROCC data
      ff_ROCCReq.deq;					   // deq rocc request here to prevent use of ready bit	
      rg_state <= ROCC_REQ;				   // change state of FSM1 from ideal to receive new ROCC request
   endrule

   // =============================================================
   // INTERFACE

   interface Server serverCPU = toGPServer(ff_ROCCReq, ff_ROCCRsp);            //server connection with flute to receive data from flute
   interface Client clientMEM = toGPClient(ff_MemReq, ff_MemRsp);	      //client conection with memory
endmodule

// ================================================================

endpackage
