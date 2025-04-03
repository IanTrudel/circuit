module {
  moore.module @Adder {
    %a = moore.input "a" : i1
    %b = moore.input "b" : i1
    %sum = moore.and %a, %b : i1
    moore.output %sum : i1
  }
}

