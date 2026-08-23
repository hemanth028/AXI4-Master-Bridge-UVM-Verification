class base_test extends uvm_test;
	`uvm_component_utils(base_test)

	`NEW_COMP
	m_axi_env env;
	//int count;
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env=new("env",this);
		`uvm_info("base_test","build_phase of base_test",UVM_HIGH)
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		uvm_top.print_topology();
	endfunction

	function void report_phase(uvm_phase phase);
		if(m_axi_common::match==0 && m_axi_common::mismatch > 0)begin
				`uvm_info("sbd report","#####TEST FAILED######",UVM_HIGH)
			//	`uvm_info("sbd report",$sformatf("Matches=%0d   mismatches=%0d",m_axi_common::match,m_axi_common::mismatch),UVM_HIGH)
			end
			else begin
					`uvm_info("sbd report","#####TEST PASSED######",UVM_HIGH) 
				//	`uvm_info("sbd report",$sformatf("Matches=%0d   mismatches=%0d",m_axi_common::match,m_axi_common::mismatch),UVM_HIGH) 					
			end
	endfunction

endclass

class test_wr extends base_test;
	`uvm_component_utils(test_wr)
	`NEW_COMP
	task run_phase(uvm_phase phase);
		seq_wr seq;
		seq = seq_wr::type_id::create("seq");//no seq=new(); this will lead to 0 ns termination 
  		uvm_config_db#(int)::set(this,"*","count",1);
	//	uvm_config_db#(int)::set(this,"*","rnw",0);
		phase.raise_objection(this);
		seq.start(env.agent.sqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask

	class test_rd extends base_test;
	`uvm_component_utils(test_rd)
	`NEW_COMP

	task run_phase(uvm_phase phase);
		seq_rd seq;
		seq=seq_rd::type_id::create("seq");
		uvm_config_db#(int)::set(this,"*","count",1);
		//uvm_config_db#(int)::set(this,"*","rnw",1);

		phase.raise_objection(this);
		seq.start(env.agent.sqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
endclass
