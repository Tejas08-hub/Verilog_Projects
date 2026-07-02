module async_fifo #(
    parameter width = 8,
    parameter depth = 8
)(
    input rd_clk,
    input wr_clk,
    input rd_en,
    input wr_en,
    input rst,
    input [width-1:0] data_in,
    output reg [width-1:0] data_out,
    output full,
    output empty
);

    localparam addr_width = $clog2(depth);

    reg [width-1:0] FIFO [depth-1:0];
    reg [addr_width:0] wb_ptr, rb_ptr;
    wire [addr_width:0] wg_ptr, rg_ptr;

    reg [addr_width:0] wg_ptr_sync1, wg_ptr_sync2;
    reg [addr_width:0] rg_ptr_sync1, rg_ptr_sync2;

    wire [addr_width:0] wb_ptr_next;
    wire [addr_width:0] wg_ptr_next;

    // Write logic
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wb_ptr <= 0;
        else if (wr_en && !full) begin
            FIFO[wb_ptr[addr_width-1:0]] <= data_in;
            wb_ptr <= wb_ptr + 1;
        end
    end

    // Write pointer to Gray
    assign wg_ptr = (wb_ptr >> 1) ^ wb_ptr;

    // Read logic
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rb_ptr <= 0;
            data_out <= 0;
        end
        else if (rd_en && !empty) begin
            data_out <= FIFO[rb_ptr[addr_width-1:0]];
            rb_ptr <= rb_ptr + 1;
        end
    end

    // Read pointer to Gray
    assign rg_ptr = (rb_ptr >> 1) ^ rb_ptr;

    // Sync write Gray pointer to read clock domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wg_ptr_sync1 <= 0;
            wg_ptr_sync2 <= 0;
        end
        else begin
            wg_ptr_sync1 <= wg_ptr;
            wg_ptr_sync2 <= wg_ptr_sync1;
        end
    end

    // Sync read Gray pointer to write clock domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rg_ptr_sync1 <= 0;
            rg_ptr_sync2 <= 0;
        end
        else begin
            rg_ptr_sync1 <= rg_ptr;
            rg_ptr_sync2 <= rg_ptr_sync1;
        end
    end

    // Empty condition
    assign empty = (rg_ptr == wg_ptr_sync2);

    // Full condition
    assign wb_ptr_next = wb_ptr + 1;
    assign wg_ptr_next = (wb_ptr_next >> 1) ^ wb_ptr_next;
    assign full = (wg_ptr_next == {~rg_ptr_sync2[addr_width:addr_width-1], rg_ptr_sync2[addr_width-2:0]});

endmodule