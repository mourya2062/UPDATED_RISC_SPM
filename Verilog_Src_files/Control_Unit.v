module Control_Unit (
  Load_R0, Load_R1, 
  Load_R2, Load_R3, 
  Load_PC, Inc_PC, 
  Sel_Bus_1_Mux, Sel_Bus_2_Mux,
  Load_IR, Load_Add_R, Load_Reg_Y, Load_Reg_Z, Load_Reg_ov,Load_Reg_md,
  write, instruction, zero,over_flow,mul_done, clk, rst);
 
  parameter word_size = 8, op_size = 4, state_size = 4;
  parameter src_size = 2, dest_size = 2, Sel1_size = 3, Sel2_size = 3;
  // State Codes
  parameter S_idle = 0, S_fet1 = 1, S_fet2 = 2, S_dec = 3;
  parameter  S_ex1 = 4, S_rd1 = 5, S_rd2 = 6,S_ex2 = 12,mul_done_wait = 13,LD_MUL_MSB=14;  
  parameter S_wr1 = 7, S_wr2 = 8, S_br1 = 9, S_br2 = 10, S_halt = 11;  
  // Opcodes
  parameter NOP = 0, ADD = 1, SUB = 2, AND = 3, NOT = 4	,MUL = 10;
  parameter RD  = 5, WR =  6,  BR =  7, BRZ = 8,BRO = 9	;  
  // Source and Destination Codes  
  parameter R0 = 0, R1 = 1, R2 = 2, R3 = 3;  

  output Load_R0, Load_R1, Load_R2, Load_R3;
  output Load_PC, Inc_PC;
  output [Sel1_size-1:0] Sel_Bus_1_Mux;
  output Load_IR, Load_Add_R;
  output Load_Reg_Y, Load_Reg_Z,Load_Reg_ov,Load_Reg_md;
  output [Sel2_size-1: 0] Sel_Bus_2_Mux;
  output write;
  input [word_size-1: 0] instruction;
  input zero;
  input over_flow;
  input mul_done;
  input clk, rst;
 
  reg [state_size-1: 0] state, next_state;
  reg Load_R0, Load_R1, Load_R2, Load_R3, Load_PC, Inc_PC;
  reg Load_IR, Load_Add_R, Load_Reg_Y;
  reg Sel_ALU, Sel_Bus_1, Sel_Mem,Sel_mul_LSB,Sel_mul_MSB;
  reg Sel_R0, Sel_R1, Sel_R2, Sel_R3, Sel_PC;
  reg Load_Reg_Z, write,Load_Reg_ov,Load_Reg_md;
  reg err_flag;

  wire [op_size-1:0] opcode = instruction [word_size-1: word_size - op_size];
  wire [src_size-1: 0] src = instruction [src_size + dest_size -1: dest_size];
  wire [dest_size-1:0] dest = instruction [dest_size -1:0];
  reg  temp = 0	;
 
  // Mux selectors
  assign  Sel_Bus_1_Mux[Sel1_size-1:0] = Sel_R0 ? 0:
				 Sel_R1 ? 1:
				 Sel_R2 ? 2:
				 Sel_R3 ? 3:
				 Sel_PC ? 4: 3'bx;  // 3-bits, sized number

  assign  Sel_Bus_2_Mux[Sel2_size-1:0] = Sel_ALU ? 0:
				 Sel_Bus_1 	 ? 1:
				 Sel_Mem 	 ? 2:
				 Sel_mul_LSB ? 3:
				 Sel_mul_MSB ? 4: 3'bx;

  always @ (posedge clk or negedge rst) begin: State_transitions
    if (rst == 0) state <= S_idle; else state <= next_state; end

