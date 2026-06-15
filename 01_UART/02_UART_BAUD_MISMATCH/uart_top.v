module uart_top(
    input clk,
    input rst,
    input wr_enb,
    input rdy_clr,
    input [7:0] data_in,
    output tx,
    output busy,
    output rdy,
    output [7:0] data_out
);

wire tx_enb;
wire rx_enb;

baud_rate_generator bg(
    .clk(clk),
    .rst(rst),
    .tx_enb(tx_enb),
    .rx_enb(rx_enb)
);

transmitter tx_inst(
    .clk(clk),
    .rst(rst),
    .wr_enb(wr_enb),
    .enb(tx_enb),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
);

receiver rx_inst(
    .clk(clk),
    .rst(rst),
    .rx(tx),
    .rdy_clr(rdy_clr),
    .clk_enb(rx_enb),
    .rdy(rdy),
    .data_out(data_out)
);

endmodule