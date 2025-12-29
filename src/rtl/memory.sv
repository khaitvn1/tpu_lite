module memory # (
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic load_en,
    input logic [2:0] addr,
    input logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] a_data_out0,
    output logic [DATA_WIDTH-1:0] a_data_out1,
    output logic [DATA_WIDTH-1:0] a_data_out2,
    output logic [DATA_WIDTH-1:0] a_data_out3,
    output logic [DATA_WIDTH-1:0] b_data_in0,
    output logic [DATA_WIDTH-1:0] b_data_in1,
    output logic [DATA_WIDTH-1:0] b_data_in2,
    output logic [DATA_WIDTH-1:0] b_data_in3
);
    logic [DATA_WIDTH-1:0] ram [0:DATA_WIDTH-1]; // 0-3 for matrix A elements, 4-7 for matrix B elements
    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                ram[i] <= '0;
            end
        end else if (load_en) begin
            ram[addr] <= data_in;
        end
    end

    assign a_data_out0 = ram[0];
    assign a_data_out1 = ram[1];
    assign a_data_out2 = ram[2];
    assign a_data_out3 = ram[3];
    assign b_data_in0 = ram[4];
    assign b_data_in1 = ram[5];
    assign b_data_in2 = ram[6];
    assign b_data_in3 = ram[7];

endmodule