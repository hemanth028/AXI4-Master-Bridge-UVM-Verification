class m_axi_driver extends uvm_driver#(m_axi_tx);
	`uvm_component_utils(m_axi_driver)

	`NEW_COMP
	virtual m_axi_intf vif;
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("DRIVER","build_phase of driver",UVM_HIGH)
		if(!uvm_config_db#(virtual m_axi_intf)::get(this,"","VIF",vif))begin
			`uvm_fatal("DRIVER","failed getting vif")
		end
		else 
			`uvm_info("DRIVER","successful retrival of vif",UVM_HIGH)
	endfunction	

	task run_phase(uvm_phase phase);

		vif.drv_cb.user_cmd_valid   <= 1'b0;
        vif.drv_cb.user_tx_valid    <= 1'b0;
        vif.drv_cb.user_rx_ready    <= 1'b0;
        vif.drv_cb.user_start_addr  <= 0;
        vif.drv_cb.user_total_bytes <= 0;
        vif.drv_cb.user_rnw         <= 1'b0;
        vif.drv_cb.user_burst       <= 2'b00;
        vif.drv_cb.user_tx_data     <= 0;
        vif.drv_cb.user_tx_wstrb    <= 0;

        // Initialize Slave Emulations [1.2.6]
        vif.drv_cb.m_axi_awready    <= 1'b0;
        vif.drv_cb.m_axi_wready     <= 1'b0;
        vif.drv_cb.m_axi_arready    <= 1'b0;
        vif.drv_cb.m_axi_bvalid     <= 1'b0;
        vif.drv_cb.m_axi_rvalid     <= 1'b0;

		@(posedge vif.ACLK);
	//	while(!vif.ARESET_n) @(posedge vif.ACLK);
		forever begin
			seq_item_port.get_next_item(req);
			drive_item(req);
			req.print();
			seq_item_port.item_done();		
		end
	endtask
task drive_item(m_axi_tx tx);

  //  while (!vif.ARESET_n)
    //    @(posedge vif.ACLK);

    fork

       // Command / Address Channel (AW/AR)

        begin : cmd_thread

            // User command
            vif.drv_cb.user_cmd_valid <= 1'b1;
				
         //   if (vif.drv_cb.user_cmd_valid && vif.drv_cb.user_cmd_ready) 
		//		`uvm_info("HANDSHAKING_DRV",$sprintf("VALUE OF CMD_VALID %b AND READY %b ",vif.drv_cb.user_cmd_valid , vif.drv_cb.user_cmd_ready),UVM_HIGH)
		
          		wait(vif.drv_cb.user_cmd_ready);
				wait(vif.drv_cb.user_cmd_valid);
				vif.drv_cb.user_start_addr  <= req.user_start_addr;
                vif.drv_cb.user_total_bytes <= req.user_total_bytes;
                vif.drv_cb.user_rnw         <= req.user_rnw;
                vif.drv_cb.user_burst       <= req.user_burst;
            
			@(posedge vif.drv_cb);
      //      vif.drv_cb.user_cmd_valid <= 1'b0;

            vif.drv_cb.m_axi_awready <= 1'b1;
            vif.drv_cb.m_axi_arready <= 1'b1;

            if (req.user_rnw == 1'b0) begin
                // ---------------- WRITE ADDRESS ----------------

               // if (vif.drv_cb.m_axi_awready && vif.drv_cb.m_axi_awvalid) begin
					wait(vif.drv_cb.m_axi_awready);
					wait(vif.drv_cb.m_axi_awvalid);
                    req.m_axi_awid    = vif.drv_cb.m_axi_awid;
                    req.m_axi_awaddr  = vif.drv_cb.m_axi_awaddr;
                    req.m_axi_awlen   = vif.drv_cb.m_axi_awlen;
                    req.m_axi_awsize  = vif.drv_cb.m_axi_awsize;
                    req.m_axi_awburst = vif.drv_cb.m_axi_awburst;
                    req.m_axi_awvalid = vif.drv_cb.m_axi_awvalid;
              //  end
             ///   else begin
              //      @(posedge vif.drv_cb);
              //  end
		
            end
            else begin
                // ---------------- READ ADDRESS ----------------
				wait(vif.drv_cb.m_axi_arready);
				wait(vif.drv_cb.m_axi_arvalid);
                req.m_axi_arid    = vif.drv_cb.m_axi_arid;
                req.m_axi_araddr  = vif.drv_cb.m_axi_araddr;
                req.m_axi_arlen   = vif.drv_cb.m_axi_arlen;
                req.m_axi_arsize  = vif.drv_cb.m_axi_arsize;
                req.m_axi_arburst = vif.drv_cb.m_axi_arburst;
                req.m_axi_arvalid = vif.drv_cb.m_axi_arvalid;
            end

            @(posedge vif.drv_cb);

            vif.drv_cb.m_axi_awready <= 1'b0;
            vif.drv_cb.m_axi_arready <= 1'b0;

        end


       
        // Data Channel (W/B or R)
        
        begin : data_thread
		            //---------------- WRITE DATA ----------------
            if (req.user_rnw == 1'b0) begin

                vif.drv_cb.m_axi_wready <= 1'b1;
				vif.drv_cb.user_tx_wstrb <= req.user_tx_wstrb;
				@(posedge vif.ACLK);
				  req.m_axi_wstrb  = vif.drv_cb.m_axi_wstrb;
				  req.m_axi_wvalid = vif.drv_cb.m_axi_wvalid;

                for (int i = 0; i <=req.user_tx_data.size(); i++) begin

                    vif.drv_cb.user_tx_valid <= 1'b1;
					
				    vif.drv_cb.user_tx_data  <= req.user_tx_data[i];
				//		@(posedge vif.ACLK);
                  `uvm_info("WRITE_DATA",$sformatf("user_data %h", req.user_tx_data[i]),UVM_HIGH)					  
				   // req.m_axi_wvalid = vif.drv_cb.m_axi_wvalid;
						@(posedge vif.ACLK);
					 
                   wait (vif.drv_cb.m_axi_wready);
				   wait(vif.m_axi_wvalid);				
				     req.m_axi_wdata  = vif.drv_cb.m_axi_wdata;
                 end
				 req.m_axi_wlast  = vif.drv_cb.m_axi_wlast;

             //  vif.drv_cb.user_tx_valid <= 1'b0;
                vif.drv_cb.m_axi_wready  <= 1'b0;

           //     repeat (5)
                    @(vif.drv_cb);

                vif.drv_cb.m_axi_bvalid <= 1'b1;
                vif.drv_cb.m_axi_bid    <= vif.drv_cb.m_axi_awid;
                vif.drv_cb.m_axi_bresp  <= 2'b00;

                wait (vif.drv_cb.write_complete);

                req.m_axi_bready  = vif.drv_cb.m_axi_bready;
                req.write_error   = vif.drv_cb.write_error;

                vif.drv_cb.m_axi_bvalid <= 1'b0;

            end

            //---------------- READ DATA ----------------
            else begin

                int num_beats;

                num_beats = (req.user_total_bytes + (`DATA_WIDTH/8) - 1) /(`DATA_WIDTH/8);
				`uvm_info("DRV",$sformatf("num_beats",num_beats),UVM_HIGH)
                req.user_rx_data = new[num_beats];

                for (int i = 0; i <num_beats; i++) begin

                    vif.drv_cb.user_rx_ready <= 1'b1;

                    vif.drv_cb.m_axi_rvalid <= 1'b1;
                    vif.drv_cb.m_axi_rid    <= vif.drv_cb.m_axi_arid;
                    vif.drv_cb.m_axi_rresp  <= 2'b00;
					wait (vif.drv_cb.m_axi_rvalid==1'b1);
					wait (vif.drv_cb.m_axi_rready==1'b1);
				    vif.drv_cb.m_axi_rdata  <= $urandom;
					@(posedge vif.ACLK);
					`uvm_info("READ_LOOP",$sformatf("VALUE %h  i=%d",vif.drv_cb.m_axi_rdata,i),UVM_HIGH)

                    vif.drv_cb.m_axi_rlast  <= (i == num_beats-1);
					@(posedge vif.ACLK);
					req.m_axi_rready    = vif.drv_cb.m_axi_rready;

                    wait (vif.drv_cb.user_rx_valid);
					wait (vif.drv_cb.user_rx_ready);					
                    req.user_rx_data[i] = vif.drv_cb.user_rx_data;
                end

                vif.drv_cb.user_rx_ready <= 1'b0;
                vif.drv_cb.m_axi_rvalid  <= 1'b0;
                vif.drv_cb.m_axi_rlast   <= 1'b0;

                req.read_error = vif.drv_cb.read_error;

            end

        end

    join
	`uvm_info("DRIVE_ITEM","drivers drive_item executed",UVM_HIGH)
endtask
endclass
