`timescale 1ns/1ps

module uart_rx_tb;

    parameter DATA_WIDTH = 8;
    parameter OVERSAMPLE = 16;

    reg clk;
    reg rst_n;
    reg rx_line;
    reg parity_enable;
    reg parity_type;

    wire [DATA_WIDTH-1:0] rx_data;
    wire data_ready;
    wire parity_error;
    wire frame_error;

    integer error_count;

    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .OVERSAMPLE(OVERSAMPLE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_line(rx_line),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .parity_error(parity_error),
        .frame_error(frame_error)
    );

    always #2 clk = ~clk;

    task reset_dut;
        begin
            rst_n = 1'b0;
            rx_line = 1'b1;
            parity_enable = 1'b0;
            parity_type = 1'b0;
            repeat(5) @(posedge clk);
            rst_n = 1'b1;
        end
    endtask

    task send_uart_bit;
        input bit_value;
        integer i;
        begin
            rx_line = bit_value;
            for (i = 0; i < OVERSAMPLE; i = i + 1)
                @(posedge clk);
        end
    endtask

    task send_uart_frame;
        input [7:0] data_value;
        input parity_en;
        input parity_sel;
        reg parity_bit;
        integer i;
        begin
            parity_enable = parity_en;
            parity_type = parity_sel;

            parity_bit = parity_sel ? ~(^data_value) : (^data_value);

            send_uart_bit(1'b0);

            for (i = 0; i < 8; i = i + 1)
                send_uart_bit(data_value[i]);

            if (parity_en)
                send_uart_bit(parity_bit);

            send_uart_bit(1'b1);

            wait(data_ready);

            if (rx_data !== data_value) begin
                $display("ERROR: Expected %h, Got %h", data_value, rx_data);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Received %h", rx_data);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);

        clk = 1'b0;
        error_count = 0;

        reset_dut();

        send_uart_frame(8'hA5, 1'b1, 1'b0);
        send_uart_frame(8'h3C, 1'b1, 1'b1);
        send_uart_frame(8'hF0, 1'b0, 1'b0);
        send_uart_frame(8'h55, 1'b1, 1'b0);

        $display("UART RECEIVER TEST COMPLETED");
        $display("Total Errors = %0d", error_count);

        #50;
        $finish;
    end

endmodule