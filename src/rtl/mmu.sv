module mmu #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic start,
    input logic transpose_b,
    input logic signed [DATA_WIDTH-1:0] a00, a01, a10, a11,
    input logic signed [DATA_WIDTH-1:0] b00, b01, b10, b11,
    output logic signed [DATA_WIDTH-1:0] a_data0, a_data1, b_data0, b_data1,
    output logic clear00, clear01, clear10, clear11,
    output logic busy,
    output logic done
);
    // transpose b matrix if needed
    logic signed [DATA_WIDTH-1:0] b00_t, b01_t, b10_t, b11_t;
    always_comb begin 
        b00_t = b00;
        b11_t = b11;
        if (transpose_b) begin
            b01_t = b10;
            b10_t = b01;
        end else begin
            b01_t = b01;
            b10_t = b10;
        end
    end

    typedef enum logic [1:0] {
        IDLE,
        RUN,
        DONE
    } state_t;
    state_t state;

    logic [2:0] cycle;
    localparam int unsigned LAST_CYCLE = 3;

    always_comb begin
        a_data0 = '0;
        a_data1 = '0;
        b_data0 = '0;
        b_data1 = '0;

        clear00 = 1'b0;
        clear01 = 1'b0;
        clear10 = 1'b0;
        clear11 = 1'b0;

        busy = (state == RUN);
        done = (state == DONE);

        if (state == RUN) begin
            unique case (cycle)
                3'd0: begin
                    // First valid multiply at PE00 only
                    a_data0 = a00;
                    a_data1 = '0;
                    b_data0 = b00_t;
                    b_data1 = '0;
                    clear00 = 1'b1;
                end
                3'd1: begin
                    // PE01 and PE10 see their first valid multiply
                    a_data0 = a01;
                    a_data1 = a10;
                    b_data0 = b10_t;
                    b_data1 = b01_t;
                    clear01 = 1'b1;
                    clear10 = 1'b1;
                end
                3'd2: begin
                    // PE11 sees its first valid multiply
                    a_data0 = '0;
                    a_data1 = a11;
                    b_data0 = '0;
                    b_data1 = b11_t;
                    clear11 = 1'b1;
                end
                default: begin
                    // let cycles 3, 4, flush the zeros
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cycle <= '0;
        end else begin
            unique case (state)
                IDLE: begin
                    cycle <= '0;
                    if (start) begin
                        state <= RUN;
                        cycle <= '0;
                    end
                end

                RUN: begin
                    if (cycle == LAST_CYCLE[2:0]) begin
                        state <= DONE;
                        cycle <= '0;
                    end else begin
                        cycle <= cycle + 1;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    cycle <= '0;
                end
            endcase
        end
    end
    
endmodule