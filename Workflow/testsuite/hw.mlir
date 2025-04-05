hw.module @MyMod(%a: i1, %b: i1) -> (%c: i1) {
  %0 = comb.and %a, %b : i1
  hw.output %0 : i1
}
