`timescale 1ns/1ps

module uart_tx_tb;

    parameter DATA_WIDTH = 8;

    reg clk;
    reg rst_n;
    reg tx_start;
    reg [DATA_WIDTH-1:0] tx_data;
    reg parity_enable;
    reg parity_type;

    wire tx_line;
    wire tx_busy;
    wire tx_done;

    integer error_count;
    integer test_count;

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .tx_line(tx_line),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    task reset_dut;
        begin
            rst_n = 1'b0;
            tx_start = 1'b0;
            tx_data = 8'h00;
            parity_enable = 1'b0;
            parity_type = 1'b0;
            repeat(3) @(posedge clk);
            rst_n = 1'b1;
            repeat(2) @(posedge clk);
        end
    endtask

    task send_byte;
        input [7:0] data_value;
        input parity_en;
        input parity_sel;
        begin
            @(posedge clk);
            tx_data = data_value;
            parity_enable = parity_en;
            parity_type = parity_sel;
            tx_start = 1'b1;

            @(posedge clk);
            tx_start = 1'b0;

            wait(tx_done);
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        clk = 1'b0;
        error_count = 0;
        test_count = 0;

        reset_dut();

        send_byte(8'hA5, 1'b1, 1'b0);
        send_byte(8'h3C, 1'b1, 1'b1);
        send_byte(8'hF0, 1'b0, 1'b0);
        send_byte(8'h55, 1'b1, 1'b0);

        $display("UART TRANSMITTER TEST COMPLETED");
        $display("Total Tests  = %0d", test_count);
        $display("Total Errors = %0d", error_count);

        #50;
        $finish;
    end

endmodule