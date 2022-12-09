module Program_Counter (count, data_in, Load_PC, Inc_PC, clk, rst);
  parameter word_size = 8;
  output [word_size-1: 0] 	count					;
  input 	[word_size-1: 0] 	data_in				;
  input 							Load_PC, Inc_PC	;
  input 							clk, rst				;
  reg 	[word_size-1: 0]	count					;
  
  always @ (posedge clk or negedge rst)
    if (rst == 0) 
		count <= 0; 
	else if (Load_PC) 
		count <= data_in; 
	else if  (Inc_PC) 
		count <= count +1;
	 
endmodule 