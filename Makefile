# Melodica Makefile
#
# --------
# Mandatory command-line argument -- use to fix posit size
POSIT_SIZE ?= 32
# --------
#  Common compilation flags
BSC_COMPILATION_FLAGS = -keep-fires -aggressive-conditions

# Melodica-specific compilation flags
# Select P8 for 8-bit posits, P16 for 16-bit and P32 for 32-bit
BSC_COMPILATION_FLAGS += \
		 -D RANDOM \
		 -D P$(POSIT_SIZE)
OBJ = .o

TOPMOD = mkTestbench
PNE_TOPMOD = mkPNE_test

BLUESPEC_LIB = %/Prelude:%/Libraries:%/Libraries/BlueNoC


CXXFAMILY=$(shell $(BLUESPECDIR)/bin/bsenv c++_family)


# Change me -- Where are the DISTRO objects
DISTRO ?= ./
SOFTPOSIT_OBJPATH = $(DISTRO)SoftPosit/build/Linux-x86_64-GCC

BSC_CFLAGS = \
		-Xc -lm\
		-Xc -I$(DISTRO)SoftPosit/source/include \
		-Xc++ -D_GLIBCXX_USE_CXX11_ABI=0

SOFTPOSIT_OBJS = \
$(SOFTPOSIT_OBJPATH)/s_addMagsP8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_subMagsP8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_mulAddP8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_mul$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_div$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_sqrt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_i32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_i64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_ui32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_to_ui64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_roundToInt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_mulAdd$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_eq$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_le$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p8_lt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire8_fdp_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire8_fdp_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui32_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui64_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i32_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i64_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_addMagsP16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_subMagsP16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_mulAddP16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_ui32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_ui64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_i32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_i64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_roundToInt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_mul$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_mulAdd$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_div$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_eq$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_le$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_lt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p16_sqrt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire16_fdp_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire16_fdp_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire_helper$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui32_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui64_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i32_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i64_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_addMagsP32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_subMagsP32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_mulAddP32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_ui32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_ui64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_i32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_i64$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_p8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_p16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_roundToInt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_mul$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_mulAdd$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_div$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_eq$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_le$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_lt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/p32_sqrt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire32_fdp_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/quire32_fdp_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui32_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui64_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i32_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i64_to_p32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_approxRecipSqrt_1Ks$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertDecToPosit8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertPosit8ToDec$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertDecToPosit16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertPosit16ToDec$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertQuire8ToPosit8$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertQuire16ToPosit16$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertQuire32ToPosit32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertDecToPosit32$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertPosit32ToDec$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_int$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_addMagsPX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_subMagsPX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/s_mulAddPX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_add$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_sub$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_mul$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_div$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_mulAdd$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_roundToInt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_sqrt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_eq$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_le$(OBJ) \
$(SOFTPOSIT_OBJPATH)/pX2_lt$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui32_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/ui64_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i32_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/i64_to_pX2$(OBJ) \
$(SOFTPOSIT_OBJPATH)/c_convertQuireX2ToPositX2$(OBJ) 
 

# From bluespec installation
BSIM_INCDIR=$(BLUESPECDIR)/Bluesim
BSIM_LIBDIR=$(BSIM_INCDIR)/$(CXXFAMILY)
Testbench_Path = src_bsv/tb

# ---------------
#  PATH and Variable settings for individual pipelines
#ADDER------------
ADDER_PATH = .:src_bsv/Adder:src_bsv/lib:src_bsv/common:$(Testbench_Path):$(BLUESPEC_LIB) 
BUILD_DIR_ADDER=builds/Adder
BUILD_BSIM_DIR_ADDER=builds/Adder
BSC_BUILDDIR_ADDER=-simdir $(BUILD_BSIM_DIR_ADDER) -bdir $(BUILD_DIR_ADDER) -info-dir $(BUILD_DIR_ADDER)
VERILOG_CODE_DIR_ADDER=Verilog_RTL/Adder
OUTPUT_ADDER = builds/Adder/output

