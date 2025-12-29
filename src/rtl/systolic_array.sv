module systolic_array #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic signed [DATA_WIDTH-1:0] a_row0_in,
    input logic signed [DATA_WIDTH-1:0] a_row1_in,
    input logic signed [DATA_WIDTH-1:0] b_col0_in,
    input logic signed [DATA_WIDTH-1:0] b_col1_in,
    input logic clear00,
    input logic clear01,
    input logic clear10,
    input logic clear11,
    output logic signed [(2*DATA_WIDTH)-1:0] c00_out,
    output logic signed [(2*DATA_WIDTH)-1:0] c01_out,
    output logic signed [(2*DATA_WIDTH)-1:0] c10_out,
    output logic signed [(2*DATA_WIDTH)-1:0] c11_out
);
    logic signed [DATA_WIDTH-1:0] a00_to_a01;
    logic signed [DATA_WIDTH-1:0] a10_to_a11;
    logic signed [DATA_WIDTH-1:0] b00_to_b10;
    logic signed [DATA_WIDTH-1:0] b01_to_b11;

    processing_element # (.DATA_WIDTH(DATA_WIDTH)) pe00 (
        .clk(clk),
        .rst(rst),
        .clear(clear00),
        .a_in(a_row0_in),
        .b_in(b_col0_in),
        .a_out(a00_to_a01),
        .b_out(b00_to_b10),
        .c_out(c00_out)
    );

    processing_element # (.DATA_WIDTH(DATA_WIDTH)) pe01 (
        .clk(clk),
        .rst(rst),
        .clear(clear01),
        .a_in(a00_to_a01),
        .b_in(b_col1_in),
        .a_out(),
        .b_out(b01_to_b11),
        .c_out(c01_out)
    );

    processing_element # (.DATA_WIDTH(DATA_WIDTH)) pe10 (
        .clk(clk),
        .rst(rst),
        .clear(clear10),
        .a_in(a_row1_in),
        .b_in(b00_to_b10),
        .a_out(a10_to_a11),
        .b_out(),
        .c_out(c10_out)
    );

    processing_element # (.DATA_WIDTH(DATA_WIDTH)) pe11 (
        .clk(clk),
        .rst(rst),
        .clear(clear11),
        .a_in(a10_to_a11),
        .b_in(b01_to_b11),
        .a_out(),
        .b_out(),
        .c_out(c11_out)
    );
    
endmodule