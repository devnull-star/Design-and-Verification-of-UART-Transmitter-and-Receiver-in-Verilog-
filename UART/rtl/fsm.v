`timescale 1ns/1ps

module fsm (
    input  wire clk,
    input  wire rst_n,

    input  wire start_request,
    input  wire byte_done,
    input  wire parity_enable,

    output reg  load_data,
    output reg  shift_data,
    output reg  busy,
    output reg  frame_done,
    output reg  [1:0] mux_sel
);

    localparam IDLE_STATE   = 3'b000;
    localparam START_STATE  = 3'b001;
    localparam DATA_STATE   = 3'b010;
    localparam PARITY_STATE = 3'b011;
    localparam STOP_STATE   = 3'b100;

    localparam SEL_START  = 2'b00;
    localparam SEL_DATA   = 2'b01;
    localparam SEL_PARITY = 2'b10;
    localparam SEL_STOP   = 2'b11;

    reg [2:0] current_state;
    reg [2:0] next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE_STATE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE_STATE: begin
                if (start_request)
                    next_state = START_STATE;
                else
                    next_state = IDLE_STATE;
            end

            START_STATE: begin
                next_state = DATA_STATE;
            end

            DATA_STATE: begin
                if (byte_done) begin
                    if (parity_enable)
                        next_state = PARITY_STATE;
                    else
                        next_state = STOP_STATE;
                end else begin
                    next_state = DATA_STATE;
                end
            end

            PARITY_STATE: begin
                next_state = STOP_STATE;
            end

            STOP_STATE: begin
                next_state = IDLE_STATE;
            end

            default: begin
                next_state = IDLE_STATE;
            end
        endcase
    end

    always @(*) begin
        load_data  = 1'b0;
        shift_data = 1'b0;
        busy       = 1'b0;
        frame_done = 1'b0;
        mux_sel    = SEL_STOP;

        case (current_state)
            IDLE_STATE: begin
                busy = 1'b0;
                mux_sel = SEL_STOP;

                if (start_request)
                    load_data = 1'b1;
            end

            START_STATE: begin
                busy = 1'b1;
                mux_sel = SEL_START;
            end

            DATA_STATE: begin
                busy = 1'b1;
                mux_sel = SEL_DATA;
                shift_data = 1'b1;
            end

            PARITY_STATE: begin
                busy = 1'b1;
                mux_sel = SEL_PARITY;
            end

            STOP_STATE: begin
                busy = 1'b1;
                mux_sel = SEL_STOP;
                frame_done = 1'b1;
            end

            default: begin
                busy = 1'b0;
                mux_sel = SEL_STOP;
            end
        endcase
    end

endmodule