#MULTIPLIER------------
MULTIPLIER_PATH = .:$(BLUESPEC_LIB):src_bsv/Multiplier:src_bsv/lib:src_bsv/common:$(Testbench_Path)  
BUILD_DIR_MULTIPLIER=builds/Multiplier
BUILD_BSIM_DIR_MULTIPLIER=builds/Multiplier
BSC_BUILDDIR_MULTIPLIER=-simdir $(BUILD_BSIM_DIR_MULTIPLIER) -bdir $(BUILD_DIR_MULTIPLIER) -info-dir $(BUILD_DIR_MULTIPLIER)
VERILOG_CODE_DIR_MULTIPLIER=Verilog_RTL/Multiplier
OUTPUT_MULTIPLIER = builds/Multiplier/output

#DIVIDER------------
DIVIDER_PATH = .:$(BLUESPEC_LIB):src_bsv/Divider:src_bsv/lib:src_bsv/common:$(Testbench_Path)  
BUILD_DIR_DIVIDER=builds/Divider
BUILD_BSIM_DIR_DIVIDER=builds/Divider
BSC_BUILDDIR_DIVIDER=-simdir $(BUILD_BSIM_DIR_DIVIDER) -bdir $(BUILD_DIR_DIVIDER) -info-dir $(BUILD_DIR_DIVIDER)
VERILOG_CODE_DIR_DIVIDER=Verilog_RTL/Divider
OUTPUT_DIVIDER = builds/Divider/output

#MAC------------
MAC_PATH = .:$(BLUESPEC_LIB):src_bsv/Mac:src_bsv/lib:src_bsv/common:$(Testbench_Path)  
BUILD_DIR_MAC=builds/Mac
BUILD_BSIM_DIR_MAC=builds/Mac
BSC_BUILDDIR_MAC=-simdir $(BUILD_BSIM_DIR_MAC) -bdir $(BUILD_DIR_MAC) -info-dir $(BUILD_DIR_MAC)
VERILOG_CODE_DIR_MAC=Verilog_RTL/Mac
OUTPUT_MAC = builds/Mac/output

#FMA------------
FMA_PATH = .:$(BLUESPEC_LIB):src_bsv/Fused_Op:src_bsv/lib:src_bsv/common:$(Testbench_Path)  
BUILD_DIR_FMA=builds/Fused_Op/fma
BUILD_BSIM_DIR_FMA=builds/Fused_Op/fma
BSC_BUILDDIR_FMA=-simdir $(BUILD_BSIM_DIR_FMA) -bdir $(BUILD_DIR_FMA) -info-dir $(BUILD_DIR_FMA)
VERILOG_CODE_DIR_FMA=Verilog_RTL/Fused_Op/fma
OUTPUT_FMA = builds/Fused_Op/fma/output

#FDA------------
FDA_PATH = .:$(BLUESPEC_LIB):src_bsv/Fused_Op:src_bsv/lib:src_bsv/common:$(Testbench_Path)  
BUILD_DIR_FDA=builds/Fused_Op/fda
BUILD_BSIM_DIR_FDA=builds/Fused_Op/fda
BSC_BUILDDIR_FDA=-simdir $(BUILD_BSIM_DIR_FDA) -bdir $(BUILD_DIR_FDA) -info-dir $(BUILD_DIR_FDA)
VERILOG_CODE_DIR_FDA=Verilog_RTL/Fused_Op/fda
OUTPUT_FDA = builds/Fused_Op/fda/output

#QtoP------------
QtoP_PATH = .:$(BLUESPEC_LIB):src_bsv/QtoP:src_bsv/lib:src_bsv/common:$(Testbench_Path) 
BUILD_DIR_QtoP=builds/QtoP
BUILD_BSIM_DIR_QtoP=builds/QtoP
BSC_BUILDDIR_QtoP=-simdir $(BUILD_BSIM_DIR_QtoP) -bdir $(BUILD_DIR_QtoP) -info-dir $(BUILD_DIR_QtoP)
VERILOG_CODE_DIR_QtoP=Verilog_RTL/QtoP
OUTPUT_QtoP = builds/QtoP/output

