class m_axi_sbd extends uvm_scoreboard;
    `uvm_component_utils(m_axi_sbd)

    `NEW_COMP

    uvm_analysis_imp #(m_axi_tx, m_axi_sbd) imp_axi;
    m_axi_tx tx;

    // 1. ADDED: SystemVerilog Event for synchronization [1.2.7]
    event tx_received;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp_axi = new("imp_axi", this);
        `uvm_info("SCOREBOARD", "build_phase of sbd", UVM_HIGH)
    endfunction

    // 2. UPDATED: Removed redundant memory allocation and trigger the event [1.2.7, 1.3.1]
    function void write(m_axi_tx t);
        tx = t;            // Save the received handle [1.1.2]
        -> tx_received;    // Trigger the synchronization event [1.2.7]
    endfunction

    task run_phase(uvm_phase phase);

        int start_offset;
        int total_bytes;
        int expected_len;
        bit [3:0] start_wstrb_mask;
        bit [3:0] expected_beat0_strb;

        forever begin
            // 3. UPDATED: Wait for the next transaction to be received [1.2.7]
            // This prevents the infinite zero-delay CPU loop hang! [1.2.7]
            @tx_received; 

            if (tx.user_rnw == 1'b0) begin : CHECK_WRITE_TRANSACTION

                // Address check
                if (tx.m_axi_awaddr !== tx.user_start_addr) begin
                    `uvm_error("SBD_AWADDR",$sformatf("Address mismatch! Expected: 32'h%h, Got: 32'h%h",tx.user_start_addr, tx.m_axi_awaddr))
                    m_axi_common::mismatch++;
                end
                else m_axi_common::match++;

                // Burst type check
                if (tx.m_axi_awburst !== tx.user_burst) begin
                    `uvm_error("SBD_AWBURST",$sformatf("Burst mismatch! Expected: 2'b%b, Got: 2'b%b",tx.user_burst, tx.m_axi_awburst))
                     m_axi_common::mismatch++;
                end
                else m_axi_common::match++;

                // Length calculation check
                start_offset = tx.user_start_addr[1:0];
                total_bytes  = tx.user_total_bytes + start_offset;
                expected_len = ((total_bytes + 4 - 1) / 4) - 1;

                if (tx.m_axi_awlen !== expected_len) begin
                    `uvm_error("SBD_AWLEN",$sformatf("AWLEN mismatch! Expected: %0d, Got: %0d",expected_len, tx.m_axi_awlen))
                    m_axi_common::mismatch++;
                end
                else m_axi_common::match++;

                start_wstrb_mask   = 4'b1111 << start_offset;
                expected_beat0_strb = tx.user_tx_wstrb[0] & start_wstrb_mask;

                // Verify Beat 0 Strobe
                if (tx.m_axi_wstrb !== expected_beat0_strb) begin
                    `uvm_error("SBD_WSTRB_BEAT[0]",$sformatf("Beat 0 Strobe Mismatch! Expected: 4'b%b, Got: 4'b%b",expected_beat0_strb, tx.m_axi_wstrb))
                    m_axi_common::mismatch++;
                end
                else m_axi_common::match++;

                // Verify Data Payload matching
                if (tx.m_axi_wdata !== tx.user_tx_data[0]) begin
                    `uvm_error("SBD_WDATA",$sformatf("Write data mismatch! Expected: 32'h%h, Got: 32'h%h",tx.user_tx_data[0], tx.m_axi_wdata))
                    m_axi_common::mismatch++;
                end
                else begin
                    `uvm_info("SBD_WDATA","Write data matches correctly.", UVM_MEDIUM)
                    m_axi_common::match++;
                end

                // Verify successful transaction completion
                if (tx.write_complete && !tx.write_error) begin
                    `uvm_info("SBD_PASS","Write transaction verified successfully.", UVM_LOW)
                    m_axi_common::match++;
                end
                else if (tx.write_error) begin
                    `uvm_error("SBD_FAIL","Write transaction failed on AXI bus response!")
                    m_axi_common::mismatch++;
                end

            end
            else begin : CHECK_READ_TRANSACTION

                if (tx.m_axi_araddr !== tx.user_start_addr) begin
                    `uvm_error("SBD_ARADDR",$sformatf("Read address mismatch! Expected: 32'h%h, Got: 32'h%h",tx.user_start_addr, tx.m_axi_araddr))
                    m_axi_common::mismatch++;
                end
                else m_axi_common::match++;

                if (tx.read_error) begin
                    `uvm_error("SBD_FAIL","Read transaction failed on AXI bus response!")
                    m_axi_common::mismatch++;
                end
                else begin
                    `uvm_info("SBD_PASS","Read transaction verified successfully.", UVM_LOW)
                    m_axi_common::match++;
                end

            end
        end
    endtask
endclass
