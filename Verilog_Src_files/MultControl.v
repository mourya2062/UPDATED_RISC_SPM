//Multiplier controller. Verilog behavioral model.
module MultControl 
	(
		input Clock, Reset, Q0, C0,               //declare inputs
		output Start, Add,sub, Shift, Halt			//declare outputs
	);  
	
	reg [5:0] state;                					//five states (one hot –one flip-flop per state)
	
	//one-hot state assignments for five states
	
	parameter StartS=6'b000001, TestS=6'b000010, AddS=6'b000100, ShiftS=6'b001000, HaltS=6'b010000,subS=6'b100000	;

	// State transitions on positive edge of Clock or Resets
	
	always @(posedge Clock, posedge Reset)
	if (Reset==1) 
		state <= StartS		; 				//enter StartS state on Reset
	else 											//change state on Clock
	case (state)          
	StartS:  
			state <= TestS		;       		// StartS to TestS
	TestS:   
		if (Q0 == 1 && C0 == 1) 
			state <= subS		;
		else if(Q0 == 1)
			state <= AddS		; 				// TestS to AddS if Q0=1
		else 
			state <= ShiftS	; 				// TestS to ShiftS if Q0=0
	AddS:  
			state <= ShiftS	;          	// AddS to ShiftS
	subS:
			state <= ShiftS	;          	// subS to ShiftS
	ShiftS:   
		if (C0) 
			state <= HaltS		;  			// ShiftS to HaltS if C0=1
		else 
			state <= TestS		; 				// ShiftS to TestS if C0=0
	HaltS:  
			state <= HaltS		; 				// stay in HaltS
	endcase

	// Moore model - activate one output per state
	assign Start 	= state[0]	;      // Start=1 in state StartS, else 0
	assign Add  	= state[2]	;      // Add=1 in state AddS, else 0
	assign Shift 	= state[3]	;      // Shift=1 in state ShiftS, else 0
	assign Halt  	= state[4]	;      // Halt=1 in state HaltS, else 0
	
	assign sub	 	= state[5] 	;
	
endmodule 