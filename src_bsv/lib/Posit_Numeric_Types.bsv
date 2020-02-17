// Copyright (c) HPC Lab, Department of Electrical Engineering, IIT Bombay
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
package Posit_Numeric_Types;

// ================================================================
// Basic sizes, from which everything else is derived

// PositWidth        = 32    (= 0x20)    (bits in posit number)
// ExpWidth          =  2    (= 0x02)    (width of exponent field)
// FloatWidth          = 32    (= 0x20)    (width of exponent field)

// ================================================================
// Type decls

// Posit Fields ---------------

typedef        32   PositWidth                    ;    // (basic)
typedef         2   ExpWidth                      ;    // (basic)
typedef        32   FloatWidth                    ;    // (basic)
typedef         8   FloatExpWidth                 ;    // Exponent width of single precision float
typedef        23   FloatFracWidth                ;    // Fraction width of single precision float
typedef       127   FloatBias                     ;    // Bais for single precision float
typedef        31   PositWidthMinus1              ;    // PositWidth - 1
typedef        29   PositWidthMinus3              ;    // PositWidth - 3
typedef         5   BitsPerPositWidth             ;    // log2 (PositWidth)
typedef         5   Iteration                     ;    // log2 (PositWidth-1)
typedef         6   RegimeWidth                   ;    // log2 (PositWidth) + 1

typedef         4   MaxExpValue                   ;    // 2 ^ ExpWidth
typedef         1   BitsPerExpWidth               ;    // log2 (ExpWidth)

typedef        27   FracWidth                     ;    // PositWidth-3-ExpWidth

typedef         7   ScaleWidth                    ;    // log2((PositWidth-1)*(2^ExpWidth)-1)
typedef         8   ScaleWidthPlus1               ;    // ScaleWidth + 1
typedef         5   ScaleWidthMinusExpWidth       ;    // ScaleWidth - ExpWidth
typedef         6   ScaleWidthMinusExpWidthPlus1  ;    // ScaleWidth - ExpWidth


/*// ================================================================
// Utility functions

function  Bit#(1)  fnSign (Bit #(n)  posit);
   return  posit [(valueOf (n) - 1)];
endfunction

function  Bit#(n)  fnUnsignedPosit (Bit #(n)  posit);
   return  extend (posit [(valueOf (n) - 1):0]);
endfunction

// ================================================================*/

endpackage: Posit_Numeric_Types
