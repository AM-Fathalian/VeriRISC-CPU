// `include "typedefs.vh"
import typedefs::*;


module control (
	output logic      load_ac ,
	output logic      mem_rd  ,
	output logic      mem_wr  ,
	output logic      inc_pc  ,
	output logic      load_pc ,
	output logic      load_ir ,
	output logic      halt    ,
	input  opcode_t   opcode  , // opcode type name must be opcode_t
	input  logic 	  zero   ,
	input             clk     ,
	input             rst_   
	);
// SystemVerilog: time units and time precision specification
timeunit 1ns;
timeprecision 100ps;

state_t current_state, next_state;
logic ALUOP;



always_ff @(posedge clk or negedge rst_)	begin
	  unique if (!rst_)
		 current_state <= INST_ADDR;
	  else
		 current_state <= next_state;
	end
	
	
assign ALUOP = (opcode inside {ADD, AND, XOR, LDA});

always_comb	begin
	next_state = current_state;
	{mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr} = 7'b000_0000;
// typedef enum logic[2:0] {INST_ADDR= 0, INST_FETCH= 1, INST_LOAD= 2, IDLE= 3, OP_ADDR= 4, OP_FETCH= 5, ALU_OP= 6, STORE= 7} state_t;

	  unique case (current_state)
		(INST_ADDR) : begin
			next_state = state_t'(INST_FETCH);
		end
		(INST_FETCH) : begin 
			next_state = state_t'(INST_LOAD);
			mem_rd = '1;
		end
		(INST_LOAD) : begin 
			next_state = state_t'(IDLE);
			mem_rd = '1;
			load_ir = '1;
		end
		(IDLE) : begin
			next_state = state_t'(OP_ADDR); // current_state.next();
			mem_rd = '1;
			load_ir = '1;
		end
		(OP_ADDR) : begin
			next_state = state_t'(OP_FETCH);
			inc_pc = '1;
			halt = (opcode == HLT);
		end
		(OP_FETCH) : begin
			next_state = state_t'(ALU_OP);
			mem_rd = ALUOP;
		end
		(ALU_OP) : begin
			next_state = state_t'(STORE);
			mem_rd = ALUOP;
			load_ac = ALUOP;
			inc_pc = ((opcode == SKZ) && zero);
			load_pc = (opcode == JMP);
		end
		(STORE) : begin
			next_state = state_t'(INST_ADDR);
			mem_rd = ALUOP;
			load_ac = ALUOP;
			load_pc = (opcode == JMP);
			inc_pc =  (opcode == JMP || ((opcode == SKZ) && zero));
			mem_wr = (opcode == STO);
		end

		default : begin 
			next_state = state_t'(INST_ADDR);
		end

	  endcase
	end
	
endmodule
