module i2c_clk_gen #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000
)(
    input  clk,
    input reset,
    output reg tick
);

    localparam integer HALF_PERIOD =
                    CLK_FREQ / (2 * I2C_FREQ);

    reg [8:0] counter;

    always @(posedge clk) begin

        if (reset) begin
            counter <= 9'd0;
            tick    <= 1'b0;
        end

        else if (counter == HALF_PERIOD - 1) begin
            counter <= 9'd0;
            tick    <= 1'b1;
        end

        else begin
            counter <= counter + 1'b1;
            tick    <= 1'b0;
        end

    end

endmodule