`timescale 1ns / 1ps

module test_RISC_SPM ();
  reg rst;
  wire clk;
  parameter word_size = 8;
  reg [8:0] k;

  Clock_Unit M1 (clk);
  RISC_SPM M2 (clk, rst);

 initial #3500 $finish;
 
// Initialize Memory

initial begin
  #2 rst = 0; for (k=0;k<=255;k=k+1)M2.M2_SRAM.memory[k] = 0; #10 rst = 1;
end

initial begin
 
 // Add the contents of R2 and R3 untill the R3 hits Overflow 
 #5
// opcode_src_dest
 M2.M2_SRAM.memory[0] = 8'b0000_00_00;		// NOP
 M2.M2_SRAM.memory[1] = 8'b0101_00_10;		// Read 130 to R2
 M2.M2_SRAM.memory[2] = 130;
 M2.M2_SRAM.memory[3] = 8'b0101_00_11;		// Read 131 to R3
 M2.M2_SRAM.memory[4] = 131;

 M2.M2_SRAM.memory[5] = 8'b0001_10_11;		// Add R2+R3 to R3
 M2.M2_SRAM.memory[6] = 8'b1001_00_11;		// BRO
 M2.M2_SRAM.memory[7] = 134;
 M2.M2_SRAM.memory[8] = 8'b0111_00_11;		// BR
 M2.M2_SRAM.memory[9] = 140;

// Load data
 M2.M2_SRAM.memory[130] = 10;
 M2.M2_SRAM.memory[131] = 10;
 M2.M2_SRAM.memory[134] = 139;
 M2.M2_SRAM.memory[139] = 8'b1111_00_00;		// HALT
 M2.M2_SRAM.memory[140] = 5;				//  Recycle
end 
//
endmodule 
