interface m_axi_intf(input bit ACLK,input bit ARESET_n);

    // =========================================================================
    // PHYSICAL WIRE DECLARATIONS
    // =========================================================================
    // User Command Interface
    logic [`ADDR_WIDTH-1:0]     user_start_addr;
    logic [31:0]               user_total_bytes;
    logic                      user_rnw;
    logic [1:0]                user_burst;
    logic                      user_cmd_valid;
    logic                      user_cmd_ready;

    // User Write Data Interface
    logic [`DATA_WIDTH-1:0]     user_tx_data;
    logic                      user_tx_valid;
    logic [(`DATA_WIDTH/8)-1:0] user_tx_wstrb;
    logic                      user_tx_ready;

    // User Read Data Interface
    logic [`DATA_WIDTH-1:0]     user_rx_data;
    logic                      user_rx_valid;
    logic                      user_rx_ready;

    // Status Signals
    logic                      write_complete;
    logic                      write_error;
    logic                      read_error;

    // AXI AW Channel
    logic [`ID_WIDTH-1:0]       m_axi_awid;
    logic [`ADDR_WIDTH-1:0]     m_axi_awaddr;
    logic [7:0]                m_axi_awlen;
    logic [2:0]                m_axi_awsize;
    logic [1:0]                m_axi_awburst;
    logic [3:0]                m_axi_awcache;
    logic [2:0]                m_axi_awprot;
    logic                      m_axi_awvalid;
    logic                      m_axi_awready;

    // AXI W Channel
    logic [`DATA_WIDTH-1:0]     m_axi_wdata;
    logic [(`DATA_WIDTH/8)-1:0] m_axi_wstrb;
    logic                      m_axi_wlast;
    logic                      m_axi_wvalid;
    logic                      m_axi_wready;

    // AXI B Channel
    logic [`ID_WIDTH-1:0]       m_axi_bid;
    logic [1:0]                m_axi_bresp;
    logic                      m_axi_bvalid;
    logic                      m_axi_bready;

    // AXI AR Channel
    logic [`ID_WIDTH-1:0]       m_axi_arid;
    logic [`ADDR_WIDTH-1:0]     m_axi_araddr;
    logic [7:0]                m_axi_arlen;
    logic [2:0]                m_axi_arsize;
    logic [1:0]                m_axi_arburst;
    logic [3:0]                m_axi_arcache;
    logic [2:0]                m_axi_arprot;
    logic                      m_axi_arvalid;
    logic                      m_axi_arready;

    // AXI R Channel
    logic [`ID_WIDTH-1:0]       m_axi_rid;
    logic [`DATA_WIDTH-1:0]     m_axi_rdata;
    logic [1:0]                m_axi_rresp;
    logic                      m_axi_rlast;
    logic                      m_axi_rvalid;
    logic                      m_axi_rready;


    // =========================================================================
    // DRIVER CLOCKING BLOCK (drv_cb)
    // =========================================================================
    clocking drv_cb @(posedge ACLK);
        // Timing skew: sample 1ns before posedge, drive 1ns after posedge
        default input #1ns output #1ns; 
        // Outputs driven by the Driver to the DUT
        output user_start_addr, user_total_bytes, user_rnw, user_burst, user_cmd_valid;
        output user_tx_data, user_tx_valid, user_tx_wstrb, user_rx_ready;

        // Inputs sampled by the Driver from the DUT
        input  user_cmd_ready, user_tx_ready, user_rx_valid, user_rx_data;
        input  write_complete, write_error, read_error;

        // Slave Simulation Interface (Driven by the testbench slave agent)
        output m_axi_awready, m_axi_wready, m_axi_bvalid, m_axi_bid, m_axi_bresp;
        output m_axi_arready, m_axi_rvalid, m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast;

        // Master outputs (Sampled by the testbench slave agent)
        input  m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize, m_axi_awburst, m_axi_awcache, m_axi_awprot, m_axi_awvalid;
        input  m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_wvalid, m_axi_bready;
        input  m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arcache, m_axi_arprot, m_axi_arvalid, m_axi_rready;
    endclocking


    // =========================================================================
    // MONITOR CLOCKING BLOCK (mon_cb)
    // =========================================================================
    clocking mon_cb @(posedge ACLK);
        default input #1ns output #1ns;

        // The Monitor is purely passive; all signals are inputs
        input user_start_addr, user_total_bytes, user_rnw, user_burst, user_cmd_valid, user_cmd_ready;
        input user_tx_data, user_tx_valid, user_tx_wstrb, user_tx_ready;
        input user_rx_data, user_rx_valid, user_rx_ready;
        input write_complete, write_error, read_error;

        input m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize, m_axi_awburst, m_axi_awcache, m_axi_awprot, m_axi_awvalid, m_axi_awready;
        input m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_wvalid, m_axi_wready;
        input m_axi_bid, m_axi_bresp, m_axi_bvalid, m_axi_bready;
        input m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arcache, m_axi_arprot, m_axi_arvalid, m_axi_arready;
        input m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_rvalid, m_axi_rready;
    endclocking

endinterface
