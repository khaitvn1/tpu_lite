module tpu_tb_top;

    timeunit 1ns;
    timeprecision 100ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import tpu_test_pkg::*;
    import tpu_seq_pkg::*;
    import tpu_agent_pkg::*;
    import tpu_env_pkg::*;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    localparam int DATA_WIDTH = 8;

    tpu_if #(DATA_WIDTH) vif (.clk(clk));

    tpu_lite_dut_uvm #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .wr_en(vif.wr_en),
        .wr_addr(vif.wr_addr),
        .wr_data(vif.wr_data),
        .start(vif.start),
        .transpose_b(vif.transpose_b),
        .busy(vif.busy),
        .done(vif.done),
        .c00(vif.c00),
        .c01(vif.c01),
        .c10(vif.c10),
        .c11(vif.c11)
    );

    initial begin
        vif.rst = 1'b1;
        vif.wr_en = 1'b0;
        vif.wr_addr = '0;
        vif.wr_data = '0;
        vif.start = 1'b0;
        vif.transpose_b = 1'b0;

        repeat (5) @(posedge clk);
        vif.rst = 1'b0;
    end

    initial begin
        $shm_open("waves.shm");
        $shm_probe("AS");
        uvm_config_db#(virtual tpu_if.drv)::set(null, "*", "vif", vif);
        uvm_config_db#(virtual tpu_if.mon)::set(null, "*", "vif", vif);
        run_test();
    end

endmodule : tpu_tb_top
