/*ALU Instruction		Action
ADD			Adds the datapaths to form data_1 + data_2.
SUB			Subtracts the datapaths to form data_1 - data_2.
AND			Takes the bitwise-and of the datapaths, data_1 & data_2.
NOT			Takes the bitwise Boolean complement of data_1.
*/
// Note: the carries are ignored in this model.
 
module Alu_RISC (alu_mul_done_flag,alu_overflow_flag,alu_zero_flag, alu_out,mul_LSB_byte,mul_MSB_byte, data_1, data_2, sel,clk);
  parameter word_size = 8;
  parameter op_size = 4;
  // Opcodes
  parameter NOP 	= 4'b0000							;
  parameter ADD 	= 4'b0001							;
  parameter SUB 	= 4'b0010							;
  parameter AND 	= 4'b0011							;
  parameter NOT 	= 4'b0100							;
  parameter RD  	= 4'b0101							;
  parameter WR		= 4'b0110							;
  parameter BR		= 4'b0111							;
  parameter BRZ 	= 4'b1000							;
  parameter BRO 	= 4'b1001							;
  parameter MUL 	= 4'b1010							;

  output 						alu_overflow_flag		;
  output 						alu_zero_flag			;
  output 						alu_mul_done_flag		;
  output 	[word_size-1: 0] 	alu_out					;
  output 	[word_size-1: 0] 	mul_LSB_byte			;
  output 	[word_size-1: 0] 	mul_MSB_byte			;
  input 	[word_size-1: 0] 	data_1, data_2			;
  input 	[op_size-1: 0] 		sel						;
  input     					clk						;
  reg 		[word_size-1: 0]	alu_out					;
  reg 		[word_size-1: 0]	Multiplicand			;
  reg 		[word_size-1: 0]	Multiplier				;
  reg 							Reset					;
  reg 							Reset1					;
  reg 							Reset2					;
  reg 							Reset3					;
  wire							mul_done				;
  reg							mul_en					;
  reg 							mul_en_del				;
  wire							mul_en_rsg				;
  wire          [(2*word_size)-1: 0]    		Product					;
  reg                                   check_mul_flag;

//ZERO FLAG
  assign  alu_zero_flag = ~|alu_out;
//OVERFLOW FLAG 
 assign  alu_overflow_flag	=	(data_1[word_size - 1] & data_2[word_size - 1] & ~alu_out[word_size - 1])|(~data_1[word_size - 1] & ~data_2[word_size - 1] & alu_out[word_size - 1])	;

//MUL_DONE_FLAG
 assign alu_mul_done_flag	=	mul_done	;
 
 initial
 begin
	check_mul_flag  <=	1'b1	;
	mul_en			<=	1'b0	;
end 
 
	always @ (sel or data_1 or data_2) 
	begin  
		 case  (sel)
		  NOP:	alu_out = 0;
		  ADD:	alu_out = data_1 + data_2;  // Reg_Y + Bus_1
		  SUB:	alu_out = data_2 - data_1;
		  AND:	alu_out = data_1 & data_2;
		  NOT:	alu_out = ~ data_2;	 // Gets data from Bus_1
		  MUL:	mul_en = 1	;
		  default: 	alu_out = 0	;
		endcase 
	end	 
	
		
	//These delays are to wait for loading the data into ALU from registers 
	always @(posedge clk)
	begin
		Reset1		<=	Reset	;
		Reset2		<=	Reset1	;
		Reset3		<=	Reset2	;
		mul_en_del	<=	mul_en	;
	end 
	
	assign mul_en_rsg	= mul_en & ~(mul_en_del)	;
		
	always @(posedge clk)
	begin
		if(mul_en_rsg == 1'b1 && check_mul_flag == 1'b1)
		begin
			Reset 			<= 	1'b1 	;
			check_mul_flag 	<=	1'b0	;
		end
		else if(mul_done == 1'b1)
		begin
			check_mul_flag 	<=	1'b1	;
			Reset 			<= 	1'b0 	;
		end
		else
			Reset 			<= 	1'b0 	;
	end 

	
	assign mul_LSB_byte	=	Product[7:0]	;
	assign mul_MSB_byte	=	Product[15:8]	;
	
	Eight_Bit_Multiplier_RISC MULTIPLIER
	(
		 .Clock(clk)													,
		 .Reset(Reset)													,
		 .Multiplicand(data_1)											,                             
		 .Multiplier(data_2)											, 
		 .Product(Product)												,
		 .mul_done(mul_done)														
	);  
	
endmodule
