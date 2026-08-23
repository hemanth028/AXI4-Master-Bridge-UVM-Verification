module transaction_splitter #(
    parameter ADDR_WIDTH = 32,
    parameter BYTES      = 4    
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // --- User Interface ---
    input  wire [ADDR_WIDTH-1:0]  start_addr,
    input  wire [31:0]            full_bytes,  // Total BYTES to transfer
    input  wire                   wr_rd,     // 1=Read, 0=Write
    input  wire                   valid,
    output reg                    ready,
    input  wire [1:0]             user_burst, 

    // --- FIFO Status ---
    input  wire                   fifo_full,
    output reg                    cmd_valid,
    output reg  [ADDR_WIDTH-1:0]  cmd_addr,
    output reg  [7:0]             cmd_axi_len, // Beats - 1
    output reg                    cmd_wr_rd,
    output reg  [1:0]             cmd_burst,
    output reg  [2:0]             cmd_offset
);

    localparam IDLE  = 1'b0;
    localparam SPLIT = 1'b1;

    reg state;
    reg [ADDR_WIDTH-1:0] curr_addr;
    reg [31:0]           rem_bytes;
    reg                  rnw_reg;
    reg [1:0]            burst_reg;  

    
    wire [2:0] start_offset = start_addr[$clog2(BYTES)-1:0];//this points to the exact lane to start with    
    // Bytes remaining until the next 4KB boundary
    wire [12:0] bytes_to_4k = 4096 - curr_addr[11:0];

    // Max bytes in a single AXI burst (256 beats)
    wire [31:0] max_axi_bytes = 256 * BYTES;

    // Select the minimum of rem_bytes, bytes_to_4k, and max_axi_bytes
    wire [31:0] min_1 = (rem_bytes < bytes_to_4k) ? rem_bytes : bytes_to_4k;
    wire [31:0] burst_bytes = (min_1 < max_axi_bytes) ? min_1 : max_axi_bytes;
    wire [31:0] total_bytes = (state == IDLE) ? (burst_bytes + start_offset) : burst_bytes;//here we count the unalligned start (to calc beat count)
    // AxLEN signal calculation
  //  wire [7:0] calc_axi_len = (total_bytes / BYTES) - 1; faillin for odd no of bytes eg:9
      wire [7:0] calc_axi_len = ((total_bytes + BYTES - 1) / BYTES) - 1;    
      
      reg [2:0] start_offset_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            ready       <= 1'b1;
            cmd_valid   <= 1'b0;
            cmd_addr    <= 0;
            cmd_axi_len <= 0;
            cmd_wr_rd   <= 0;
            curr_addr   <= 0;
            rem_bytes   <= 0;
            rnw_reg     <= 0;
            start_offset_reg<=0;
            cmd_offset<=0;
        end else begin
            
            cmd_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (valid && ready) begin
                        curr_addr <= start_addr;
                        rem_bytes <= full_bytes;
                        rnw_reg   <= wr_rd;
                        start_offset_reg <= start_offset; 
                        burst_reg        <= user_burst; 
                        ready     <= 1'b0; 
                        state     <= SPLIT;
                    end
                end

                SPLIT: begin
                    if (!fifo_full) begin
                        cmd_valid   <= 1'b1;
                        cmd_addr    <= curr_addr;
                        cmd_axi_len <= calc_axi_len;
                        cmd_wr_rd   <= rnw_reg;
                        cmd_offset  <=start_offset_reg;
                        cmd_burst   <= burst_reg;  
                        if (burst_reg != 2'b00) begin
                            curr_addr <= curr_addr + burst_bytes;
                        end
                        rem_bytes <= rem_bytes - burst_bytes;
                        
                        // Optimized: Checks equality to save an adder circuit
                        if (rem_bytes == burst_bytes) begin
                            state <= IDLE;
                            ready <= 1'b1; 
                        end
                    end
                end
            endcase
        end
    end

endmodule

