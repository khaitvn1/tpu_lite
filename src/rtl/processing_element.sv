module processing_element #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst,
    input logic clear, // load first product for new dot product
    input logic signed [DATA_WIDTH-1:0] a_in,
    input logic signed [DATA_WIDTH-1:0] b_in,
    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic signed [(2*DATA_WIDTH)-1:0] c_out
);

    logic signed [(2*DATA_WIDTH)-1:0] product;
    assign product = a_in * b_in;

    always_ff @(posedge clk) begin
        if (rst) begin
            a_out <= '0;
            b_out <= '0;
            c_out <= '0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            if (clear) begin
                c_out <= product;
            end else begin
                c_out <= c_out + prduct;
            end
        end
    end
    
endmodule