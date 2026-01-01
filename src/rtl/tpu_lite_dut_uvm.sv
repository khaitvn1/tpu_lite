module tpu_lite_dut_uvm #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [2:0] wr_addr,
    input logic signed [DATA_WIDTH-1:0] wr_data,
    input logic start,
    input logic transpose_b,
    output logic busy,
    output logic done,
    output logic signed [(2*DATA_WIDTH)-1:0] c00,
    output logic signed [(2*DATA_WIDTH)-1:0] c01,
    output logic signed [(2*DATA_WIDTH)-1:0] c10,
    output logic signed [(2*DATA_WIDTH)-1:0] c11
);
    logic signed [DATA_WIDTH-1:0] a00, a01, a10, a11, b00, b01, b10, b11;

    memory #(.DATA_WIDTH(DATA_WIDTH)) mem_inst (
        .clk(clk),
        .rst(rst),
        .load_en(wr_en),
        .addr(wr_addr),
        .data_in(wr_data),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11)
    );

    logic signed [DATA_WIDTH-1:0] a_row0_in, a_row1_in, b_col0_in, b_col1_in;
    logic clear00, clear01, clear10, clear11;

    mmu #(.DATA_WIDTH(DATA_WIDTH)) mmu_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .transpose_b(transpose_b),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11),
        .a_data0(a_row0_in), .a_data1(a_row1_in),
        .b_data0(b_col0_in), .b_data1(b_col1_in),
        .clear00(clear00), .clear01(clear01),
        .clear10(clear10), .clear11(clear11),
        .busy(busy),
        .done(done)
    );

    systolic_array #(.DATA_WIDTH(DATA_WIDTH)) sa_inst (
        .clk(clk),
        .rst(rst),
        .a_row0_in(a_row0_in), .a_row1_in(a_row1_in),
        .b_col0_in(b_col0_in), .b_col1_in(b_col1_in),
        .clear00(clear00), .clear01(clear01),
        .clear10(clear10), .clear11(clear11),
        .c00_out(c00), .c01_out(c01), .c10_out(c10), .c11_out(c11)
    );
endmodule