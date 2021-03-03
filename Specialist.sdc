derive_pll_clocks
derive_clock_uncertainty;

set_multicycle_path -to {emu|cpu|*} -setup 2
set_multicycle_path -to {emu|cpu|*} -hold 1
