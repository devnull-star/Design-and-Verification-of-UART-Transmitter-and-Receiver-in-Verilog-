`timescale 1ns/1ps

module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  tx_start,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire                  parity_enable,
    input  wire                  parity_type,

    output wire                  tx_line,
    output wire                  tx_busy,
    output wire                  tx_done
);

    wire load_data;
    wire shift_data;
    wire serial_data;
    wire byte_done;
    wire generated_parity;
    wire [1:0] mux_select;

    localparam SEL_START  = 2'b00;
    localparam SEL_DATA   = 2'b01;
    localparam SEL_PARITY = 2'b10;
    localparam SEL_STOP   = 2'b11;

    serializer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) serializer_unit (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(load_data),
        .shift_en(shift_data),
        .parallel_in(tx_data),
        .serial_bit(serial_data),
        .done(byte_done)
    );

    parity_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) parity_unit (
        .data_word(tx_data),
        .parity_enable(parity_enable),
        .parity_type(parity_type),
        .parity_bit(generated_parity)
    );

    fsm tx_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start_request(tx_start),
        .byte_done(byte_done),
        .parity_enable(parity_enable),
        .load_data(load_data),
        .shift_data(shift_data),
        .busy(tx_busy),
        .frame_done(tx_done),
        .mux_sel(mux_select)
    );

    reg tx_reg;

    always @(*) begin
        case (mux_select)
            SEL_START:  tx_reg = 1'b0;
            SEL_DATA:   tx_reg = serial_data;
            SEL_PARITY: tx_reg = generated_parity;
            SEL_STOP:   tx_reg = 1'b1;
            default:    tx_reg = 1'b1;
        endcase
    end

    assign tx_line = tx_reg;

endmodule