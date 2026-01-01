module tpu_tb_top;

    timeunit 1ns;
    timeprecision 100ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import tpu_test_pkg::*;
    import tpu_seq_pkg::*;
    import tpu_agent_pkg::*;
    import tpu_env_pkg::*;

endmodule : tpu_tb_top
