`timescale 1ns/1ps

module parity_checker #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] data_word,
    input  wire                  parity_enable,
    input  wire                  parity_type,
    output wire                  parity_bit
);

    /*
        parity_type = 0 -> even parity
        parity_type = 1 -> odd parity
    */

    wire xor_result;

    assign xor_result = ^data_word;

    assign parity_bit = (parity_enable) ? 
                        ((parity_type) ? ~xor_result : xor_result) :
                        1'b0;

endmodule