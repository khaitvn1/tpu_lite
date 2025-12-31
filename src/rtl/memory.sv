module memory # (
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic load_en,
    input logic [2:0] addr,
    input logic signed [DATA_WIDTH-1:0] data_in,
    output logic signed [DATA_WIDTH-1:0] a00, a01, a10, a11,
    output logic signed [DATA_WIDTH-1:0] b00, b01, b10, b11
);
    logic [DATA_WIDTH-1:0] ram [0:7]; // 0-3 for matrix A elements, 4-7 for matrix B elements
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

    assign a00 = ram[0];
    assign a01 = ram[1];
    assign a10 = ram[2];
    assign a11 = ram[3];

    assign b00 = ram[4];
    assign b01 = ram[5];
    assign b10 = ram[6];
    assign b11 = ram[7];

endmodule