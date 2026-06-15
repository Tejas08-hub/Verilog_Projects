`timescale 1ns/1ps

module uart_top_tb;

reg clk;
reg rst;
reg wr_enb;
reg rdy_clr;
reg [7:0] data_in;

wire tx;
wire busy;
wire rdy;
wire [7:0] data_out;

uart_top uut(
    .clk(clk),
    .rst(rst),
    .wr_enb(wr_enb),
    .rdy_clr(rdy_clr),
    .data_in(data_in),
    .tx(tx),
    .busy(busy),
    .rdy(rdy),
    .data_out(data_out)
);

always #10 clk = ~clk;   // 50 MHz clock

initial
begin

    clk = 0;
    rst = 1;
    wr_enb = 0;
    rdy_clr = 0;
    data_in = 8'h00;

    #100;
    rst = 0;

    //--------------------------------------------------
    // First Byte
    //--------------------------------------------------

    #100;

    data_in = 8'h55;
    wr_enb = 1;

    #20;
    wr_enb = 0;

    wait(rdy);

    #100;

    rdy_clr = 1;

    #20;
    rdy_clr = 0;

    //--------------------------------------------------
    // Second Byte
    //--------------------------------------------------

    #1000;

    data_in = 8'hA3;
    wr_enb = 1;

    #20;
    wr_enb = 0;

    wait(rdy);

    #100;

    rdy_clr = 1;

    #20;
    rdy_clr = 0;

    //--------------------------------------------------

    #10000;

    $finish;

end

endmodule