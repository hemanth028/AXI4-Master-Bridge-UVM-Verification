//`timescale 1ns/1ps

module top;
    parameter ADDR_WIDTH      = 32;
    parameter DATA_WIDTH      = 32;
    parameter ID_WIDTH        = 4;
    parameter ID_VALUE        = 4'b0000;
    parameter FIFO_DEPTH      = 16;
    parameter MAX_OUTSTANDING = 4;

    bit ACLK;
    bit ARESET_n;

    m_axi_intf pif (ACLK, ARESET_n);
    
    always #5 ACLK = ~ACLK;

    master_top #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .ID_WIDTH        (ID_WIDTH),
        .ID_VALUE        (ID_VALUE),
        .FIFO_DEPTH      (FIFO_DEPTH),
        .MAX_OUTSTANDING (MAX_OUTSTANDING)
    ) dut (
        .clk              (ACLK),
        .rst_n            (ARESET_n),

        .user_start_addr  (pif.user_start_addr),
        .user_total_bytes (pif.user_total_bytes),
        .user_rnw         (pif.user_rnw),
        .user_burst       (pif.user_burst),
        .user_cmd_valid   (pif.user_cmd_valid),
        .user_cmd_ready   (pif.user_cmd_ready),

        .user_tx_data     (pif.user_tx_data),
        .user_tx_valid    (pif.user_tx_valid),
        .user_tx_wstrb    (pif.user_tx_wstrb),
        .user_tx_ready    (pif.user_tx_ready),

        .user_rx_data     (pif.user_rx_data),
        .user_rx_valid    (pif.user_rx_valid),
        .user_rx_ready    (pif.user_rx_ready),

        // Status Out [1]
        .write_complete   (pif.write_complete),
        .write_error      (pif.write_error),
        .read_error       (pif.read_error),

        // AXI Write Address Channel (AW) [1]
        .m_axi_awid       (pif.m_axi_awid),
        .m_axi_awaddr     (pif.m_axi_awaddr),
        .m_axi_awlen      (pif.m_axi_awlen),
        .m_axi_awsize     (pif.m_axi_awsize),
        .m_axi_awburst    (pif.m_axi_awburst),
        .m_axi_awcache    (pif.m_axi_awcache),
        .m_axi_awprot     (pif.m_axi_awprot),
        .m_axi_awvalid    (pif.m_axi_awvalid),
        .m_axi_awready    (pif.m_axi_awready),

        // AXI Write Data Channel (W) [1]
        .m_axi_wdata      (pif.m_axi_wdata),
        .m_axi_wstrb      (pif.m_axi_wstrb),
        .m_axi_wlast      (pif.m_axi_wlast),
        .m_axi_wvalid     (pif.m_axi_wvalid),
        .m_axi_wready     (pif.m_axi_wready),

        // AXI Write Response Channel (B) [1]
        .m_axi_bid        (pif.m_axi_bid),
        .m_axi_bresp      (pif.m_axi_bresp),
        .m_axi_bvalid     (pif.m_axi_bvalid),
        .m_axi_bready     (pif.m_axi_bready),

        // AXI Read Address Channel (AR) [1]
        .m_axi_arid       (pif.m_axi_arid),
        .m_axi_araddr     (pif.m_axi_araddr),
        .m_axi_arlen      (pif.m_axi_arlen),
        .m_axi_arsize     (pif.m_axi_arsize),
        .m_axi_arburst    (pif.m_axi_arburst),
        .m_axi_arcache    (pif.m_axi_arcache),
        .m_axi_arprot     (pif.m_axi_arprot),
        .m_axi_arvalid    (pif.m_axi_arvalid),
        .m_axi_arready    (pif.m_axi_arready),

        // AXI Read Data Channel (R) [1]
        .m_axi_rid        (pif.m_axi_rid),
        .m_axi_rdata      (pif.m_axi_rdata),
        .m_axi_rresp      (pif.m_axi_rresp),
        .m_axi_rlast      (pif.m_axi_rlast),
        .m_axi_rvalid     (pif.m_axi_rvalid),
        .m_axi_rready     (pif.m_axi_rready)
    );

      initial begin
        ACLK     = 0;
        ARESET_n = 0; // Assert active-low reset [1.2.7]
        repeat(3) @(posedge ACLK);
     //   @(negedge ACLK);
        ARESET_n = 1; // Release cleanly on falling clock edge [1.2.7]
    end

    initial begin
		uvm_config_db#(virtual m_axi_intf)::set(null, "*", "VIF", pif);
    end
    initial begin
        run_test("test_wr");
    end
bind master_top m_axi_sva #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .ID_WIDTH   (ID_WIDTH)
	) sva_inst (
    .clk             (clk),
    .rst_n           (rst_n),
    // AXI Port mappings [1]
    .m_axi_awvalid   (m_axi_awvalid),
    .m_axi_awready   (m_axi_awready),
    .m_axi_awaddr    (m_axi_awaddr),
    .m_axi_awlen     (m_axi_awlen),
    .m_axi_awsize    (m_axi_awsize),
    .m_axi_awburst   (m_axi_awburst),
    .m_axi_wvalid    (m_axi_wvalid),
    .m_axi_wready    (m_axi_wready),
    .m_axi_wdata     (m_axi_wdata),
    .m_axi_wstrb     (m_axi_wstrb),
    .m_axi_wlast     (m_axi_wlast),
    .m_axi_arvalid   (m_axi_arvalid),
    .m_axi_arready   (m_axi_arready),
    .m_axi_araddr    (m_axi_araddr),
    .m_axi_arlen     (m_axi_arlen),
    .m_axi_arsize    (m_axi_arsize),
    .m_axi_arburst   (m_axi_arburst),
    // Internal signal mappings [1]
    .raw_hazard      (raw_hazard),
    .aw_cmd_push     (aw_cmd_push),
    .aw_cmd_pop      (aw_cmd_pop),
    .aw_cmd_full     (aw_cmd_full),
    .aw_cmd_empty    (aw_cmd_empty)
);

endmodule
