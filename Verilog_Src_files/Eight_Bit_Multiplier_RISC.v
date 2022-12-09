//Multiplier. Verilog behavioral model.
module Eight_Bit_Multiplier_RISC 
	(
		input 				Clock										, 
		input 				Reset										,		
		input  	[7:0] 		Multiplicand								,
		input  	[7:0] 		Multiplier									,        
		output 	[15:0] 		Product										,
		output 				mul_done										
	);
	
	reg 	[7:0]  	RegQ   												;      // Q register
	reg 	[16:0]	RegA												;      // A register
	reg 	[16:0] 	RegM												;      // M register
	reg 	[2:0] 	Count												;      //	3-bit iteration counter

	wire 	C0, Start, Add, Shift, sub, sub_flag						;
	
	assign 	Product = {RegA[7:0],RegQ}									;		
	
	// 3-bit counter for #iterations
	always @(posedge Clock)
	if (Start == 1) 
		Count <= 3'b00													;       // clear in Start state
	else if (Shift == 1) 
		Count <= Count + 1												;  		// increment in Shift state
			
	assign C0 			= Count[2] & Count[1] & Count[0]				;      	// detect count = 7

	// Multiplicand register (load only)
	always @(posedge Clock)
		if (Start == 1) 
				RegM <= {{8{Multiplicand[7]}},Multiplicand}				;

	// Multiplier register (load, shift)
	always @(posedge Clock)
	if (Start == 1)  
			RegQ <= Multiplier											;     // load in Start state
	else if (Shift == 1) 
		RegQ <= {RegA[0],RegQ[7:1]}										;  	// shift in Shift state
		
	// Accumulator register (clear, load, shift)
	always @(posedge Clock)
	if (Start == 1)
			RegA	<=	16'd0											;
	else if(sub == 1)
		RegA	<=	RegA - RegM											;		//subtract sub stae
	else if (Add == 1)  
		RegA <= RegA + RegM												;    	// load in Add state
	else if(Shift == 1)							 								// shift in Shift state 
		RegA	<= RegA >> 1											;
	

	// Instantiate controller module

	MultControl Ctrl
	(
		 .Clock(Clock)													,
		 .Reset(Reset)													,
		 .Q0(RegQ[0])													,                             
		 .C0(C0)														, 
		 .Start(Start)													,
		 .Add(Add)														,
		 .sub(sub)														,
		 .Shift(Shift)													,
		 .Halt(mul_done)										
	);  

endmodule 