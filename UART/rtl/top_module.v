`timescale 1ns/1ps

module top_module #(
    parameter DATA_WIDTH = 8,
    parameter OVERSAMPLE = 16
)(
    input  wire                  tx_clk,
    input  wire                  rx_clk,
    input  wire                  rst_n,

    input  wire                  start_tx,
    input  wire [DATA_WIDTH-1:0] parallel_data_in,
    input  wire                  parity_enable,
    input  wire                  parity_type,

    output wire                  tx_busy,
    output wire                  tx_done,

    output wire [DATA_WIDTH-1:0] parallel_data_out,
    output wire                  rx_data_valid,
    output wire                  parity_error,
    output wire                  frame_error
);

    wire serial_link;

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) transmitter (
        .clk(tx_clk),
        .rst_n(rst_n),
        .tx_start(start_tx),
        .tx_data(parallel_data_in),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .tx_line(serial_link),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .OVERSAMPLE(OVERSAMPLE)
    ) receiver (
        .clk(rx_clk),
        .rst_n(rst_n),
        .rx_line(serial_link),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .rx_data(parallel_data_out),
        .data_ready(rx_data_valid),
        .parity_error(parity_error),
        .frame_error(frame_error)
    );

endmodule