module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  write_en,
    input  wire                  read_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire                  full,   
    output wire                  empty   
);

    reg [(DATA_WIDTH-1)+8:0] mem [0:DEPTH-1];
    integer i;
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr; 
    reg wr_tgl_flag, rd_tgl_flag;           //wrapping indication
	wire do_write = write_en && !full;
    wire do_read  = read_en  && !empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr      <= 0;
            wr_tgl_flag <= 1'b0;
            for (i = 0; i < DEPTH; i = i + 1) mem[i] <= 0;
        end else if (do_write) begin
            mem[wr_ptr] <= data_in;
            if (wr_ptr == DEPTH - 1) begin
                wr_ptr      <= 0;
                wr_tgl_flag <= ~wr_tgl_flag;
            end else begin
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr      <= 0;
            rd_tgl_flag <= 1'b0;
        end else if (do_read) begin
            if (rd_ptr == DEPTH - 1) begin
                rd_ptr      <= 0;
                rd_tgl_flag <= ~rd_tgl_flag;
            end else begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    assign data_out = mem[rd_ptr];
    assign empty = (rd_ptr == wr_ptr) && (rd_tgl_flag == wr_tgl_flag);	//ptr at same location and wrapped around at same no of times so empty (ntg to read)
	assign full  = (rd_ptr == wr_ptr) && (rd_tgl_flag != wr_tgl_flag);  //ptr at same location but wr_ptr is wrapped one extra than read so full .
endmodule

// separated write and read because in AXI both can occur simultaneously
