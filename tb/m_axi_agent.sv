class m_axi_agent extends uvm_agent;
	`uvm_component_utils(m_axi_agent)

	`NEW_COMP

	m_axi_seq sqr;
	m_axi_driver drv;
	m_axi_mon mon;
	m_axi_cov cov;
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sqr=new("sqr",this);
		mon=new("mon",this);
		drv=new("drv",this);
		cov=new("cov",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	    mon.ap_port.connect(cov.analysis_export);	
	endfunction
endclass
