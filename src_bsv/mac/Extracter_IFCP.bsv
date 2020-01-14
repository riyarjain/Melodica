package Extracter_IFCP;

import GetPut       :: *;
import ClientServer :: *;
import Pipeline_reg :: *;

interface Extracter_IFC;
   interface Server #(Input_posit,Output_posit) inoutifc;
endinterface

endpackage: Extracter_IFCP