#PtoQ------------
PtoQ_PATH = .:$(BLUESPEC_LIB):src_bsv/PtoQ:src_bsv/lib:src_bsv/common:$(Testbench_Path) 
BUILD_DIR_PtoQ=builds/PtoQ
BUILD_BSIM_DIR_PtoQ=builds/PtoQ
BSC_BUILDDIR_PtoQ=-simdir $(BUILD_BSIM_DIR_PtoQ) -bdir $(BUILD_DIR_PtoQ) -info-dir $(BUILD_DIR_PtoQ)
VERILOG_CODE_DIR_PtoQ=Verilog_RTL/PtoQ
OUTPUT_PtoQ = builds/PtoQ/output

#FtoP------------
FtoP_PATH = .:$(BLUESPEC_LIB):src_bsv/FtoP:src_bsv/lib:src_bsv/common:$(Testbench_Path) 
BUILD_DIR_FtoP=builds/FtoP
BUILD_BSIM_DIR_FtoP=builds/FtoP
BSC_BUILDDIR_FtoP=-simdir $(BUILD_BSIM_DIR_FtoP) -bdir $(BUILD_DIR_FtoP) -info-dir $(BUILD_DIR_FtoP)
VERILOG_CODE_DIR_FtoP=Verilog_RTL/FtoP
OUTPUT_FtoP = builds/FtoP/output

#PtoF------------
PtoF_PATH = .:$(BLUESPEC_LIB):src_bsv/PtoF:src_bsv/lib:src_bsv/common:$(Testbench_Path) 
BUILD_DIR_PtoF=builds/PtoF
BUILD_BSIM_DIR_PtoF=builds/PtoF
BSC_BUILDDIR_PtoF=-simdir $(BUILD_BSIM_DIR_PtoF) -bdir $(BUILD_DIR_PtoF) -info-dir $(BUILD_DIR_PtoF)
VERILOG_CODE_DIR_PtoF=Verilog_RTL/PtoF
OUTPUT_PtoF = builds/PtoF/output
# ---------------

# For final C++ link with main.cxx driver for non-BlueTcl version
# (needed for SoftPosits)
CPP_FLAGS += \
	-static \
	-D_GLIBCXX_USE_CXX11_ABI=0 \
        -DNEW_MODEL_MKFOO=new_MODEL_$(TOPMOD) \
        -DMODEL_MKFOO_H=\"model_$(TOPMOD).h\" \
	-I$(BSIM_INCDIR) \
	-L$(BSIM_LIBDIR) \
	-L$(SOFTPOSIT_OBJPATH) \
	-O3 \

# -------------------------------------------------------------------------------------
# Compilation Targets -- Here starts the real work
default: rtl sim

# --------
# Working Directories
# --------
.PHONY: adder_working_dirs
adder_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_ADDER) $(BUILD_DIR_ADDER) $(BUILD_BSIM_DIR_ADDER) $(OUTPUT_ADDER)

.PHONY: multiplier_working_dirs
multiplier_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_MULTIPLIER) $(BUILD_DIR_MULTIPLIER) $(BUILD_BSIM_DIR_MULTIPLIER) $(OUTPUT_MULTIPLIER)

.PHONY: divider_working_dirs
divider_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_DIVIDER) $(BUILD_DIR_DIVIDER) $(BUILD_BSIM_DIR_DIVIDER) $(OUTPUT_DIVIDER)

.PHONY: fma_working_dirs
fma_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_FMA) $(BUILD_DIR_FMA) $(BUILD_BSIM_DIR_FMA) $(OUTPUT_FMA)

.PHONY: fda_working_dirs
fda_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_FDA) $(BUILD_DIR_FDA) $(BUILD_BSIM_DIR_FDA) $(OUTPUT_FDA)

.PHONY: ftop_working_dirs
ftop_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_FtoP) $(BUILD_DIR_FtoP) $(BUILD_BSIM_DIR_FtoP) $(OUTPUT_FtoP)

.PHONY: ptof_working_dirs
ptof_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_PtoF) $(BUILD_DIR_PtoF) $(BUILD_BSIM_DIR_PtoF) $(OUTPUT_PtoF)

