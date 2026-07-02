module tb_async_fifo;

    parameter width = 8;
    parameter depth = 8;

    reg wr_clk, rd_clk;
    reg wr_en, rd_en;
    reg rst;
    reg [width-1:0] data_in;
    wire [width-1:0] data_out;
    wire full, empty;

    async_fifo #(
        .width(width),
        .depth(depth)
    ) dut (
        .rd_clk(rd_clk),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    initial rd_clk = 0;
    always #12 rd_clk = ~rd_clk;

    integer i;

    initial begin
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        #20 rst = 0;

        // Write data into FIFO
        $display("---- Writing Data ----");
        for (i = 1; i < 12; i = i + 1) begin
            @(posedge wr_clk);
            if (!full) begin
                wr_en <= 1;
                data_in <= i;
                $display("%0t ns : WRITE data_in = %0d (full = %b)", $time, i, full);
            end
            else begin
                wr_en <= 0;
                $display("%0t ns : FIFO FULL, cannot write", $time);
            end
        end

        wr_en <= 0;
        #50;

        // Read data from FIFO
        $display("---- Reading Data ----");
        for (i = 1; i < 12; i = i + 1) begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en <= 1;
                #1;
                $display("%0t ns : READ data_out = %0d (empty = %b)", $time, data_out, empty);
            end
            else begin
                rd_en <= 0;
                $display("%0t ns : FIFO EMPTY, cannot read", $time);
            end
        end

        rd_en <= 0;

        #100;
        $finish;
    end

endmodule