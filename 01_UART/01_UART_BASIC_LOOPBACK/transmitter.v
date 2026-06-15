module transmitter(
    input clk,
    input rst,
    input wr_enb,
    input enb,
    input [7:0] data_in,
    output reg tx,
    output reg busy
);

parameter IDLE  = 2'b00;
parameter START = 2'b01;
parameter DATA  = 2'b10;
parameter STOP  = 2'b11;

reg [1:0] state;
reg [7:0] shift_reg;
reg [2:0] index;

always @(posedge clk)
begin
    if(rst)
    begin
        state <= IDLE;
        tx <= 1'b1;
        busy <= 1'b0;
        shift_reg <= 8'd0;
        index <= 3'd0;
    end
    else
    begin
        case(state)

        IDLE:
        begin
            tx <= 1'b1;
            busy <= 1'b0;

            if(wr_enb)
            begin
                shift_reg <= data_in;
                index <= 0;
                busy <= 1'b1;
                state <= START;
            end
        end

        START:
        begin
            if(enb)
            begin
                tx <= 1'b0;
                state <= DATA;
            end
        end

        DATA:
        begin
            if(enb)
            begin
                tx <= shift_reg[0];
                shift_reg <= shift_reg >> 1;

                if(index == 3'd7)
                    state <= STOP;
                else
                    index <= index + 1'b1;
            end
        end

        STOP:
        begin
            if(enb)
            begin
                tx <= 1'b1;
                busy <= 1'b0;
                state <= IDLE;
            end
        end

        endcase
    end
end

endmodule