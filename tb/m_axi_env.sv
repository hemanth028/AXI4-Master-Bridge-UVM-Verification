class m_axi_env extends uvm_env;
	`uvm_component_utils(m_axi_env)

	`NEW_COMP

	m_axi_agent agent;
	m_axi_sbd   sbd;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent=new("agent",this);
		sbd=new("sbd",this);
	endfunction

	function void connect_phase(uvm_phase phase);
			agent.mon.ap_port.connect(sbd.imp_axi);
	endfunction
endclass