.PHONY: ptoq_working_dirs
ptoq_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_PtoQ) $(BUILD_DIR_PtoQ) $(BUILD_BSIM_DIR_PtoQ) $(OUTPUT_PtoQ)

.PHONY: qtop_working_dirs
qtop_working_dirs :
	mkdir -p $(VERILOG_CODE_DIR_QtoP) $(BUILD_DIR_QtoP) $(BUILD_BSIM_DIR_QtoP) $(OUTPUT_QtoP)

# --------
# RTL Generation
# --------
.PHONY: rtl
rtl: rtl_adder rtl_multiplier rtl_divider rtl_fma rtl_fda rtl_qtop rtl_ptoq rtl_ftop rtl_ptof
	@echo "Generating Melodica RTL ..."

.PHONY: rtl_adder 
rtl_adder : adder_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_ADDER) -vdir $(VERILOG_CODE_DIR_ADDER) $(BSC_COMPILATION_FLAGS) -p $(ADDER_PATH) -g $(PNE_TOPMOD) src_bsv/Adder/PNE.bsv
.PHONY: rtl_multiplier 
rtl_multiplier : multiplier_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_MULTIPLIER) -vdir $(VERILOG_CODE_DIR_MULTIPLIER) $(BSC_COMPILATION_FLAGS) -p $(MULTIPLIER_PATH) -g $(PNE_TOPMOD) src_bsv/Multiplier/PNE.bsv
.PHONY: rtl_divider 
rtl_divider : divider_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_DIVIDER) -vdir $(VERILOG_CODE_DIR_DIVIDER) $(BSC_COMPILATION_FLAGS) -p $(DIVIDER_PATH) -g $(PNE_TOPMOD) src_bsv/Divider/PNE.bsv
.PHONY: rtl_fma 
rtl_fma : fma_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_FMA) -vdir $(VERILOG_CODE_DIR_FMA) $(BSC_COMPILATION_FLAGS) -p $(FMA_PATH) -g $(PNE_TOPMOD) src_bsv/Fused_Op/FMA_PNE_Quire.bsv
.PHONY: rtl_fda 
rtl_fda : fda_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_FDA) -vdir $(VERILOG_CODE_DIR_FDA) $(BSC_COMPILATION_FLAGS) -p $(FDA_PATH) -g $(PNE_TOPMOD) src_bsv/Fused_Op/FDA_PNE_Quire.bsv
.PHONY: rtl_qtop 
rtl_qtop : qtop_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_QtoP) -vdir $(VERILOG_CODE_DIR_QtoP) $(BSC_COMPILATION_FLAGS) -p $(QtoP_PATH) -g $(PNE_TOPMOD) src_bsv/QtoP/PNE.bsv
.PHONY: rtl_ptoq 
rtl_ptoq : ptoq_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_PtoQ) -vdir $(VERILOG_CODE_DIR_PtoQ) $(BSC_COMPILATION_FLAGS) -p $(PtoQ_PATH) -g $(PNE_TOPMOD) src_bsv/PtoQ/PNE.bsv
.PHONY: rtl_ftop 
rtl_ftop : ftop_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_FtoP) -vdir $(VERILOG_CODE_DIR_FtoP) $(BSC_COMPILATION_FLAGS) -p $(FtoP_PATH) -g $(PNE_TOPMOD) src_bsv/FtoP/PNE.bsv
.PHONY: rtl_ptof
rtl_ptof: ptof_working_dirs
	bsc -u -elab -verilog $(BSC_BUILDDIR_PtoF) -vdir $(VERILOG_CODE_DIR_PtoF) $(BSC_COMPILATION_FLAGS) -p $(PtoF_PATH) -g $(PNE_TOPMOD) src_bsv/PtoF/PNE.bsv


# --------
# Building a (bsim) simulator
# --------
sim:  sim_adder sim_multiplier sim_divider sim_mac sim_fma sim_fda sim_qtop sim_ptoq sim_ftop sim_ptof
	@echo "Generating Melodica simulator ..."

link: link_adder link_multiplier link_divider link_mac link_fma link_fda link_qtop link_ptoq link_ftop link_ptof

