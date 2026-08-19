module i2c_master (

    input        clk,
    input        reset,
    input        tick,

    input        start,
    input        rw,
    input  [6:0] addr,
    input  [7:0] tx_data,

    // I2C open-drain bus
    inout        scl,
    inout        sda,

    output reg       busy,
    output reg       done,
    output reg [7:0] rx_data,
    output reg       ack_error,
    output reg       irq

);

    //====================================================
    // FSM STATES
    //====================================================

    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam SEND_ADDR  = 4'd2;
    localparam ADDR_ACK   = 4'd3;

    localparam WRITE_DATA = 4'd4;
    localparam WRITE_ACK  = 4'd5;

    localparam STOP       = 4'd6;
    localparam DONE       = 4'd7;
    localparam ERROR      = 4'd8;

    localparam READ_DATA  = 4'd9;
    localparam READ_ACK   = 4'd10;


    //====================================================
    // INTERNAL REGISTERS
    //====================================================

    reg [3:0] state;

    reg [7:0] tx_shift_reg;

    reg [2:0] bit_count;

    // Open-drain controls
    reg scl_drive_low;
    reg sda_drive_low;


    //====================================================
    // OPEN-DRAIN BUS
    //====================================================

    assign scl = scl_drive_low ? 1'b0 : 1'bz;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;


    //====================================================
    // MAIN FSM
    //====================================================

    always @(posedge clk) begin

        if (reset) begin

            state         <= IDLE;

            tx_shift_reg  <= 8'b0;
            bit_count     <= 3'd0;

            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;

            busy          <= 1'b0;
            done          <= 1'b0;
            rx_data       <= 8'b0;
            ack_error     <= 1'b0;
            irq           <= 1'b0;

        end

        else begin

            // One-clock pulse signals
            done <= 1'b0;
            irq  <= 1'b0;

            case (state)


                //================================================
                // IDLE
                //================================================

                IDLE: begin

                    // Release both bus lines
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;

                    busy <= 1'b0;

                    if (start) begin

                        busy <= 1'b1;

                        // Address + R/W
                        tx_shift_reg <= {addr, rw};

                        // Start from MSB
                        bit_count <= 3'd7;

                        // Clear previous error
                        ack_error <= 1'b0;

                        state <= START;

                    end

                end


                //================================================
                // START
                //================================================

                START: begin

                    // SCL HIGH
                    scl_drive_low <= 1'b0;

                    // SDA HIGH -> LOW
                    sda_drive_low <= 1'b1;

                    if (tick) begin

                        // Pull SCL LOW
                        scl_drive_low <= 1'b1;

                        state <= SEND_ADDR;

                    end

                end


                //================================================
                // SEND ADDRESS
                //================================================

                SEND_ADDR: begin

                    // SCL LOW
                    if (scl_drive_low == 1'b1) begin

                        // Prepare current bit

                        if (tx_shift_reg[bit_count])
                            sda_drive_low <= 1'b0;
                        else
                            sda_drive_low <= 1'b1;


                        if (tick) begin

                            // Release SCL
                            // Pull-up makes SCL HIGH
                            scl_drive_low <= 1'b0;

                        end

                    end


                    // SCL HIGH
                    else begin

                        // SDA remains stable here

                        if (tick) begin

                            // Pull SCL LOW
                            scl_drive_low <= 1'b1;


                            if (bit_count == 3'd0) begin

                                // Address byte complete

                                // Release SDA for ACK
                                sda_drive_low <= 1'b0;

                                state <= ADDR_ACK;

                            end

                            else begin

                                bit_count <= bit_count - 1'b1;

                            end

                        end

                    end

                end


                //================================================
                // ADDRESS ACK
                //================================================

                ADDR_ACK: begin

                    // Master releases SDA
                    sda_drive_low <= 1'b0;


                    if (tick) begin

                        // SCL LOW -> HIGH
                        if (scl_drive_low == 1'b1) begin

                            scl_drive_low <= 1'b0;

                        end

                        // SCL HIGH -> sample ACK
                        else begin

                            if (sda == 1'b0) begin

                                // ACK received

                                scl_drive_low <= 1'b1;


                                if (rw == 1'b0) begin

                                    //========================
                                    // WRITE
                                    //========================

                                    tx_shift_reg <= tx_data;

                                    bit_count <= 3'd7;

                                    state <= WRITE_DATA;

                                end

                                else begin

                                    //========================
                                    // READ
                                    //========================

                                    bit_count <= 3'd7;

                                    rx_data <= 8'b0;

                                    state <= READ_DATA;

                                end

                            end

                            else begin

                                // NACK received

                                scl_drive_low <= 1'b1;

                                state <= ERROR;

                            end

                        end

                    end

                end


                //================================================
                // WRITE DATA
                //================================================

                WRITE_DATA: begin

                    // SCL LOW
                    if (scl_drive_low == 1'b1) begin

                        // Prepare current data bit

                        if (tx_shift_reg[bit_count])
                            sda_drive_low <= 1'b0;
                        else
                            sda_drive_low <= 1'b1;


                        if (tick) begin

                            // SCL LOW -> HIGH
                            scl_drive_low <= 1'b0;

                        end

                    end


                    // SCL HIGH
                    else begin

                        if (tick) begin

                            // SCL HIGH -> LOW
                            scl_drive_low <= 1'b1;


                            if (bit_count == 3'd0) begin

                                // All 8 bits transmitted

                                // Release SDA for ACK
                                sda_drive_low <= 1'b0;

                                state <= WRITE_ACK;

                            end

                            else begin

                                bit_count <= bit_count - 1'b1;

                            end

                        end

                    end

                end


                //================================================
                // WRITE ACK
                //================================================

                WRITE_ACK: begin

                    // Release SDA
                    sda_drive_low <= 1'b0;


                    if (tick) begin

                        // SCL LOW -> HIGH
                        if (scl_drive_low == 1'b1) begin

                            scl_drive_low <= 1'b0;

                        end

                        // SCL HIGH -> sample ACK
                        else begin

                            if (sda == 1'b0) begin

                                // ACK

                                scl_drive_low <= 1'b1;

                                state <= STOP;

                            end

                            else begin

                                // NACK

                                scl_drive_low <= 1'b1;

                                state <= ERROR;

                            end

                        end

                    end

                end


                //================================================
                // READ DATA
                //================================================

                READ_DATA: begin

                    // Master releases SDA.
                    // Slave controls SDA.

                    sda_drive_low <= 1'b0;


                    // SCL LOW
                    if (scl_drive_low == 1'b1) begin

                        if (tick) begin

                            // SCL LOW -> HIGH
                            scl_drive_low <= 1'b0;

                        end

                    end


                    // SCL HIGH
                    else begin

                        if (tick) begin

                            // Sample slave data

                            rx_data[bit_count] <= sda;


                            // SCL HIGH -> LOW
                            scl_drive_low <= 1'b1;


                            if (bit_count == 3'd0) begin

                                // All 8 bits received

                                state <= READ_ACK;

                            end

                            else begin

                                bit_count <= bit_count - 1'b1;

                            end

                        end

                    end

                end


                //================================================
                // READ ACK / NACK
                //================================================

                READ_ACK: begin

                    // For our first one-byte READ,
                    // master sends NACK by releasing SDA.

                    sda_drive_low <= 1'b0;


                    if (tick) begin

                        // SCL LOW -> HIGH
                        if (scl_drive_low == 1'b1) begin

                            scl_drive_low <= 1'b0;

                        end

                        // SCL HIGH
                        else begin

                            // NACK complete

                            scl_drive_low <= 1'b1;

                            state <= STOP;

                        end

                    end

                end


                //================================================
                // ERROR
                //================================================

                ERROR: begin

                    ack_error <= 1'b1;

                    state <= STOP;

                end


                //================================================
                // STOP
                //================================================

                STOP: begin

                    // SCL LOW
                    if (scl_drive_low == 1'b1) begin

                        // Keep SDA LOW
                        sda_drive_low <= 1'b1;


                        if (tick) begin

                            // Release SCL
                            scl_drive_low <= 1'b0;

                        end

                    end


                    // SCL HIGH
                    else begin

                        if (tick) begin

                            // SDA LOW -> HIGH
                            // while SCL HIGH
                            // = STOP condition

                            sda_drive_low <= 1'b0;

                            state <= DONE;

                        end

                    end

                end


                //================================================
                // DONE
                //================================================

                DONE: begin

                    busy <= 1'b0;

                    done <= 1'b1;

                    // Temporary interrupt indication
                    irq <= 1'b1;

                    state <= IDLE;

                end


                //================================================
                // DEFAULT
                //================================================

                default: begin

                    state <= IDLE;

                end


            endcase

        end

    end

endmodule