`include "sync_fifo.v"
`include "read_issuer.v"
`include "data_issuer.v"
`include "data_resposer.v"
`include "addr_splitter.v"
`include "addr_issuer.v"

module master_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter ID_VALUE   = 4'b0000,
    parameter FIFO_DEPTH = 16,
    parameter MAX_OUTSTANDING = 4
)(
    input  wire                      clk,
    input  wire                      rst_n,

    
    input  wire [ADDR_WIDTH-1:0]     user_start_addr,
    input  wire [31:0]               user_total_bytes,
    input  wire                      user_rnw,         
    input  wire                      user_cmd_valid,
    output wire                      user_cmd_ready,

    input  wire [DATA_WIDTH-1:0]     user_tx_data,
    input  wire                      user_tx_valid,
    input  wire [(DATA_WIDTH/8)-1:0] user_tx_wstrb,
    output wire                      user_tx_ready, 
    input wire 	[1:0] 				 user_burst,  

    // RX Data Stream (User reads received data here)
    output wire [DATA_WIDTH-1:0]     user_rx_data,
    output wire                      user_rx_valid,   // Connected to !RX_FIFO_EMPTY
    input  wire                      user_rx_ready,

    // Status Out
    output wire                      write_complete,  // Pulse indicating write complete
    output wire                      write_error,     // Latched write error
    output wire                      read_error,      // Latched read error

    output wire [ID_WIDTH-1:0]       m_axi_awid,
    output wire [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output wire [7:0]                m_axi_awlen,
    output wire [2:0]                m_axi_awsize,
    output wire [1:0]                m_axi_awburst,
    output wire [3:0]                m_axi_awcache,
    output wire [2:0]                m_axi_awprot,
    output wire                      m_axi_awvalid,
    input  wire                      m_axi_awready,

    // Write Data Channel (W)
    output wire [DATA_WIDTH-1:0]     m_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output wire                      m_axi_wlast,
    output wire                      m_axi_wvalid,
    input  wire                      m_axi_wready,

    // Write Response Channel (B)
    input  wire [ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output wire                      m_axi_bready,

    // Read Address Channel (AR)
    output wire [ID_WIDTH-1:0]       m_axi_arid,
    output wire [ADDR_WIDTH-1:0]     m_axi_araddr,
    output wire [7:0]                m_axi_arlen,
    output wire [2:0]                m_axi_arsize,
    output wire [1:0]                m_axi_arburst,
    output wire [3:0]                m_axi_arcache,
    output wire [2:0]                m_axi_arprot,
    output wire                      m_axi_arvalid,
    input  wire                      m_axi_arready,

    // Read Data Channel (R)
    input  wire [ID_WIDTH-1:0]       m_axi_rid,
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output wire                      m_axi_rready
);

    // =========================================================================
    // INTERNAL WIRE DECLARATIONS (Wiring Loom)
    // =========================================================================
    // Splitter Outputs
    wire                  split_cmd_valid;
    wire [ADDR_WIDTH-1:0] split_cmd_addr;
    wire [7:0]            split_cmd_axi_len;
    wire                  split_cmd_wr_rd;
    wire  [2:0]             split_cmd_offset;

    // FIFO Full/Empty Status Signals
    wire                  aw_cmd_full,  aw_cmd_empty;
    wire                  ar_cmd_full,  ar_cmd_empty;
    wire                  w_cmd_full,   w_cmd_empty;
    wire                  tx_data_full, tx_data_empty;
    wire                  rx_data_full, rx_data_empty;

    // FIFO Bundled outputs 
    wire [ADDR_WIDTH+12:0] aw_cmd_data_out; // 32 + 8 + 3+2
    wire [ADDR_WIDTH+12:0] ar_cmd_data_out; // 32 + 8 + 3 +2
    wire [10:0]            w_cmd_fifo_out;  // 8 + 3 
    wire [DATA_WIDTH-1:0]  tx_data_out;
    wire [DATA_WIDTH-1:0]  rx_data_in;
    
    // Decoupled FIFO Pop/Write Signals
    wire                  aw_cmd_pop;
    wire                  ar_cmd_pop;
    wire                  w_cmd_pop;
    wire                  tx_data_pop;
    wire                  rx_data_wr_en;
    wire [1:0] split_cmd_burst;

    wire                  aw_cmd_push = split_cmd_valid && (!split_cmd_wr_rd);
    wire                  w_cmd_push  = split_cmd_valid && (!split_cmd_wr_rd);
    wire                  ar_cmd_push = split_cmd_valid && split_cmd_wr_rd;

    // Block Splitter if the targeted FIFO runs out of space
    wire splitter_fifo_full = user_rnw ? ar_cmd_full : (aw_cmd_full || w_cmd_full);

    // Unpack Command FIFO Outputs
    wire [ADDR_WIDTH-1:0] aw_cmd_addr_out = aw_cmd_data_out[ADDR_WIDTH+12:13];//44:13
    wire [7:0]            aw_cmd_len_out  = aw_cmd_data_out[12:5];
    wire [2:0]            aw_cmd_offset_out = aw_cmd_data_out[4:2];// 4:2
    wire [1:0]            aw_cmd_burst_out  = aw_cmd_data_out[1:0]; // Bits 1:0 
    
    wire [ADDR_WIDTH-1:0] ar_cmd_addr_out = ar_cmd_data_out[ADDR_WIDTH+12:13];
    wire [7:0]            ar_cmd_len_out  = ar_cmd_data_out[12:5];
    wire [2:0]            ar_cmd_offset_out = ar_cmd_data_out[4:2];
    wire [1:0]            ar_cmd_burst_out  = ar_cmd_data_out[1:0];
         
    wire [7:0]            w_cmd_axi_len     = w_cmd_fifo_out[10:3];              // 10:3
    wire [2:0]            w_cmd_offset      = w_cmd_fifo_out[2:0];  
    wire [(DATA_WIDTH/8)-1:0]tx_wstrb_out ;
    // Status Out signals
    assign user_tx_ready = !tx_data_full;
    assign user_rx_valid = !rx_data_empty;
    
    // FOR RAW(READ BEFORE WRITE)HAZARD
    reg write_is_active;
    reg [ADDR_WIDTH-1:0] active_write_addr;
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            write_is_active<=1'b0;
            active_write_addr<=1'b0;
        end
        else begin
            if(aw_cmd_pop)begin   // pop from cmd fifo of ar channel(i.e write is active)//before ar_cmd_pop
                write_is_active<=1'b1;
                active_write_addr<=aw_cmd_addr_out;
            end
            else if(write_complete) begin
                write_is_active<=1'b0;
            end
        end
    end
    
    // if the next read address matches
    wire hazard_same_addr = (!aw_cmd_empty) && (ar_cmd_addr_out == aw_cmd_addr_out);
    wire hazard_active_write = write_is_active && (ar_cmd_addr_out == active_write_addr);
    
    // Hazard is active if the read address conflicts with either write state
    wire raw_hazard = (hazard_same_addr || hazard_active_write) && (!ar_cmd_empty);
    
    // =========================================================================
    // OUTSTANDING TRANSACTION TRACKING & THROTTLING LOGIC [1]
    // =========================================================================
    // Size the counter to fit MAX_OUTSTANDING values
    localparam CTR_WIDTH = $clog2(MAX_OUTSTANDING + 1);

    reg [CTR_WIDTH-1:0] outstding_wrs;
    reg [CTR_WIDTH-1:0] outstding_rds;
    
    wire rd_comp; // Connected to R-receiver's burst completion pulse

    // Write Outstanding Tracker [1]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            outstding_wrs <= 0;
        end else begin
            case ({aw_cmd_pop, write_complete})
                2'b10: outstding_wrs <= outstding_wrs + 1'b1; // New write issued
                2'b01: outstding_wrs <= outstding_wrs - 1'b1; // Write completed
                default: ; // No change (00 or concurrent 11)
            endcase
        end
    end

    // Read Outstanding Tracker [1]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            outstding_rds <= 0;
        end else begin
            case ({ar_cmd_pop, rd_comp})
                2'b10: outstding_rds <= outstding_rds + 1'b1; // New read issued
                2'b01: outstding_rds <= outstding_rds - 1'b1; // Read burst completed
                default: ; // No change (00 or concurrent 11)
            endcase
        end
    end

    // Stall signals trigger when outstanding count hits the maximum allowed limit [1]
    wire aw_stall = (outstding_wrs == MAX_OUTSTANDING);
    wire ar_stall = (outstding_rds  == MAX_OUTSTANDING);
    // =======================================================================
    // SUB-MODULE INSTANTIATIONS
    // =========================================================================

    // 1. Transaction Splitter (The Brain)
    transaction_splitter #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .BYTES      (DATA_WIDTH / 8)
    ) splitter_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .start_addr       (user_start_addr),
        .full_bytes         (user_total_bytes),
        .wr_rd            (user_rnw),
        .valid            (user_cmd_valid),
        .ready            (user_cmd_ready),
        .fifo_full        (splitter_fifo_full),
        .user_burst       (user_burst),
        .cmd_valid        (split_cmd_valid),
        .cmd_addr         (split_cmd_addr),
        .cmd_axi_len      (split_cmd_axi_len),
        .cmd_offset       (split_cmd_offset),
        .cmd_wr_rd        (split_cmd_wr_rd),
        .cmd_burst        (split_cmd_burst)
    );

    // 2. Command & Data FIFOs (Encapsulated Storage)
    
    // Write Command FIFO (Address + Length bundled)
    sync_fifo #(
        .DATA_WIDTH (ADDR_WIDTH + 8+3+2),//addr,len,offset(unaligned transfer),burst type
        .DEPTH      (FIFO_DEPTH)
    ) aw_cmd_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .write_en (aw_cmd_push),
        .read_en  (aw_cmd_pop),
        .data_in  ({split_cmd_addr, split_cmd_axi_len, split_cmd_offset,split_cmd_burst}),
        .data_out (aw_cmd_data_out),
        .full     (aw_cmd_full),
        .empty    (aw_cmd_empty)
    );

    // Read Command FIFO (Address + Length bundled)
    sync_fifo #(
        .DATA_WIDTH (ADDR_WIDTH + 8+3+2),
        .DEPTH      (FIFO_DEPTH)
    ) ar_cmd_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .write_en (ar_cmd_push),
        .read_en  (ar_cmd_pop),
        .data_in  ({split_cmd_addr, split_cmd_axi_len, split_cmd_offset,split_cmd_burst}),
        .data_out (ar_cmd_data_out),
        .full     (ar_cmd_full),
        .empty    (ar_cmd_empty)
    );

    // Write Length FIFO (For W-Channel synchronization)
    sync_fifo #(
        .DATA_WIDTH (8+3),
        .DEPTH      (FIFO_DEPTH)
    ) w_cmd_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .write_en (w_cmd_push),
        .read_en  (w_cmd_pop),
        .data_in  ({split_cmd_axi_len, split_cmd_offset}),
         .data_out (w_cmd_fifo_out),
        .full     (w_cmd_full),
        .empty    (w_cmd_empty)
    );

    // TX Data FIFO (Stores outgoing user data payload)
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH +(DATA_WIDTH/8)),
        .DEPTH      (FIFO_DEPTH)
    ) tx_data_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .write_en (user_tx_valid),
        .read_en  (tx_data_pop),
        .data_in  ({user_tx_data,user_tx_wstrb}),
        .data_out ({tx_data_out,tx_wstrb_out}),
        .full     (tx_data_full),
        .empty    (tx_data_empty)
    );

    // RX Data FIFO (Stores incoming bus data payload)
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) rx_data_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .write_en (rx_data_wr_en),
        .read_en  (user_rx_ready),
        .data_in  (rx_data_in),
        .data_out (),
        .full     (rx_data_full),
        .empty    (rx_data_empty)
    );
