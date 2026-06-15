module receiver(
    input clk,
    input rst,
    input rx,
    input rdy_clr,
    input clk_enb,
    output reg rdy,
    output reg [7:0] data_out
);

parameter IDLE  = 2'b00;
parameter START = 2'b01;
parameter DATA  = 2'b10;
parameter STOP  = 2'b11;

reg [1:0] state;
reg [2:0] index;
reg [7:0] rx_shift;

always @(posedge clk)
begin
    if(rst)
    begin
        state <= IDLE;
        index <= 0;
        rx_shift <= 0;
        data_out <= 0;
        rdy <= 0;
    end
    else
    begin
        if(rdy_clr)
            rdy <= 0;

        case(state)

        IDLE:
        begin
            if(rx == 0)
                state <= START;
        end

        START:
        begin
            if(clk_enb)
            begin
                if(rx == 0)
                begin
                    index <= 0;
                    state <= DATA;
                end
                else
                    state <= IDLE;
            end
        end

        DATA:
        begin
            if(clk_enb)
            begin
                rx_shift[index] <= rx;

                if(index == 3'd7)
                    state <= STOP;
                else
                    index <= index + 1'b1;
            end
        end

        STOP:
        begin
            if(clk_enb)
            begin
                if(rx)
                begin
                    data_out <= rx_shift;
                    rdy <= 1'b1;
                end

                state <= IDLE;
            end
        end

        endcase
    end
end

endmodule