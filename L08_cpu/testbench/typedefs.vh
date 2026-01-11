`ifndef TYPEDEFS_VH
`define TYPEDEFS_VH

package typedefs;

	typedef enum logic[2:0] {INST_ADDR= 0, INST_FETCH= 1, INST_LOAD= 2, IDLE= 3, OP_ADDR= 4, OP_FETCH= 5, ALU_OP= 6, STORE= 7} state_t;
	
	typedef enum logic[2:0] {HLT= 0, SKZ= 1, ADD= 2, AND= 3, XOR= 4, LDA= 5, STO= 6, JMP= 7} opcode_t;
	
	
endpackage


`endif