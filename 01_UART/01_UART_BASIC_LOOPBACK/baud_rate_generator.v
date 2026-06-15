module baud_rate_generator(
    input clk,
    input rst,
    output reg tx_enb,
    output reg rx_enb
);

parameter freq = 5000;
parameter baud = 100;

localparam integer ccpt = freq/baud;

integer count;

always @(posedge clk)
begin
    if(rst)
    begin
        count <= 0;
        tx_enb <= 0;
        rx_enb <= 0;
    end
    else if(count == ccpt-1)
    begin
        count <= 0;
        tx_enb <= 1;
        rx_enb <= 1;
    end
    else
    begin
        count <= count + 1;
        tx_enb <= 0;
        rx_enb <= 0;
    end
end

endmodule