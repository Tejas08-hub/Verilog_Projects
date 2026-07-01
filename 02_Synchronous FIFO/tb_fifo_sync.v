`timescale 1ns/1ps

module tb_fifo_sync;

parameter DATA_WIDTH = 32;
parameter FIFO_DEPTH = 8;

// Inputs
reg clk;
reg rst_n;
reg cs;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] data_in;

// Outputs
wire [DATA_WIDTH-1:0] data_out;
wire full;
wire empty;

integer i;

// DUT
fifo_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) uut (
    .clk(clk),
    .rst_n(rst_n),
    .cs(cs),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

// Clock
always #5 clk = ~clk;

initial begin

    // Initialize
    clk = 0;
    rst_n = 0;
    cs = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;

    // Reset
    #20;
    rst_n = 1;

    // Write data
    $display("------ WRITE ------");

    for(i=1; i<=FIFO_DEPTH; i=i+1)
    begin
        @(negedge clk);
        wr_en = 1;
        data_in = i;

        @(posedge clk);
        $display("[%0t] Write = %0d", $time, data_in);
    end

    @(negedge clk);
    wr_en = 0;

    // Wait
    #20;

    // Read data
    $display("------ READ ------");

    for(i=1; i<=FIFO_DEPTH; i=i+1)
    begin
        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1;
        $display("[%0t] Read = %0d", $time, data_out);
    end

    @(negedge clk);
    rd_en = 0;

    // End simulation
    #20;
    $finish;

end

// Display values
initial begin
    $monitor("Time=%0t  In=%0d  Out=%0d  Full=%b  Empty=%b",
              $time, data_in, data_out, full, empty);
end

endmodule