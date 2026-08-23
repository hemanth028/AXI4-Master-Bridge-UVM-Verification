module axi_r_receiver #(
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,

    input wire fifo_full,
    output wire fifo_wr_en,
    output wire [DATA_WIDTH-1:0] fifo_data,

    input wire [ID_WIDTH-1:0] RID,
    input wire [DATA_WIDTH-1:0] RDATA,
    input wire [1:0] RRESP,
    input wire RLAST,
    input wire RVALID,
    output wire RREADY,

    output wire read_burst_done,
    output reg read_error_stick
);

assign RREADY = !fifo_full;
wire handshake = RREADY && RVALID;
assign fifo_wr_en = handshake && (RRESP == 2'b00);
assign fifo_data = RDATA;
assign read_burst_done = handshake && RLAST;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_error_stick <= 1'b0;
    else if (handshake && (RRESP != 2'b00))
        read_error_stick <= 1'b1;
end

endmodule
