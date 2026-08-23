/*module addr_issuer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,  // Used to calculate AXSIZE
    parameter ID_WIDTH   = 4,   // AXI Transaction ID width
    parameter ID_VALUE   = 4'b0000
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // --- FIFO Interface ---
    input  wire                    fifo_empty,
    input  wire [ADDR_WIDTH-1:0]   cmd_addr,     // Corrected width
    input  wire [7:0]              cmd_axi_len,  // Corrected width
    output reg                     fifo_pop,     // Corrected to Output

    // --- AXI Interface ---
    output wire [ID_WIDTH-1:0]     AXID,         
    output reg                     AXVALID,
    input  wire                    AXREADY,
    output reg  [ADDR_WIDTH-1:0]   AXADDR,
    output reg  [7:0]              AXLEN,        // Corrected: 8-bit width (0-255)
    output wire [2:0]              AXSIZE,       // Corrected: 3-bit width
    output wire [1:0]              AXBURST,      // Corrected: 2-bit width
    output wire [3:0]              AXCACHE,      // Corrected: 4-bit width
    output wire [2:0]              AXPROT        // Corrected: 3-bit width
);

    // AXSIZE calculation: 32-bit (4 bytes) -> size 2 (2^2)
    assign AXSIZE  = $clog2(DATA_WIDTH / 8);

    // Static AXI parameters
    assign AXID    = ID_VALUE;
    assign AXBURST = 2'b01;   // INCR (Incrementing burst)
    assign AXCACHE = 4'b0011; // Bufferable/Modifiable
    assign AXPROT  = 3'b000;  // Secure, Data, Unprivileged

    // FSM States
    localparam IDLE       = 1'b0;
    localparam WAIT_READY = 1'b1;

    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            fifo_pop <= 1'b0;
            AXVALID  <= 1'b0;
            AXADDR   <= 0;
            AXLEN    <= 0;
        end else begin
            // Default: clear the single-cycle pop pulse
           // fifo_pop <= 1'b0;

            case (state)
                IDLE: begin
                    // If the FIFO has a command, grab it and go VALID immediately
                  //  if (!fifo_empty) begin
                        fifo_pop = 1'b1; // Pop the FIFO for 1 cycle
                    //    AXADDR   <= cmd_addr;
                      //  AXLEN    <= cmd_axi_len; // Corrected from cmd_len to cmd_axi_len
                        AXVALID  <= 1'b1;
                        if(AXVALID &&AXREADY)
                            state    <= WAIT_READY; 
                    //end
                end

                WAIT_READY: begin
                    // Keep VALID high until READY is asserted
                        AXADDR   <= cmd_addr;
                        AXLEN    <= cmd_axi_len;
                    if (AXREADY ) begin
   
                        AXVALID <= 1'b0;
                         fifo_pop <= 1'b0;

                        state   <= IDLE; // Handshake complete
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
*/
module addr_issuer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,  // Used to calculate AXSIZE
    parameter ID_WIDTH   = 4,   // AXI Transaction ID width
    parameter ID_VALUE   = 4'b0000
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    // --- FIFO Interface ---
    input  wire                    fifo_empty,
    input  wire [ADDR_WIDTH-1:0]   cmd_addr,
    input  wire [7:0]              cmd_axi_len,
    output wire                    fifo_pop,     // Changed to wire
    input wire [1:0] cmd_burst,
    // --- AXI Interface ---
    output wire [ID_WIDTH-1:0]     AXID,         
    output wire                    AXVALID,      // Changed to wire
    input  wire                    AXREADY,
    output reg  [ADDR_WIDTH-1:0]   AXADDR,       // Changed to wire
    output reg  [7:0]              AXLEN,        // Changed to wire
    output wire [2:0]              AXSIZE,
    output wire [1:0]              AXBURST,
    output wire [3:0]              AXCACHE,
    output wire [2:0]              AXPROT
);

    // AXSIZE calculation: 32-bit (4 bytes) -> size 2 (2^2)
    assign AXSIZE  = $clog2(DATA_WIDTH / 8);

    // Static AXI parameters
    assign AXID    = ID_VALUE;
    assign AXBURST = cmd_burst; 
    assign AXCACHE = 4'b0011; // Bufferable/Modifiable
    assign AXPROT  = 3'b000;  // Secure, Data, Unprivileged

    // =========================================================================
    // Combinational Logic (Matching axi_w_issuer style)
    // =========================================================================
    
    // Valid is simply tied to the FIFO not being empty
    assign AXVALID = !fifo_empty;
    
  /*  // Address and Length directly pass through from the command FIFO
    assign AXADDR  = cmd_addr;
    assign AXLEN   = cmd_axi_len;*/

    // Handshake occurs when both VALID and READY are high
    wire ax_handshake = (AXVALID && AXREADY);
    reg start;
    // Pop the FIFO exactly when the AXI slave accepts the address
    assign fifo_pop = ax_handshake;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            AXADDR<=0;
            AXLEN<=0;
        end
        else if(ax_handshake)begin
            start=1'b1;
        end
        else if (start)begin
            AXADDR=cmd_addr;
            AXLEN=cmd_axi_len;
        end
    end
endmodule
