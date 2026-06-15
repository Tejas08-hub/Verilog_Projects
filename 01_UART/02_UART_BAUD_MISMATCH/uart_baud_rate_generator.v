module baud_rate_generator(
    input clk,
    input rst,
    output tx_enb,
    output rx_enb
);

reg [5:0] tx_count;
reg [5:0] rx_count;

always @(posedge clk)
begin
    if(rst)
        tx_count <= 0;
    else if(tx_count == 49)
        tx_count <= 0;
    else
        tx_count <= tx_count + 1'b1;
end

always @(posedge clk)
begin
    if(rst)
        rx_count <= 0;
    else if(rx_count == 59)
        rx_count <= 0;
    else
        rx_count <= rx_count + 1'b1;
end

assign tx_enb = (tx_count == 0);
assign rx_enb = (rx_count == 0);

endmodule