.PHONY: sim_adder
sim_adder: bsim_adder link_adder_d

.PHONY: bsim_adder
bsim_adder: adder_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_ADDER) $(BSC_COMPILATION_FLAGS) -p $(ADDER_PATH) -g $(TOPMOD) $(Testbench_Path)/Add_Tb.bsv 

#MULTIPLIER
.PHONY: sim_multiplier
sim_multiplier: bsim_multiplier link_multiplier_d

.PHONY: bsim_multiplier
bsim_multiplier: multiplier_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_MULTIPLIER) $(BSC_COMPILATION_FLAGS) -p $(MULTIPLIER_PATH) -g $(TOPMOD) $(Testbench_Path)/Mul_Tb.bsv 

#DIVIDER
.PHONY: sim_divider
sim_divider: bsim_divider link_divider_d

.PHONY: bsim_divider
bsim_divider: divider_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_DIVIDER) $(BSC_COMPILATION_FLAGS) -p $(DIVIDER_PATH) -g $(TOPMOD) $(Testbench_Path)/Div_Tb.bsv 

#FMA
.PHONY: sim_fma
sim_fma: bsim_fma link_fma_d

.PHONY: bsim_fma
bsim_fma: fma_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_FMA) $(BSC_COMPILATION_FLAGS) -p $(FMA_PATH) -g $(TOPMOD) $(Testbench_Path)/Fma_Tb.bsv 

#FDA
.PHONY: sim_fda
sim_fda: bsim_fda link_fda_d

.PHONY: bsim_fda
bsim_fda: fda_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_FDA) $(BSC_COMPILATION_FLAGS) -p $(FDA_PATH) -g $(TOPMOD) $(Testbench_Path)/Fda_Tb.bsv 

#QtoP
.PHONY: sim_qtop
sim_qtop: bsim_qtop link_qtop_d

.PHONY: bsim_qtop
bsim_qtop: qtop_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_QtoP) $(BSC_COMPILATION_FLAGS) -p $(QtoP_PATH) -g $(TOPMOD) $(Testbench_Path)/QtoP_Tb.bsv 

#PtoQ
.PHONY: sim_ptoq
sim_ptoq: bsim_ptoq link_ptoq_d

.PHONY: bsim_ptoq
bsim_ptoq: ptoq_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_PtoQ) $(BSC_COMPILATION_FLAGS) -p $(PtoQ_PATH) -g $(TOPMOD) $(Testbench_Path)/PtoQ_Tb.bsv 

#FtoP
.PHONY: sim_ftop
sim_ftop: bsim_ftop link_ftop_d

.PHONY: bsim_ftop
bsim_ftop: ftopworking_dirs
	bsc -u -sim $(BSC_BUILDDIR_FtoP) $(BSC_COMPILATION_FLAGS) -p $(FtoP_PATH) -g $(TOPMOD) $(Testbench_Path)/FtoP_Tb.bsv 

#PtoF
.PHONY: sim_ptof
sim_ptof: bsim_ptof link_ptof_d

.PHONY: bsim_ptof
bsim_ptof: ptof_working_dirs
	bsc -u -sim $(BSC_BUILDDIR_PtoF) $(BSC_COMPILATION_FLAGS) -p $(PtoF_PATH) -g $(TOPMOD) $(Testbench_Path)/PtoF_Tb.bsv 

