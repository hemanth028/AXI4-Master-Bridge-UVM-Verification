module data_response #(
    parameter ID_WIDTH = 4
)(  input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  BVALID,          
	input  wire [1:0]            BRESP,
    input  wire [ID_WIDTH-1:0]   BID,             
    output wire                  BREADY,
    output wire                  wr_burst_done,
    output reg                   wr_error_sticky
);

    assign BREADY = 1'b1;
    wire handshake = (BREADY && BVALID);
    assign wr_burst_done = handshake;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_error_sticky <= 1'b0; 
        end else begin
            if (handshake) begin
                if (BRESP != 2'b00) begin
                    wr_error_sticky <= 1'b1;
                end
            end
        end
    end
endmodule
