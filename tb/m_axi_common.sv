`define ADDR_WIDTH       32
`define DATA_WIDTH       32
`define ID_WIDTH         4
`define ID_VALUE         4'b0000
`define FIFO_DEPTH       16
`define MAX_OUTSTANDING  4

`define NEW_COMP \
function new(string name, uvm_component parent); \
    super.new(name, parent); \
endfunction

`define NEW_OBJ \
function new(string name = ""); \
    super.new(name); \
endfunction

class m_axi_common;
	static int match;
	static int mismatch;
endclass
