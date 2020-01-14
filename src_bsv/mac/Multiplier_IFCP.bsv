package Multiplier_IFCP;

import GetPut       :: *;
import ClientServer :: *;
import Pipeline_reg_M :: *;

interface Multiplier_IFC;
   interface Server #(Inputs_m,Outputs_m) inoutifc;
endinterface

endpackage: Multiplier_IFCP
