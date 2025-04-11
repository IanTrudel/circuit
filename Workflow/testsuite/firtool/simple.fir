FIRRTL version 2.0.0

circuit Adder :
  module Adder :
    input a : UInt<8>
    input b : UInt<8>
    output c : UInt<8>
    c <= add(a, b)

