class base_seq extends uvm_sequence#(m_axi_tx);
    `uvm_object_utils(base_seq)

    `NEW_OBJ

    int count;
    m_axi_tx tx, tx_t;

    task pre_body();
    endtask

    task post_body();
    endtask

endclass


class seq_wr extends base_seq;
    `uvm_object_utils(seq_wr)

    `NEW_OBJ
	
    task body();
      if (!uvm_config_db#(int)::get(get_sequencer(), "", "count", count)) begin// why becasue this is a object so no" this "
         `uvm_fatal("SEQ_LIB", "count not received !!!!!!")
      end
      else begin
        `uvm_info("SEQ_LIB", "count received", UVM_MEDIUM)
      end
			
        repeat (count) begin
            `uvm_do_with(req,{
                req.user_rnw         ==1'b0;
                req.user_total_bytes == 15;
                req.user_burst       == 2'b01;
				req.user_start_addr  == 32'h1002;
                req.m_axi_rid        == 0;
               // req.m_axi_rdata      == 0;
               // req.m_axi_rresp      == 0;
               // req.m_axi_rlast      == 0;
              //  req.m_axi_rvalid     == 0;
				req.user_tx_wstrb == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[1] == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[2] == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[3] == {(`DATA_WIDTH/8){1'b1}};
		//		req.user_tx_data[0] == 32'h0000_0001;
        //         req.user_tx_data[1] == 32'h0000_0002;
        //         req.user_tx_data[2] == 32'h0000_0003;
		//		 req.user_tx_data[3] == 32'h0000_0004;
            })

            `uvm_info("SEQ_LIB",
                $sformatf("Successfully generated and sent write transaction:\n%s",
                req.sprint()), UVM_HIGH)
        end

        tx_t = m_axi_tx::type_id::create("tx_t");
        tx_t.copy(req);

    endtask
endclass

class seq_rd extends base_seq;
	`uvm_object_utils(seq_rd)

	`NEW_OBJ

task body();
         if (!uvm_config_db#(int)::get(get_sequencer(), "", "count", count)) begin// why becasue this is a object so no" this "
         `uvm_fatal("SEQ_LIB", "count not received !!!!!!")
      end
      else begin
        `uvm_info("SEQ_LIB", "count received", UVM_MEDIUM)
      end
		
        repeat (count) begin
            `uvm_do_with(req,{
                req.user_rnw         == 1'b1;
                req.user_total_bytes == 15;
                req.user_burst       == 2'b01;
				req.user_start_addr  == 32'h1002;
                req.m_axi_rid        == 0;
               // req.m_axi_rdata      == 0;
               // req.m_axi_rresp      == 0;
               // req.m_axi_rlast      == 0;
              //  req.m_axi_rvalid     == 0;
				req.user_tx_wstrb == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[1] == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[2] == {(`DATA_WIDTH/8){1'b1}};
			//	req.user_tx_wstrb[3] == {(`DATA_WIDTH/8){1'b1}};
		//		req.user_tx_data[0] == 32'h0000_0001;
        //         req.user_tx_data[1] == 32'h0000_0002;
        //         req.user_tx_data[2] == 32'h0000_0003;
		//		 req.user_tx_data[3] == 32'h0000_0004;
            })

            `uvm_info("SEQ_LIB",$sformatf("Successfully generated and sent write transaction:\n%s",req.sprint()), UVM_HIGH)
        end

        tx_t = m_axi_tx::type_id::create("tx_t");
        tx_t.copy(req);
	endtask
endclass

// Why is a loop not being used here?
// A constraint is defined in the transaction class that resizes the array
// based on the total number of beats. Therefore, the array is automatically
// created with the required size, and all its elements are randomized.
