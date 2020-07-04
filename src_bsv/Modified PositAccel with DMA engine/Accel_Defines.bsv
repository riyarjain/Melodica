package Accel_Defines;

// ================================================================
// BSV Library imports

import GetPut :: *;
import ClientServer :: *;

// ================================================================
// Project imports
import PositCore::*;
import Posit_Numeric_Types :: *;
import FloatingPoint :: *;
import Utils :: *;
import Posit_User_Types :: *;

// ================================================================
// Type Definations for struct
typedef Bit#(64) Mdata;            //data to be fetched from memory
typedef Bit#(PositWidth) Data;     //operands from flute register
typedef Bit#(3) Reg_sel;   //Part of custom instruction to select whether register adderss is of flute or accelerator
typedef Bit#(7) Op;        //opcode
typedef Bit#(1) Value;     //value bit of ROCC
typedef Bit#(5) Rdst;      //destination reg
typedef PositCore::FloatU Result;        //output from melodica
typedef FloatingPoint::Exception Ex;     //exception
typedef Bit#(QuireWidth) Quire;          //Quire output (rg_quire)
typedef Bit#(1) LS;			 //to determine whether its load aur store for memory

typedef struct {
   Data data1;
   Data data2;
   Reg_sel rg_sel;
   Rdst reg_d;
   Op opcode;
   Value val_pro;		
}Wrapper_in_req deriving(Bits);  //struct for flute to wrapper


typedef struct {
   Result result_melodica;
   Ex exception;
   Quire quire;	
   Rdst reg_d;
   Value val_acc;
}Wrapper_in_res deriving(Bits);  //struct for wrapper to flute


typedef struct {
   Data addr1;
   LS load_store;
   Data vdata_store;
}Mem_Req deriving(Bits);


typedef struct {
   Mdata vdata_load1;
   Bit#(1) valid;
}Mem_Rsp deriving(Bits);

 
// ================================================================
//function bits definition
Bit #(7) f7_fma_p = 7'h0;
Bit #(7) f7_fda_p = 7'h1;
Bit #(7) f7_fms_p = 7'h2;
Bit #(7) f7_fds_p = 7'h3;
Bit #(7) f7_fcvt_p_s = 7'h4;
Bit #(7) f7_fcvt_s_p = 7'h5;
Bit #(7) f7_fcvt_p_r = 7'h6;
Bit #(7) f7_fcvt_r_p = 7'h7;
Bit #(7) f7_mem = 7'h8;


// ================================================================
endpackage
