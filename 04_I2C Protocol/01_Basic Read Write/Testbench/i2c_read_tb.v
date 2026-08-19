`timescale 1us/1ns

module i2c_read_tb;

    //==================================================
    // SYSTEM / CONTROL SIGNALS
    //==================================================

    reg        clk;
    reg        reset;
    reg        start;
    reg        rw;
    reg [6:0]  addr;
    reg [7:0]  tx_data;

    wire       tick;

    // I2C bus
    tri        scl;
    tri        sda;

    // Master outputs
    wire       busy;
    wire       done;
    wire [7:0] rx_data;
    wire       ack_error;
    wire       irq;


    //==================================================
    // SLAVE MODEL
    //==================================================

    reg        slave_ack;
    reg [7:0]  slave_read_data;
    reg [2:0]  slave_bit_count;
    reg        slave_drive_low;


    //==================================================
    // I2C PULL-UP RESISTORS
    //==================================================

    pullup(scl);
    pullup(sda);


    //==================================================
    // 1 MHz SYSTEM CLOCK
    // Period = 1 us
    //==================================================

    initial begin
        clk = 1'b0;

        forever #0.5 clk = ~clk;
    end


    //==================================================
    // I2C CLOCK GENERATOR
    // 1 MHz SYSTEM CLOCK
    // 100 kHz I2C CLOCK
    //==================================================

    i2c_clk_gen #(
        .CLK_FREQ(1_000_000),
        .I2C_FREQ(100_000)
    ) clk_gen (
        .clk   (clk),
        .reset (reset),
        .tick  (tick)
    );


    //==================================================
    // I2C MASTER
    //==================================================

    i2c_master dut (

        .clk       (clk),
        .reset     (reset),
        .tick      (tick),

        .start     (start),
        .rw        (rw),
        .addr      (addr),
        .tx_data   (tx_data),

        .scl       (scl),
        .sda       (sda),

        .busy      (busy),
        .done      (done),
        .rx_data   (rx_data),
        .ack_error (ack_error),
        .irq       (irq)
    );


    //==================================================
    // SLAVE SDA DRIVER
    //==================================================

    assign sda =
           slave_ack ? 1'b0 :
           (dut.state == 4'd9 && slave_drive_low) ? 1'b0 :
           1'bz;


    //==================================================
    // ADDRESS ACK
    //==================================================

    always @(*) begin

        slave_ack = 1'b0;

        // ADDR_ACK = state 3

        if ((dut.state == 4'd3) && (scl == 1'b1))
            slave_ack = 1'b1;

    end


    //==================================================
    // SLAVE READ DATA
    //==================================================

    // Slave sends:
    //
    // 11001100
    //
    // MSB first.

    initial begin

        slave_read_data = 8'b11001100;
        slave_bit_count = 3'd7;
        slave_drive_low = 1'b0;

    end


    //==================================================
    // PREPARE NEXT READ BIT
    //==================================================

    // SDA changes while SCL is LOW.

    always @(negedge scl or posedge reset) begin

        if (reset) begin

            slave_bit_count <= 3'd7;
            slave_drive_low <= 1'b0;

        end

        else if (dut.state == 4'd9) begin

            if (slave_read_data[slave_bit_count] == 1'b0)
                slave_drive_low <= 1'b1;
            else
                slave_drive_low <= 1'b0;

        end

    end


    //==================================================
    // MOVE TO NEXT READ BIT
    //==================================================

    always @(posedge scl or posedge reset) begin

        if (reset) begin

            slave_bit_count <= 3'd7;

        end

        else if (dut.state == 4'd9) begin

            if (slave_bit_count != 3'd0)
                slave_bit_count <= slave_bit_count - 1'b1;

        end

    end


    //==================================================
    // READ TEST
    //==================================================

    initial begin

        // Initial values

        reset   = 1'b1;
        start   = 1'b0;

        addr    = 7'b1010000;

        // READ operation
        rw      = 1'b1;

        // Not used during READ
        tx_data = 8'b00000000;


        // Reset
        #5;
        reset = 1'b0;


        // Wait before starting
        #5;


        // Start READ transaction
        start = 1'b1;

        #1;

        start = 1'b0;


        // Wait for complete transaction
        #150;


        // Display result

        $display("------------------------------------");
        $display("I2C READ COMPLETE");
        $display("RX DATA   = %b", rx_data);
        $display("RX DATA   = %d", rx_data);
        $display("ACK ERROR = %b", ack_error);
        $display("------------------------------------");


        $finish;

    end


    //==================================================
    // SIMPLE MONITOR
    //==================================================

    initial begin

        $monitor(
            "TIME=%0t us | SCL=%b | SDA=%b | STATE=%0d | BIT=%0d | RX=%b | DONE=%b",
            $time,
            scl,
            sda,
            dut.state,
            dut.bit_count,
            rx_data,
            done
        );

    end

endmodule