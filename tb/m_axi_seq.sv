class m_axi_seq extends uvm_sequencer#(m_axi_tx);
	`uvm_component_utils(m_axi_seq)

	`NEW_COMP

	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("SEQUENCER","build_phase of sequencer",UVM_HIGH)
	endfunction
endclass