#LINK----------------------------------------------------------------------------------------------
#ADDER
.PHONY: link_adder
link_adder:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_ADDER)/out -simdir $(BUILD_DIR_ADDER) -p $(ADDER_PATH) -bdir $(BUILD_DIR_ADDER) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#MULTIPLIER
.PHONY: link_multiplier
link_multiplier:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_MULTIPLIER)/out -simdir $(BUILD_DIR_MULTIPLIER) -p $(MULTIPLIER_PATH) -bdir $(BUILD_DIR_MULTIPLIER) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#DIVIDER
.PHONY: link_divider
link_divider:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_DIVIDER)/out -simdir $(BUILD_DIR_DIVIDER) -p $(DIVIDER_PATH) -bdir $(BUILD_DIR_DIVIDER) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#MAC
.PHONY: link_mac
link_mac:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_MAC)/out -simdir $(BUILD_DIR_MAC) -p $(MAC_PATH) -bdir $(BUILD_DIR_MAC) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#FMA
.PHONY: link_fma
link_fma:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_FMA)/out -simdir $(BUILD_DIR_FMA) -p $(FMA_PATH) -bdir $(BUILD_DIR_FMA) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#FDA
.PHONY: link_fda
link_fda:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_FDA)/out -simdir $(BUILD_DIR_FDA) -p $(FDA_PATH) -bdir $(BUILD_DIR_FDA) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#QtoP
.PHONY: link_qtop
link_qtop:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_QtoP)/out -simdir $(BUILD_DIR_QtoP) -p $(QtoP_PATH) -bdir $(BUILD_DIR_QtoP) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c$(OBJS_OTHERS) 
	@echo Linking finished

#PtoQ
.PHONY: link_ptoq
link_ptoq:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_PtoQ)/out -simdir $(BUILD_DIR_PtoQ) -p $(PtoQ_PATH) -bdir $(BUILD_DIR_PtoQ) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#FtoP
.PHONY: link_ftop
link_ftop:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_FtoP)/out -simdir $(BUILD_DIR_FtoP) -p $(FtoP_PATH) -bdir $(BUILD_DIR_FtoP) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c$(OBJS_OTHERS) 
	@echo Linking finished

#PtoF
.PHONY: link_ptof
link_ptof:
	@echo Linking...
	bsc -e $(TOPMOD) -sim -o $(OUTPUT_PtoF)/out -simdir $(BUILD_DIR_PtoF) -p $(PtoF_PATH) -bdir $(BUILD_DIR_PtoF) -keep-fires -aggressive-conditions  $(BSC_CFLAGS) $(DISTRO)src_c/softposit_wrappers.c $(OBJS_OTHERS) 
	@echo Linking finished

#LINK_d------------------------------------------------------------------------------------------------
BLUESIM_MAIN_CXX = $(DISTRO)BSV_Additional_Libs/C++/bluesim_main.cxx

#ADDER
.PHONY: link_adder_d
link_adder_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_ADDER) \
		-o $(OUTPUT_ADDER)/out_adder \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_ADDER)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#MULTIPLIER
.PHONY: link_multiplier_d
link_multiplier_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_MULTIPLIER) \
		-o $(OUTPUT_MULTIPLIER)/out_multiplier \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_MULTIPLIER)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#DIVIDER
.PHONY: link_divider_d
link_divider_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_DIVIDER) \
		-o $(OUTPUT_DIVIDER)/out_divider \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_DIVIDER)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'


#MAC
.PHONY: link_mac_d
link_mac_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_MAC) \
		-o $(OUTPUT_MAC)/out_mac \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_MAC)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#FMA
.PHONY: link_fma_d
link_fma_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_FMA) \
		-o $(OUTPUT_FMA)/out_fma \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_FMA)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#FDA
.PHONY: link_fda_d
link_fda_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_FDA) \
		-o $(OUTPUT_FDA)/out_fda \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_FDA)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#QtoP
.PHONY: link_qtop_d
link_qtop_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_QtoP) \
		-o $(OUTPUT_QtoP)/out_qtop \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_QtoP)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#PtoQ
.PHONY: link_ptoq_d
link_ptoq_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_PtoQ) \
		-o $(OUTPUT_PtoQ)/out_ptoq \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_PtoQ)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#FtoP
.PHONY: link_ftop_d
link_ftop_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_FtoP) \
		-o $(OUTPUT_FtoP)/out_ftop \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_FtoP)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#PtoF
