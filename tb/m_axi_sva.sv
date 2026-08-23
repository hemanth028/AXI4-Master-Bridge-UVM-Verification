module m_axi_sva #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire                  clk,
    input wire                  rst_n,

    // AXI Interface Signals (Sampled passively)
    input wire                  m_axi_awvalid,
    input wire                  m_axi_awready,
    input wire [ADDR_WIDTH-1:0] m_axi_awaddr,
    input wire [7:0]            m_axi_awlen,
    input wire [2:0]            m_axi_awsize,
    input wire [1:0]            m_axi_awburst,

    input wire                  m_axi_wvalid,
    input wire                  m_axi_wready,
    input wire [DATA_WIDTH-1:0] m_axi_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    input wire                  m_axi_wlast,

    input wire                  m_axi_arvalid,
    input wire                  m_axi_arready,
    input wire [ADDR_WIDTH-1:0] m_axi_araddr,
    input wire [7:0]            m_axi_arlen,
    input wire [2:0]            m_axi_arsize,
    input wire [1:0]            m_axi_arburst,

    input wire                  m_axi_bvalid,
    input wire                  m_axi_bready,
    input wire [1:0]            m_axi_bresp,

    input wire                  m_axi_rvalid,
    input wire                  m_axi_rready,
    input wire [DATA_WIDTH-1:0] m_axi_rdata,
    input wire [1:0]            m_axi_rresp,
    input wire                  m_axi_rlast,

    // Internal design wires accessed via bind [1]
    input wire                  raw_hazard,
    input wire                  aw_cmd_push,
    input wire                  aw_cmd_pop,
    input wire                  aw_cmd_full,
    input wire                  aw_cmd_empty
);
	default clocking def_clk @(posedge clk);
	endclocking

// checking whether the signals stay stable till aw_ready signal once valid is high.
	property aw_stability;
		disable iff (!rst_n)
		(m_axi_awvalid && (!m_axi_awready))|=>(m_axi_awvalid && $stable(m_axi_awaddr) && $stable(m_axi_awlen) && $stable(m_axi_awsize) && $stable(m_axi_awburst));
	endproperty

	assert_aw_stability:assert property (aw_stability)
		else $error("SVA ERROR:aw signals not stable !!!!!!");

//checking the wlast
	property p_wlast_assert;
  	  @(posedge clk) disable iff (!rst_n)
  (m_axi_wvalid && m_axi_wready && (dut.w_driver_inst.beat_counter == dut.w_driver_inst.cmd_axi_len)) |->m_axi_wlast;
	endproperty
	
	assert_wlast: assert property (p_wlast_assert)
	//	$display("beat_counter=%d",dut.w_driver_inst.beat_counter);
		else $error("SVA ERROR: WLAST mismatch!!!!!");


// End address calculation = Start Address + (Length * Width in Bytes)
wire [ADDR_WIDTH-1:0] aw_end_addr = m_axi_awaddr + (m_axi_awlen << m_axi_awsize);

	property aw_4kb_crossing;
    	@(posedge clk) disable iff (!rst_n)
   		m_axi_awvalid |-> (m_axi_awaddr[31:12] == aw_end_addr[31:12]);
	endproperty
	
	assert_aw_4kb_crossing: assert property (aw_4kb_crossing)
		//$display("within the 4KB boundary......");
		else $error("SVA ERROR:4KB Boundary !!!!");
	
	property ar_stability;
    @(posedge clk) disable iff (!rst_n)
    	(m_axi_arvalid && !m_axi_arready) |=>(m_axi_arvalid && $stable(m_axi_araddr) && $stable(m_axi_arlen) && $stable(m_axi_arsize) && $stable(m_axi_arburst));
	endproperty
	assert_ar_stability: assert property (ar_stability)
   		 else $error("SVA ERROR: AR address or control signals changed prematurely!");

	property b_stability;
    @(posedge clk) disable iff (!rst_n)
    	(m_axi_bvalid && !m_axi_bready) |=> (m_axi_bvalid && $stable(m_axi_bresp));
	endproperty
	assert_b_stability: assert property (b_stability)
  		  else $error("SVA ERROR: BVALID asserted but BRESP changed or deasserted prematurely!");

	property r_stability;
    	@(posedge clk) disable iff (!rst_n)
    	(m_axi_rvalid && !m_axi_rready) |=> (m_axi_rvalid && $stable(m_axi_rdata) && $stable(m_axi_rresp) && $stable(m_axi_rlast));
	endproperty
	assert_r_stability: assert property (r_stability)
    	else $error("SVA ERROR: RVALID asserted but read data or status changed prematurely!");

	property p_raw_hazard_stall;
  	  @(posedge clk) disable iff (!rst_n)
 	   raw_hazard |-> !m_axi_arvalid;
	endproperty
	assert_raw_hazard_stall: assert property (p_raw_hazard_stall)
    	else $error("SVA ERROR: m_axi_arvalid asserted during an active RAW address hazard!");

		// AW Command FIFO Overflow check [1]
	property p_aw_cmd_no_overflow;
	    @(posedge clk) disable iff (!rst_n)
	    aw_cmd_full |-> !aw_cmd_push;
	endproperty
	assert_aw_cmd_no_overflow: assert property (p_aw_cmd_no_overflow)
	    else $error("SVA ERROR: Write Command FIFO overflow detected (pushed while full)!");
	
	// AW Command FIFO Underflow check [1]
	property p_aw_cmd_no_underflow;
	    @(posedge clk) disable iff (!rst_n)
	    aw_cmd_empty |-> !aw_cmd_pop;
	endproperty
	assert_aw_cmd_no_underflow: assert property (p_aw_cmd_no_underflow)
	    else $error("SVA ERROR: Write Command FIFO underflow detected (popped while empty)!");
endmodule
