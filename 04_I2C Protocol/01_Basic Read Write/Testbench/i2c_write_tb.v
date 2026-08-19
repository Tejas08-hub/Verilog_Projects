`timescale 1us/1ns

module i2c_write_tb;

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

    reg slave_ack;


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
    //
    // System Clock = 1 MHz
    // I2C Clock    = 100 kHz
    //
    // HALF_PERIOD = 1,000,000 / (2 × 100,000)
    //             = 5
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
    // SLAVE ACK DRIVER
    //==================================================

    // Slave pulls SDA LOW to generate ACK.
    //
    // ADDR_ACK  = state 3
    // WRITE_ACK = state 5

    assign sda = slave_ack ? 1'b0 : 1'bz;


    //==================================================
    // SLAVE ACK CONTROL
    //==================================================

    always @(*) begin

        slave_ack = 1'b0;

        // Address ACK
        if ((dut.state == 4'd3) && (scl == 1'b1))
            slave_ack = 1'b1;

        // Write data ACK
        if ((dut.state == 4'd5) && (scl == 1'b1))
            slave_ack = 1'b1;

    end


    //==================================================
    // WRITE TEST
    //==================================================

    initial begin

        // Initial values

        reset   = 1'b1;
        start   = 1'b0;

        // 7-bit slave address
        addr    = 7'b1010000;

        // WRITE operation
        rw      = 1'b0;

        // Data to transmit
        tx_data = 8'b10100101;


        //================================================
        // RESET
        //================================================

        #5;

        reset = 1'b0;


        //================================================
        // WAIT BEFORE START
        //================================================

        #5;


        //================================================
        // START WRITE TRANSACTION
        //================================================

        start = 1'b1;

        #1;

        start = 1'b0;


        //================================================
        // WAIT FOR TRANSACTION
        //================================================

        #150;


        //================================================
        // DISPLAY RESULT
        //================================================

        $display("------------------------------------");
        $display("I2C WRITE COMPLETE");
        $display("ADDRESS   = %b", addr);
        $display("RW        = %b", rw);
        $display("TX DATA   = %b", tx_data);
        $display("ACK ERROR = %b", ack_error);
        $display("------------------------------------");


        $finish;

    end


    //==================================================
    // SIMPLE MONITOR
    //==================================================

    initial begin

        $monitor(
            "TIME=%0t us | SCL=%b | SDA=%b | STATE=%0d | BIT=%0d | BUSY=%b | DONE=%b",
            $time,
            scl,
            sda,
            dut.state,
            dut.bit_count,
            busy,
            done
        );

    end

endmodule