assign user_rx_data=rx_data_in;
    // 3. Address Channel Drivers (AW & AR Issuers)
    
    // Write Address Driver (AW Channel)
    addr_issuer #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .ID_VALUE   (ID_VALUE)
    ) aw_driver_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .fifo_empty  (aw_cmd_empty || aw_stall),
        .cmd_addr    (aw_cmd_addr_out),
        .cmd_axi_len (aw_cmd_len_out),
        .fifo_pop    (aw_cmd_pop),
        .cmd_burst   (aw_cmd_burst_out),
        .AXID        (m_axi_awid),
        .AXVALID     (m_axi_awvalid),
        .AXREADY     (m_axi_awready),
        .AXADDR      (m_axi_awaddr),
        .AXLEN       (m_axi_awlen),
        .AXSIZE      (m_axi_awsize),
        .AXBURST     (m_axi_awburst),
        .AXCACHE     (m_axi_awcache),
        .AXPROT      (m_axi_awprot)
    );

    // Read Address Driver (AR Channel)
    addr_issuer #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .ID_VALUE   (ID_VALUE)
    ) ar_driver_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .fifo_empty  (ar_cmd_empty || raw_hazard|| ar_stall),           //Stall AR if RAW hazard exists
        .cmd_addr    (ar_cmd_addr_out),
        .cmd_axi_len (ar_cmd_len_out),
        .fifo_pop    (ar_cmd_pop),
        .cmd_burst   (ar_cmd_burst_out),
        .AXID        (m_axi_arid),
        .AXVALID     (m_axi_arvalid),
        .AXREADY     (m_axi_arready),
        .AXADDR      (m_axi_araddr),
        .AXLEN       (m_axi_arlen),
        .AXSIZE      (m_axi_arsize),
        .AXBURST     (m_axi_arburst),
        .AXCACHE     (m_axi_arcache),
        .AXPROT      (m_axi_arprot)
    );

    // 4. Outbound Data Driver (W Channel Issuer)
    axi_w_issuer #(
        .DATA_WIDTH (DATA_WIDTH)
    ) w_driver_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .fifo_cmd_empty  (w_cmd_empty),
        .cmd_axi_len     (w_cmd_axi_len),
        .fifo_cmd_pop    (w_cmd_pop),
        .fifo_data_empty (tx_data_empty),       
        .tx_data         (tx_data_out),
        .tx_wstrb        (tx_wstrb_out),
        .cmd_offset      (w_cmd_offset),
        .fifo_data_pop   (tx_data_pop),
        .WVALID          (m_axi_wvalid),
        .WREADY          (m_axi_wready),
        .WDATA           (m_axi_wdata),
        .WSTRB           (m_axi_wstrb),
        .WLAST           (m_axi_wlast)
    );

    // 5. Inbound Data Receiver (R Channel Receiver)
    axi_r_receiver #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) r_receiver_inst (
        .clk               (clk),
        .rst_n             (rst_n),
        .fifo_full         (rx_data_full),
        .fifo_wr_en        (rx_data_wr_en),
        .fifo_data         (rx_data_in),
        .RID               (m_axi_rid),
        .RDATA             (m_axi_rdata),
        .RRESP             (m_axi_rresp),
        .RLAST             (m_axi_rlast),
        .RVALID            (m_axi_rvalid),
        .RREADY            (m_axi_rready),
        .read_burst_done   (rd_comp), // Left floating (handled at system-level if needed)
        .read_error_stick  (read_error)
    );

    // 6. Write Response Receiver (B Channel Receiver)
    data_response #(
        .ID_WIDTH (ID_WIDTH)
    ) b_receiver_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .BVALID          (m_axi_bvalid),
        .BRESP           (m_axi_bresp),
        .BID             (m_axi_bid),
        .BREADY          (m_axi_bready),
        .wr_burst_done   (write_complete),
        .wr_error_sticky (write_error)
    );

endmodule
