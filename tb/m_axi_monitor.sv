class m_axi_mon extends uvm_monitor;
    `uvm_component_utils(m_axi_mon)

    `NEW_COMP
    uvm_analysis_port#(m_axi_tx) ap_port;
    virtual m_axi_intf vif;
    m_axi_tx tx;
    int num_beats;

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        ap_port = new("ap_port", this);    
        `uvm_info("MONITOR", "build_phase of monitor", UVM_HIGH)
        if (!uvm_config_db#(virtual m_axi_intf)::get(this, "", "VIF", vif))
            `uvm_fatal("MONITOR", "Failed to get vif")
        else
            `uvm_info("MONITOR", "successful retrieval of vif", UVM_HIGH)
    endfunction

    task run_phase(uvm_phase phase);
        
        // Wait for reset event (kept exactly as in your original draft) [1.2.7]
        wait(vif.ARESET_n);
        
        forever begin

			@(vif.mon_cb);
            
            // 1. Detect the User-Side Command Handshake on the bus [1.2.9]
            if (vif.mon_cb.user_cmd_valid && vif.mon_cb.user_cmd_ready) begin
                
                // Create a new transaction item to avoid overwriting previous data [1.1.2]
                tx = m_axi_tx::type_id::create("tx");

                // Sample user-side command parameters [1, 2]
                tx.user_start_addr  = vif.mon_cb.user_start_addr;
                tx.user_total_bytes = vif.mon_cb.user_total_bytes;
                tx.user_rnw         = vif.mon_cb.user_rnw;
                tx.user_burst       = vif.mon_cb.user_burst;

                // Passively read/sample the physical AXI AW or AR channel outputs of the DUT [1]
                if (tx.user_rnw == 1'b0) begin : CAPTURE_AXI_AW
                    tx.m_axi_awid    = vif.mon_cb.m_axi_awid;
                    tx.m_axi_awaddr  = vif.mon_cb.m_axi_awaddr;
                    tx.m_axi_awlen   = vif.mon_cb.m_axi_awlen;
                    tx.m_axi_awsize  = vif.mon_cb.m_axi_awsize;
                    tx.m_axi_awburst = vif.mon_cb.m_axi_awburst;
                    tx.m_axi_awvalid = vif.mon_cb.m_axi_awvalid;
					tx.m_axi_awready = vif.mon_cb.m_axi_awready;
                end else begin : CAPTURE_AXI_AR
                    tx.m_axi_arid    = vif.mon_cb.m_axi_arid;
                    tx.m_axi_araddr  = vif.mon_cb.m_axi_araddr;
                    tx.m_axi_arlen   = vif.mon_cb.m_axi_arlen;
                    tx.m_axi_arsize  = vif.mon_cb.m_axi_arsize;
                    tx.m_axi_arburst = vif.mon_cb.m_axi_arburst;
                    tx.m_axi_arvalid = vif.mon_cb.m_axi_arvalid;
					tx.m_axi_arready = vif.mon_cb.m_axi_arready;
                end

                // Calculate the expected number of words for this burst [1]
                num_beats = (tx.user_total_bytes + (`DATA_WIDTH/8) - 1) / (`DATA_WIDTH/8);

                // 2. Branch to Write or Read payload tracking based on direction
                if (tx.user_rnw == 1'b0) begin : TRACK_WRITE_BURST
                    // --- WRITE TRANSACTION ---
                    tx.user_tx_data  = new[num_beats];
                 //   tx.user_tx_wstrb = new[num_beats];

                    for (int i = 0; i < num_beats; i++) begin
                        // Wait for the next clock edge [1.2.7]
                        @(vif.mon_cb);
                        
                        // Loop until the write data channel handshakes [1.2.5, 1.2.9]
                        while (!(vif.mon_cb.user_tx_valid && vif.mon_cb.user_tx_ready)) begin
                            @(vif.mon_cb);
                        end

                        // Sample payload and strobes [1, 2]
                        tx.user_tx_data[i]  = vif.mon_cb.user_tx_data;
                        tx.user_tx_wstrb = vif.mon_cb.user_tx_wstrb;

                        // Passively read/sample physical AXI W-channel outputs [1]
                        tx.m_axi_wdata   = vif.mon_cb.m_axi_wdata;
                        tx.m_axi_wstrb   = vif.mon_cb.m_axi_wstrb;
                        tx.m_axi_wlast   = vif.mon_cb.m_axi_wlast;
                        tx.m_axi_wvalid  = vif.mon_cb.m_axi_wvalid;
						  tx.m_axi_wready  = vif.mon_cb.m_axi_wready; 
                    end

                    // Wait for the write response handshake (completion or error) [1]
                    @(vif.mon_cb);
                    while (!(vif.mon_cb.write_complete || vif.mon_cb.write_error)) begin
                        @(vif.mon_cb);
                    end

                    // Capture status outputs and AXI response signals [1, 2]
                    tx.write_complete = vif.mon_cb.write_complete;
                    tx.write_error    = vif.mon_cb.write_error;
                    tx.m_axi_bready   = vif.mon_cb.m_axi_bready;
					tx.m_axi_bid      = vif.mon_cb.m_axi_bid;    // <-- NEW: Captured [1]
                    tx.m_axi_bresp    = vif.mon_cb.m_axi_bresp;  // <-- NEW: Captured [1]
                    tx.m_axi_bvalid   = vif.mon_cb.m_axi_bvalid;

                end else begin : TRACK_READ_BURST
                    // --- READ TRANSACTION ---
                    tx.user_rx_data  = new[num_beats];

                    for (int i = 0; i < num_beats; i++) begin
                        // Wait for the next clock edge [1.2.7]
                        @(vif.mon_cb);
                        
                        // Loop until the read data channel handshakes [1.2.5, 1.2.9]
                        while (!(vif.mon_cb.user_rx_valid && vif.mon_cb.user_rx_ready)) begin
                            @(vif.mon_cb);
                        end

                        // Sample incoming read payload and AXI R-channel outputs [1, 2]
                        tx.user_rx_data[i] = vif.mon_cb.user_rx_data;
                        tx.m_axi_rready    = vif.mon_cb.m_axi_rready;
						tx.m_axi_rid       = vif.mon_cb.m_axi_rid;    // <-- NEW: Captured [1]
                        tx.m_axi_rdata     = vif.mon_cb.m_axi_rdata;  // <-- NEW: Captured [1]
                        tx.m_axi_rresp     = vif.mon_cb.m_axi_rresp;  // <-- NEW: Captured [1]
                        tx.m_axi_rlast     = vif.mon_cb.m_axi_rlast;  // <-- NEW: Captured [1]
                        tx.m_axi_rvalid    = vif.mon_cb.m_axi_rvalid; 
                    end

                    // Capture read status outputs [1, 2]
                    tx.read_error     = vif.mon_cb.read_error;
                end

                // 4. Broadcast the completed transaction to Scoreboard/Coverage [1.1.2]
				tx.print();		
                ap_port.write(tx);
            end
        end
    endtask
endclass
