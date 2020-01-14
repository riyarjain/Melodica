package Adder_IFCP;

import GetPut       :: *;
import ClientServer :: *;
import Pipeline_reg_A :: *;

interface Adder_IFC ;
   interface Server #(Inputs_a,Outputs_a) inoutifc;
endinterface

endpackage: Adder_IFCP
