package Normalizer_IFCP;

import GetPut       :: *;
import ClientServer :: *;
import Pipeline_reg_N :: *;

interface Normalizer_IFC;
   interface Server #(Input_value_n,Output_posit_n) inoutifc;
endinterface

endpackage: Normalizer_IFCP
