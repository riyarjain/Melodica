# Open-source Parameterized Posit Arithmetic Unit

Melodica is a parameterized posit arithmetic unit which supports
accumulating posit operations into a quire. The operations
supported are multiply add and subtract, and divide add and
subtract.

More details about the hardware architecture of Melodica are
available [here](https://arxiv.org/abs/2006.00364) and at
`Documents/Melodica-Thesis`.

## Getting Started
### SoftPosit Submodule
This repository uses SoftPosit as a submodule. Please run before
proceeding:
```
    git submodule update --init --recursive
```

In order to engage the correct wrapper functions over SoftPosit
calls to check Melodica's results, the correct posit size
defintion flag needs to be passed to the Makefile while building
Melodica. Use the following argument depending on posit-width in
the make command:
```
   POSIT_SIZE=8/16/32
```

### Posit Type-definition
The BSV source in Melodica depends on a type definition file to
implement the parameterized posit logic. This type fils is
generated using the python script `src_bsv/lib/Gen_Posit_Numeric_Types`.

Depending on the desired posit-width and exponent-size
configuration, run the following command in the `src_bsv/lib`
directory:
```
   ./Gen_Posit_Numeric_Types --posit-width [width] --exp-width [exp-size] --float-width 32
```

## Building Instructions
Individual Melodica pipelines can be built independently for
analysis and experimentation. The module `src_bsv/Posit_Core.bsv`
is an example of a posit arithmetic unit assembled comprising of
multiple pipelines.  

To build all the pipelines:
```
   make POSIT_SIZE=[8/16/32]
```

The generated RTL is in the `VerilogCode` directories.
