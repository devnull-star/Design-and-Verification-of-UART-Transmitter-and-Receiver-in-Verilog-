`timescale 1ns/1ps

module uart_rx #(
    parameter DATA_WIDTH = 8,
    parameter OVERSAMPLE = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  rx_line,
    input  wire                  parity_enable,
    input  wire                  parity_type,

    output reg  [DATA_WIDTH-1:0] rx_data,
    output reg                   data_ready,
    output reg                   parity_error,
    output reg                   frame_error
);

    localparam RX_IDLE   = 3'b000;
    localparam RX_START  = 3'b001;
    localparam RX_DATA   = 3'b010;
    localparam RX_PARITY = 3'b011;
    localparam RX_STOP   = 3'b100;

    reg [2:0] rx_state;
    reg [$clog2(OVERSAMPLE)-1:0] sample_count;
    reg [$clog2(DATA_WIDTH):0] bit_index;
    reg [DATA_WIDTH-1:0] shift_buffer;
    reg sampled_bit;
    reg received_parity;

    wire expected_parity;

    parity_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) rx_parity_unit (
        .data_word(shift_buffer),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .parity_bit(expected_parity)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state       <= RX_IDLE;
            sample_count   <= 0;
            bit_index      <= 0;
            shift_buffer   <= 0;
            rx_data        <= 0;
            data_ready     <= 1'b0;
            parity_error   <= 1'b0;
            frame_error    <= 1'b0;
            sampled_bit    <= 1'b1;
            received_parity <= 1'b0;
        end else begin
            data_ready <= 1'b0;

            case (rx_state)
                RX_IDLE: begin
                    sample_count <= 0;
                    bit_index <= 0;
                    parity_error <= 1'b0;
                    frame_error <= 1'b0;

                    if (rx_line == 1'b0)
                        rx_state <= RX_START;
                end

                RX_START: begin
                    if (sample_count == (OVERSAMPLE/2)) begin
                        if (rx_line == 1'b0) begin
                            sample_count <= 0;
                            rx_state <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end

                RX_DATA: begin
                    if (sample_count == OVERSAMPLE-1) begin
                        sample_count <= 0;
                        shift_buffer[bit_index] <= rx_line;

                        if (bit_index == DATA_WIDTH-1) begin
                            bit_index <= 0;
                            if (parity_enable)
                                rx_state <= RX_PARITY;
                            else
                                rx_state <= RX_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end

                RX_PARITY: begin
                    if (sample_count == OVERSAMPLE-1) begin
                        sample_count <= 0;
                        received_parity <= rx_line;

                        if (rx_line != expected_parity)
                            parity_error <= 1'b1;

                        rx_state <= RX_STOP;
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end

                RX_STOP: begin
                    if (sample_count == OVERSAMPLE-1) begin
                        sample_count <= 0;

                        if (rx_line != 1'b1)
                            frame_error <= 1'b1;

                        rx_data <= shift_buffer;
                        data_ready <= 1'b1;
                        rx_state <= RX_IDLE;
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end

                default: begin
                    rx_state <= RX_IDLE;
                end
            endcase
        end
    end

endmodule