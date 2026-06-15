module receiver(
    input clk,
    input rst,
    input rx,
    input rdy_clr,
    input clk_enb,      // 16x baud clock

    output reg rdy,
    output reg [7:0] data_out
);

parameter IDLE  = 2'b00;
parameter START = 2'b01;
parameter DATA  = 2'b10;
parameter STOP  = 2'b11;

reg [1:0] state;

reg [3:0] sample_count;   // 0-15
reg [2:0] bit_count;      // 0-7

reg [7:0] temp_register;

always @(posedge clk)
begin
    if(rst)
    begin
        state <= IDLE;
        sample_count <= 0;
        bit_count <= 0;
        temp_register <= 0;
        data_out <= 0;
        rdy <= 0;
    end
    else
    begin

        if(rdy_clr)
            rdy <= 0;

        if(clk_enb)
        begin

            case(state)

            IDLE:
            begin
                sample_count <= 0;

                if(rx == 1'b0)
                    state <= START;
            end

            START:
            begin
                sample_count <= sample_count + 1'b1;

                // Middle of start bit
                if(sample_count == 4'd7)
                begin
                    if(rx == 1'b0)
                    begin
                        sample_count <= 0;
                        bit_count <= 0;
                        state <= DATA;
                    end
                    else
                        state <= IDLE;
                end
            end

            DATA:
            begin
                sample_count <= sample_count + 1'b1;

                if(sample_count == 4'd15)
                begin
                    sample_count <= 0;

                    temp_register[bit_count] <= rx;

                    if(bit_count == 3'd7)
                        state <= STOP;
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end

            STOP:
            begin
                sample_count <= sample_count + 1'b1;

                if(sample_count == 4'd15)
                begin
                    if(rx == 1'b1)
                    begin
                        data_out <= temp_register;
                        rdy <= 1'b1;
                    end

                    sample_count <= 0;
                    state <= IDLE;
                end
            end

            default:
            begin
                state <= IDLE;
            end

            endcase

        end
    end
end

endmodule