/*  always @ (state or instruction or zero) begin:  Output_and_next_state	
Note: The above event control expression leads to incorrect operation.  The state transition causes the activity to be evaluated once, then the resulting instruction change causes it to be evaluated again, but with the residual value of opcode.  On the second pass the value seen is the value opcode had before the state change, which results in Sel_PC = 0 in state 3, which will cause a return to state 1 at the next clock.  Finally, opcode is changed, but this does not trigger a re-evaluation because it is not in the event control expression.  So, the caution is to be sure to use opcode in the event control expression. That way, the final execution of the behavior uses the value of opcode that results from the state change, and leads to the correct value of Sel_PC.
*/ 

  always @ (posedge clk or state or opcode or zero) begin: Output_and_next_state 
    Sel_R0 = 0; 	Sel_R1 = 0;     	Sel_R2 = 0;    	Sel_R3 = 0;     	Sel_PC = 0;
    Load_R0 = 0; 	Load_R1 = 0; 	Load_R2 = 0; 	Load_R3 = 0;	Load_PC = 0;

    Load_IR = 0;	Load_Add_R = 0;	Load_Reg_Y = 0;	Load_Reg_Z = 0;Load_Reg_ov = 0;Load_Reg_md=0	;
    Inc_PC 		= 0			; 
    Sel_Bus_1 	= 0			; 
    Sel_ALU 	= 0			; 
    Sel_Mem 	= 0			; 
    Sel_mul_LSB = 0			; 
    Sel_mul_MSB = 0			; 
    write 		= 0			; 
    err_flag 	= 0			;	// Used for de-bug in simulation		
    next_state 	= state		;

     case  (state)	
			S_idle:		
				next_state = S_fet1;      
			
			S_fet1:	  begin       	  	  	
						next_state = S_fet2; 
						Sel_PC = 1;
						Sel_Bus_1 = 1;
						Load_Add_R = 1; 
    				  end
      	
			S_fet2:	  begin 		
							next_state = S_dec; 
							Sel_Mem = 1;
      	  	  		   Load_IR = 1; 
      	  	  		   Inc_PC = 1;
    				     end

      	S_dec:  	  case  (opcode) 
							  NOP: next_state = S_fet1;
							  ADD, SUB, AND: begin
													  next_state = S_ex1;
													  Sel_Bus_1 = 1;
													  Load_Reg_Y = 1;
													  case  (src)
															R0: 		Sel_R0 = 1; 
															R1: 		Sel_R1 = 1; 
															R2: 		Sel_R2 = 1;
															R3: 		Sel_R3 = 1; 
															default : 	err_flag = 1;
													  endcase   
													end // ADD, SUB, AND

							  NOT: begin
									 next_state = S_fet1;
									 Load_Reg_Z = 1;
									 Sel_Bus_1 = 1; 
									 Sel_ALU = 1; 
									 case  (src)
											R0: 		Sel_R0 = 1;			      
											R1: 		Sel_R1 = 1;
											R2: 		Sel_R2 = 1;			      
											R3: 		Sel_R3 = 1; 
											default : 	err_flag = 1;
									 endcase   
									 case  (dest)
											R0: 		Load_R0 = 1; 
											R1: 		Load_R1 = 1;			      
											R2: 		Load_R2 = 1;
											R3: 		Load_R3 = 1;			      
											default: 	err_flag = 1;
									 endcase   
									 end // NOT
  				  
							RD: begin
									 next_state = S_rd1;
									 Sel_PC = 1; Sel_Bus_1 = 1; Load_Add_R = 1; 
								 end // RD

							WR: begin
									 next_state = S_wr1;
									 Sel_PC = 1; Sel_Bus_1 = 1; Load_Add_R = 1; 
								 end  // WR

							BR: begin 
									next_state = S_br1;  
									Sel_PC = 1; Sel_Bus_1 = 1; Load_Add_R = 1; 
								 end  // BR
	
							BRZ: if (zero == 1) 
										begin//Fetching the next instruction without incrementing PC if the condition satisfied 
											next_state = S_br1; 
											Sel_PC = 1; Sel_Bus_1 = 1; Load_Add_R = 1; 
										end // BRZ
									else 
										begin //If the condition fails then the code in the next address shouldn't be fetched and ececuted .So,PC is incremented 
											 next_state = S_fet1; 
											 Inc_PC = 1; 
										end
	
							BRO: if (over_flow == 1) 
										begin
											next_state = S_br1; //Fetching the next instruction without incrementing PC if the condition satisfied 
											Sel_PC = 1; Sel_Bus_1 = 1; Load_Add_R = 1; 
										end // BRZ
									else //If the condition fails then the code in the next address shouldn't be fetched and ececuted .So,PC is incremented 
										begin 
											 next_state = S_fet1; 
											 Inc_PC = 1; 
										end
										
							MUL: begin
									  next_state 	= S_ex2	;
									  Sel_Bus_1 	= 1		;
									  Load_Reg_Y 	= 1		;
									  case  (src)
											R0: 		Sel_R0 = 1; 
											R1: 		Sel_R1 = 1; 
											R2: 		Sel_R2 = 1;
											R3: 		Sel_R3 = 1; 
											default : 	err_flag = 1;
									  endcase   
								end // MUL
								
							default : 
										next_state = S_halt;
							endcase  // (opcode)
				
				S_ex1:		begin 
								  next_state = S_fet1;
								  Load_Reg_Z = 1;
								  Load_Reg_ov	=	1;	//BRO
								  Sel_ALU = 1; 
									  case  (dest)
										 R0: begin Sel_R0 = 1; Load_R0 = 1; end
										 R1: begin Sel_R1 = 1; Load_R1 = 1; end
										 R2: begin Sel_R2 = 1; Load_R2 = 1; end
										 R3: begin Sel_R3 = 1; Load_R3 = 1; end
										 default : err_flag = 1; 
									  endcase  
								end 
				
				S_ex2:		begin 
								  next_state 	= mul_done_wait	;
								  //Load_Reg_md 	= 1				;
								  //temp			=~temp	;
									  case  (dest)
										 R0: Sel_R0 = 1; 
										 R1: Sel_R1 = 1; 
										 R2: Sel_R2 = 1; 
										 R3: Sel_R3 = 1; 
										 default : err_flag = 1; 
									  endcase  
								end 
								

				mul_done_wait:begin
								if(mul_done == 1) 
								begin
									next_state = LD_MUL_MSB			;
									Load_Reg_Z 	= 	1				;
									Load_Reg_ov	=	1				;
									Sel_mul_LSB = 	1				;
									  case  (src)
										 R0: Load_R0 = 1			; 
										 R1: Load_R1 = 1			; 
										 R2: Load_R2 = 1			; 
										 R3: Load_R3 = 1			; 
										 default : err_flag = 1		;	 
									  endcase 
								end 
							else
								begin
								  next_state 	= state				;
								  Load_Reg_md 	= 1					;
								  temp			=~temp	;
								  case  (dest)
										 R0: Sel_R0 = 1; 
										 R1: Sel_R1 = 1; 
										 R2: Sel_R2 = 1; 
										 R3: Sel_R3 = 1; 
										 default : err_flag = 1; 
									  endcase 
								end
								end
							
				LD_MUL_MSB:	begin
							next_state = S_fet1;
							Load_Reg_Z 	= 	1				;
							Load_Reg_ov	=	1				;
							Sel_mul_MSB = 	1				;
							case  (dest)
								 R0: Load_R0 = 1			; 
								 R1: Load_R1 = 1			; 
								 R2: Load_R2 = 1			; 
								 R3: Load_R3 = 1			; 
							 default : err_flag = 1		;	 
						  endcase 
						end 
							

    	      S_rd1:		begin 
								  next_state = S_rd2;
								  Sel_Mem = 1;
								  Load_Add_R = 1; 
								  Inc_PC = 1;
								end

    	      S_wr1: 		begin
								  next_state = S_wr2;
								  Sel_Mem = 1;
								  Load_Add_R = 1; 
								  Inc_PC = 1;
								end 

      		S_rd2:		begin 
								  next_state = S_fet1;
								  Sel_Mem = 1;
									  case  (dest) 
										 R0: 		Load_R0 = 1; 
										 R1: 		Load_R1 = 1; 
										 R2: 		Load_R2 = 1; 
										 R3: 		Load_R3 = 1; 
										 default : 	err_flag = 1;
									  endcase  
								end

    	      S_wr2:		begin 
								  next_state = S_fet1;
								  write = 1;
								  case  (src)
										 R0: 		Sel_R0 = 1;		 	    
										 R1: 		Sel_R1 = 1;		 	    
										 R2: 		Sel_R2 = 1; 		 	    
										 R3: 		Sel_R3 = 1;			    
										 default : 	err_flag = 1;
								  endcase  
								end

				S_br1:		begin next_state = S_br2; Sel_Mem = 1; Load_Add_R = 1; end
				S_br2:		begin next_state = S_fet1; Sel_Mem = 1; Load_PC = 1; end
				S_halt:  		next_state = S_halt;
				default:		next_state = S_idle;
     endcase    
  end
  
endmodule 