.PHONY: link_ptof_d
link_ptof_d:
	@echo 'Linking for distributable Bluesim (without Bluetcl driver)'
	c++ $(CPP_FLAGS) \
		-I$(BUILD_BSIM_DIR_PtoF) \
		-o $(OUTPUT_PtoF)/out_ptof \
		$(BLUESIM_MAIN_CXX) \
		$(BUILD_BSIM_DIR_PtoF)/*.o \
		$(SOFTPOSIT_OBJS) \
		$(DISTRO)src_c/softposit_wrappers.o \
		-static-libgcc \
		-static-libstdc++ \
		-lbskernel -lbsprim \
		-lpthread
	@echo 'Linking finished for distributable Bluesim (without Bluetcl driver)'

#SIMULATE---------------------------------------------------------------------------------------------
#ADDER
.PHONY: simulate_adder
simulate_adder:
	@echo Simulation...
	./$(OUTPUT_ADDER)/out_adder 
	@echo Simulation finished

#MULTIPLIER
.PHONY: simulate_multiplier
simulate_multiplier:
	@echo Simulation...
	./$(OUTPUT_MULTIPLIER)/out_multiplier 
	@echo Simulation finished

#DIVIDER
.PHONY: simulate_divider
simulate_divider:
	@echo Simulation...
	./$(OUTPUT_DIVIDER)/out_divider 
	@echo Simulation finished

#MAC
.PHONY: simulate_mac
simulate_mac:
	@echo Simulation...
	./$(OUTPUT_MAC)/out_mac 
	@echo Simulation finished

#FMA
.PHONY: simulate_fma
simulate_fma:
	@echo Simulation...
	./$(OUTPUT_FMA)/out_fma 
	@echo Simulation finished

#FDA
.PHONY: simulate_fda
simulate_fda:
	@echo Simulation...
	./$(OUTPUT_FDA)/out_fda 
	@echo Simulation finished

#Q-TO-P
.PHONY: simulate_qtop
simulate_qtop:
	@echo Simulation...
	./$(OUTPUT_QtoP)/out_qtop 
	@echo Simulation finished

#P-TO-Q
.PHONY: simulate_ptoq
simulate_ptoq:
	@echo Simulation...
	./$(OUTPUT_PtoQ)/out_ptoq 
	@echo Simulation finished

#Q-TO-P
.PHONY: simulate_ftop
simulate_ftop:
	@echo Simulation...
	./$(OUTPUT_FtoP)/out_ftop 
	@echo Simulation finished

#P-TO-Q
.PHONY: simulate_ptof
simulate_ptof:
	@echo Simulation...
	./$(OUTPUT_PtoF)/out_ptof 
	@echo Simulation finished


#CLEAN------------------------------------------------------------------------------------------------------------
.PHONY: full_clean
full_clean: clean_adder clean_multiplier clean_divider clean_mac clean_fma clean_fda clean_qtop clean_ptoq clean_ftop clean_ptof

#ADDER
.PHONY: clean_adder
clean_adder:
	rm -r ./builds/Adder ./Verilog_RTL/Adder

#MULTIPLIER
.PHONY: clean_multiplier
clean_multiplier:
	rm -r ./builds/Multiplier ./Verilog_RTL/Multiplier 

#DIVIDER
.PHONY: clean_divider
clean_divider:
	rm -r ./builds/Divider ./Verilog_RTL/Divider 

#MAC
.PHONY: clean_mac
clean_mac:
	rm -r ./builds/Mac ./Verilog_RTL/Mac 

#FMA
.PHONY: clean_fma
clean_fma:
	rm -r ./builds/Fused_Op/fma ./Verilog_RTL/Fused_Op/fma 

#FDA
.PHONY: clean_fda
clean_fda:
	rm -r ./builds/Fused_Op/fda ./Verilog_RTL/Fused_Op/fda 

#Q-TO-P
.PHONY: clean_qtop
clean_qtop:
	rm -r ./builds/QtoP ./Verilog_RTL/QtoP 

#P-to-Q
.PHONY: clean_ptoq
clean_ptoq:
	rm -r ./builds/PtoQ ./Verilog_RTL/PtoQ 

 
#F-TO-P
.PHONY: clean_ftop
clean_ftop:
	rm -r ./builds/FtoP ./Verilog_RTL/FtoP 

#P-to-Q
.PHONY: clean_ptof
clean_ptof:
	rm -r ./builds/PtoF ./Verilog_RTL/PtoF 
