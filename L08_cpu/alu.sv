`include "typedefs.vh"
import typedefs::*;

module alu #(
parameter WIDTH = 8
)(
output logic [WIDTH-1: 0] out  ,
output logic 			  zero  ,
input  logic [WIDTH-1: 0] accum ,
input  logic [WIDTH-1: 0] data ,
input  opcode_t 		  opcode,
input  logic 			  clk

);


timeunit 1ns;
timeprecision 100ps;

//It is for the zero output signal

always_comb begin 
	zero = ~(|accum);
end


always_ff @(negedge clk) begin

	unique case (opcode)
		
		HLT : out <= accum;
		SKZ : out <= accum;
		ADD : out <= data + accum;
		AND : out <= data & accum;
		XOR : out <= data ^ accum;
		LDA : out <= data;
		STO : out <= accum;
		JMP : out <= accum;
		default : out <= 8'bxxxxxxx;
	endcase
end




















endmodule