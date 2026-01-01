interface tpu_if #(int DATA_WIDTH = 8)(input logic clk);
    logic rst;
    logic wr_en;
    logic [2:0] wr_addr;
    logic signed [DATA_WIDTH-1:0] wr_data;
    logic start;
    logic transpose_b;
    logic busy;
    logic done;
    logic signed [(2*DATA_WIDTH)-1:0] c00, c01, c10, c11;

    clocking drv_cb @(posedge clk);
        output rst;
        output wr_en;
        output wr_addr;
        output wr_data;
        output start;
        output transpose_b;
        input busy;
        input done;
        input c00, c01, c10, c11;
    endclocking

    clocking mon_cb @(posedge clk);
        input rst;
        input wr_en;
        input wr_addr;
        input wr_data;
        input start;
        input transpose_b;
        input busy;
        input done;
        input c00, c01, c10, c11;
    endclocking

    modport dut (
        input clk,
        input rst,
        input wr_en,
        input wr_addr,
        input wr_data,
        input start,
        input transpose_b,
        output busy,
        output done,
        output c00, c01, c10, c11
    );

    modport drv (clocking drv_cb);

    modport mon (clocking mon_cb);

endinterface