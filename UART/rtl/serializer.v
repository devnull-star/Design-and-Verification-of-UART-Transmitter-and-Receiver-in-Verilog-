`timescale 1ns/1ps

module serializer #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  load_en,
    input  wire                  shift_en,
    input  wire [DATA_WIDTH-1:0] parallel_in,
    output reg                   serial_bit,
    output reg                   done
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg  <= {DATA_WIDTH{1'b0}};
            serial_bit <= 1'b0;
            bit_count  <= 0;
            done       <= 1'b0;
        end else begin
            done <= 1'b0;

            if (load_en) begin
                shift_reg  <= parallel_in;
                serial_bit <= parallel_in[0];
                bit_count  <= 0;
            end else if (shift_en) begin
                serial_bit <= shift_reg[0];
                shift_reg  <= shift_reg >> 1;

                if (bit_count == DATA_WIDTH - 1) begin
                    done <= 1'b1;
                    bit_count <= 0;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule