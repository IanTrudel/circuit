FIRRTL version 2.0.0

circuit Foo :
  module Foo :
    input x : UInt<1>
    input y : UInt<1>
    output z : UInt<1>
    z <= and(x, y)

