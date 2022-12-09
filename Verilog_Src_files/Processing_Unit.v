module Processing_Unit (instruction, Zflag,ovflag, mdflag,address, Bus_1, mem_word, Load_R0, Load_R1, Load_R2, 
  Load_R3, Load_PC, Inc_PC, Sel_Bus_1_Mux, Load_IR, Load_Add_R, Load_Reg_Y, Load_Reg_Z, Load_Reg_ov,Load_Reg_md,
  Sel_Bus_2_Mux, clk, rst);

  parameter word_size = 8;
  parameter op_size = 4;
  parameter Sel1_size = 3;
  parameter Sel2_size = 3;

  output [word_size-1: 0] 	instruction, address, Bus_1															;
  output 					mdflag																				;
  output 					ovflag																				;
  output 					Zflag																				;

  input [word_size-1: 0]  	mem_word																			;
  input 					Load_R0, Load_R1, Load_R2, Load_R3, Load_PC, Inc_PC									;
  input [Sel1_size-1: 0] 	Sel_Bus_1_Mux																		;
  input [Sel2_size-1: 0] 	Sel_Bus_2_Mux																		;
  input 					Load_IR, Load_Add_R, Load_Reg_Y, Load_Reg_Z	,Load_Reg_ov,Load_Reg_md				;
  input 					clk, rst																			;

  wire						Load_R0, Load_R1, Load_R2, Load_R3													;
  wire [word_size-1: 0] 	Bus_2																				;
  wire [word_size-1: 0] 	R0_out, R1_out, R2_out, R3_out														;
  wire [word_size-1: 0] 	PC_count, Y_value, alu_out,mul_LSB_byte,mul_MSB_byte								;
  wire 						alu_zero_flag																		;
  wire 						alu_overflow_flag																	;
  wire 						alu_mul_done_flag																	;
  wire [op_size-1 : 0] 		opcode = instruction [word_size-1: word_size-op_size]								;

  Register_Unit 		R0 	(R0_out, Bus_2, Load_R0, clk, rst)													;
  Register_Unit 		R1 	(R1_out, Bus_2, Load_R1, clk, rst)													;
  Register_Unit 		R2 	(R2_out, Bus_2, Load_R2, clk, rst)													;
  Register_Unit 		R3 	(R3_out, Bus_2, Load_R3, clk, rst)													;
  Register_Unit 		Reg_Y (Y_value, Bus_2, Load_Reg_Y, clk, rst)											;
  
  D_flop 				Reg_md 	(mdflag, alu_mul_done_flag, Load_Reg_md, clk, rst)								;
  D_flop 				Reg_ov 	(ovflag, alu_overflow_flag, Load_Reg_ov, clk, rst)								;
  D_flop 				Reg_Z 	(Zflag, alu_zero_flag, Load_Reg_Z, clk, rst)									;
  Address_Register 		Add_R	(address, Bus_2, Load_Add_R, clk, rst)											;
  
  Instruction_Register	IR		(instruction, Bus_2, Load_IR, clk, rst)											;
  Program_Counter 		PC		(PC_count, Bus_2, Load_PC, Inc_PC, clk, rst)									;
  Multiplexer_5ch 		Mux_1 (Bus_1, R0_out, R1_out, R2_out, R3_out, PC_count, Sel_Bus_1_Mux)					;
  Multiplexer_5ch 		Mux_2	(Bus_2, alu_out, Bus_1, mem_word,mul_LSB_byte,mul_MSB_byte, Sel_Bus_2_Mux)		;
  Alu_RISC 				ALU	(alu_mul_done_flag,alu_overflow_flag,alu_zero_flag, alu_out,mul_LSB_byte,mul_MSB_byte, Y_value, Bus_1, opcode,clk)			;
  
endmodule 