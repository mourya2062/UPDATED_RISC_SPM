module Multiplexer_3ch (mux_out, data_a, data_b, data_c, sel);
  parameter 	word_size = 8;
  output 		[word_size-1: 0]	 mux_out;
  input 		[word_size-1: 0] 	data_a, data_b, data_c;
  input 		[1: 0] sel;

  assign  mux_out = (sel == 0) ? data_a: (sel == 1) ? data_b : (sel == 2) ? data_c: 'bx;
  
endmodule 