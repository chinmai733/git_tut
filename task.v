`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.01.2026 18:35:06
// Design Name: 
// Module Name: kiss_task1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module kiss_task1 (
    input  wire        clock,
    input  wire        reset,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,

    output reg  [7:0]  data_out,
    output reg         data_valid,
    output reg         start_frame,
    output reg         end_frame
);

    // KISS Decoder special characters
    localparam FEND  = 8'hC0;
    localparam FESC  = 8'hDB;
    localparam TFEND = 8'hDC;
    localparam TFESC = 8'hDD;

    // FSM states
    localparam IDLE     = 2'd0;
    localparam IN_FRAME = 2'd1;
    localparam ESCAPE   = 2'd2;

    reg [1:0] state;
    reg [8:0] payload_cnt;   // counts up to 256

    always @(posedge clock) begin
        if (reset) begin
            state        <= IDLE;
            payload_cnt  <= 9'd0;
            data_out     <= 8'd0;
            data_valid   <= 1'b0;
            start_frame  <= 1'b0;
            end_frame    <= 1'b0;
        end else begin
            // default 
            data_valid  <= 1'b0;
            start_frame <= 1'b0;
            end_frame   <= 1'b0;

            if (rx_valid) begin
                case (state)

                    // ---------------- IDLE ----------------
                    IDLE: begin
                        if (rx_data == FEND) begin
                            start_frame <= 1'b1;
                            payload_cnt <= 9'd0;
                            state <= IN_FRAME;
                        end
                    end

                    // -------------- IN_FRAME ---------------
                    IN_FRAME: begin
                        if (rx_data == FEND) begin
                            end_frame <= 1'b1;
                            state <= IDLE;
                        end
                        else if (rx_data == FESC) begin
                            state <= ESCAPE;
                        end
                        else begin
                            if (payload_cnt < 9'd256) begin
                                data_out   <= rx_data;
                                data_valid <= 1'b1;
                                payload_cnt <= payload_cnt + 1'b1;
                            end
                        end
                    end

                    // -------------- ESCAPE -----------------
                    ESCAPE: begin
                        if (payload_cnt < 9'd256) begin
                            if (rx_data == TFEND)
                                data_out <= FEND;
                            else if (rx_data == TFESC)
                                data_out <= FESC;
                            else
                                data_out <= rx_data; // safety fallback

                            data_valid <= 1'b1;
                            payload_cnt <= payload_cnt + 1'b1;
                        end
                        state <= IN_FRAME;
                    end

                    default: state <= IDLE;

                endcase
            end
        end
    end

endmodule
