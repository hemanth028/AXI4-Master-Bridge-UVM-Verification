module axi_w_issuer #(
    parameter DATA_WIDTH = 32
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      fifo_cmd_empty,
    input  wire [7:0]                cmd_axi_len,
    output wire                      fifo_cmd_pop,  

    input  wire                      fifo_data_empty,
    input  wire [DATA_WIDTH-1:0]     tx_data,
    input  wire [(DATA_WIDTH/8)-1:0] tx_wstrb,
    input wire [2:0]                 cmd_offset,
    output wire                      fifo_data_pop,  

    output wire                      WVALID,
    input  wire                      WREADY,
    output wire [DATA_WIDTH-1:0]     WDATA,
    output wire [(DATA_WIDTH/8)-1:0] WSTRB,
    output wire                      WLAST
);

    reg [7:0] beat_counter;
    reg start;
   // assign WVALID = (!fifo_cmd_empty && !fifo_data_empty);
    assign WVALID = (!fifo_data_empty);
    wire w_handshake = (WVALID && WREADY);
    assign WDATA =start?tx_data:{DATA_WIDTH{1'b0}};
  //  assign WSTRB  = {(DATA_WIDTH/8){1'b1}};
   // assign WSTRB  = start ? tx_wstrb : {(DATA_WIDTH/8){1'b0}};
	wire [(DATA_WIDTH/8)-1:0] start_wstrb_mask = {{(DATA_WIDTH/8){1'b1}}} << cmd_offset;  
    wire [(DATA_WIDTH/8)-1:0] active_wstrb = (beat_counter == 8'd0)?(tx_wstrb & {{(DATA_WIDTH/8){1'b1}}} << cmd_offset):tx_wstrb;// the strb for first beat and other beats are choosen

assign WSTRB = (WVALID || start) ? ((beat_counter == 8'd0) ? (tx_wstrb & start_wstrb_mask) : tx_wstrb) : {(DATA_WIDTH/8){1'b0}};   
 assign WLAST  = ((beat_counter == cmd_axi_len)&&(cmd_axi_len!=0))?1'b1:1'b0;
    assign fifo_data_pop = w_handshake;
    assign fifo_cmd_pop  = (w_handshake);
  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_counter <= 8'd0;
        end else begin
            if (w_handshake) begin
                start<=1'b1;
                if (WLAST||WDATA==0) begin
                    beat_counter <= 8'd0; 
                end else begin
					
                    beat_counter = beat_counter + 1'b1;
                end
			end
        end
    end

endmodule
