class m_axi_tx extends uvm_sequence_item;

       	`NEW_OBJ	

    // User-Side Inputs
    rand bit [`ADDR_WIDTH-1:0]     user_start_addr;
    rand bit [31:0]               user_total_bytes;
    rand bit                      user_rnw;
    rand bit                      user_cmd_valid;
    rand bit [1:0]                user_burst;
    rand bit                      user_rx_ready;
    
    // User-Side Write Data Stream Inputs
    rand bit [`DATA_WIDTH-1:0]     user_tx_data[];//because we have randomized it in a dynamic array way
    rand bit                      user_tx_valid;
    rand bit [(`DATA_WIDTH/8)-1:0] user_tx_wstrb;

    // AXI Bus Response/Slave Inputs (Simulated by the slave agent)
    bit                      	  m_axi_awready;
    rand bit                      m_axi_wready;
    rand bit [`ID_WIDTH-1:0]       m_axi_bid;
    rand bit [1:0]                m_axi_bresp;
    rand bit                      m_axi_bvalid;
    rand bit                      m_axi_arready;
    rand bit [`ID_WIDTH-1:0]       m_axi_rid;
    rand bit [`DATA_WIDTH-1:0]     m_axi_rdata;
    rand bit [1:0]                m_axi_rresp;
    rand bit                      m_axi_rlast;
    rand bit                      m_axi_rvalid;

    // =========================================================================
    // 2. OUTPUT PROPERTIES (Signals captured/read from the DUT) [2]
    // =========================================================================
    
    // User-Side Outputs
         bit                      user_cmd_ready;
         bit                      user_tx_ready;
         bit                      user_rx_valid;
         bit [`DATA_WIDTH-1:0]     user_rx_data[];

    // Status Outputs
         bit                      write_complete;
         bit                      write_error;
         bit                      read_error;

    // AXI Bus  Outputs (Driven by the DUT)
         bit [`ID_WIDTH-1:0]       m_axi_awid;
         bit [`ADDR_WIDTH-1:0]     m_axi_awaddr;
         bit [7:0]                m_axi_awlen;
         bit [2:0]                m_axi_awsize;
         bit [1:0]                m_axi_awburst;
         bit [3:0]                m_axi_awcache;
         bit [2:0]                m_axi_awprot;
         bit                      m_axi_awvalid;

         bit [`DATA_WIDTH-1:0]     m_axi_wdata;
         bit [(`DATA_WIDTH/8)-1:0] m_axi_wstrb;
         bit                      m_axi_wlast;
         bit                      m_axi_wvalid;
         bit                      m_axi_bready;

         bit [`ID_WIDTH-1:0]       m_axi_arid;
         bit [`ADDR_WIDTH-1:0]     m_axi_araddr;
         bit [7:0]                m_axi_arlen;	
         bit [2:0]                m_axi_arsize;
         bit [1:0]                m_axi_arburst;
         bit [3:0]                m_axi_arcache;
         bit [2:0]                m_axi_arprot;
         bit                      m_axi_arvalid;
         bit                      m_axi_rready;
	constraint byte_limit {
       	 user_total_bytes inside {[1:128]}; 
    }

    constraint valid_burst {
        user_burst inside {2'b00, 2'b01, 2'b10};
    }

    // Auto-sizes input data arrays to match the requested transfer size [2]
    constraint tx_data_size {
        user_tx_data.size()  == ((user_total_bytes + (`DATA_WIDTH/8) - 1) / (`DATA_WIDTH/8));
      //  user_tx_wstrb.size() == user_tx_data.size();
    }
	
      `uvm_object_utils_begin(m_axi_tx)
        // Input
        `uvm_field_int(user_start_addr,   UVM_ALL_ON)
        `uvm_field_int(user_total_bytes,  UVM_ALL_ON)
        `uvm_field_int(user_rnw,          UVM_ALL_ON)
        `uvm_field_int(user_cmd_valid,    UVM_ALL_ON)
        `uvm_field_int(user_burst,        UVM_ALL_ON)
        `uvm_field_int(user_rx_ready,     UVM_ALL_ON)
        `uvm_field_array_int(user_tx_data,      UVM_ALL_ON)//since dynamic array
        `uvm_field_int(user_tx_valid,     UVM_ALL_ON)
        `uvm_field_int(user_tx_wstrb,     UVM_ALL_ON)
        `uvm_field_int(m_axi_awready,     UVM_ALL_ON)
        `uvm_field_int(m_axi_wready,      UVM_ALL_ON)
        `uvm_field_int(m_axi_bid,         UVM_ALL_ON)
        `uvm_field_int(m_axi_bresp,       UVM_ALL_ON)
        `uvm_field_int(m_axi_bvalid,      UVM_ALL_ON)
        `uvm_field_int(m_axi_arready,     UVM_ALL_ON)
        `uvm_field_int(m_axi_rid,         UVM_ALL_ON)
        `uvm_field_int(m_axi_rdata,       UVM_ALL_ON)
        `uvm_field_int(m_axi_rresp,       UVM_ALL_ON)
        `uvm_field_int(m_axi_rlast,       UVM_ALL_ON)
        `uvm_field_int(m_axi_rvalid,      UVM_ALL_ON)
        // Output
        `uvm_field_int(user_cmd_ready,    UVM_ALL_ON)
        `uvm_field_int(user_tx_ready,     UVM_ALL_ON)
        `uvm_field_int(user_rx_valid,     UVM_ALL_ON)
        `uvm_field_array_int(user_rx_data,      UVM_ALL_ON)
        `uvm_field_int(write_complete,    UVM_ALL_ON)
        `uvm_field_int(write_error,       UVM_ALL_ON)
        `uvm_field_int(read_error,        UVM_ALL_ON)
        `uvm_field_int(m_axi_awid,        UVM_ALL_ON)
        `uvm_field_int(m_axi_awaddr,      UVM_ALL_ON)
        `uvm_field_int(m_axi_awlen,       UVM_ALL_ON)
        `uvm_field_int(m_axi_awsize,      UVM_ALL_ON)
        `uvm_field_int(m_axi_awburst,     UVM_ALL_ON)
        `uvm_field_int(m_axi_awcache,     UVM_ALL_ON)
        `uvm_field_int(m_axi_awprot,      UVM_ALL_ON)
        `uvm_field_int(m_axi_awvalid,     UVM_ALL_ON)
        `uvm_field_int(m_axi_wdata,       UVM_ALL_ON)
        `uvm_field_int(m_axi_wstrb,       UVM_ALL_ON)
        `uvm_field_int(m_axi_wlast,       UVM_ALL_ON)
        `uvm_field_int(m_axi_wvalid,      UVM_ALL_ON)
        `uvm_field_int(m_axi_bready,      UVM_ALL_ON)
        `uvm_field_int(m_axi_arid,        UVM_ALL_ON)
        `uvm_field_int(m_axi_araddr,      UVM_ALL_ON)
        `uvm_field_int(m_axi_arlen,       UVM_ALL_ON)
        `uvm_field_int(m_axi_arsize,      UVM_ALL_ON)
        `uvm_field_int(m_axi_arburst,     UVM_ALL_ON)
        `uvm_field_int(m_axi_arcache,     UVM_ALL_ON)
        `uvm_field_int(m_axi_arprot,      UVM_ALL_ON)
        `uvm_field_int(m_axi_arvalid,     UVM_ALL_ON)
        `uvm_field_int(m_axi_rready,      UVM_ALL_ON)
    `uvm_object_utils_end


endclass
