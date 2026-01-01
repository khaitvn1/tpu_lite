class tpu_seq_item extends uvm_sequence_item;
    `uvm_object_utils(tpu_seq_item)
    localparam int DATA_WIDTH = 8;

    // stimulus
    rand logic signed [DATA_WIDTH-1:0] a00, a01, a10, a11;
    rand logic signed [DATA_WIDTH-1:0] b00, b01, b10, b11;
    rand bit transpose_b;

    rand bit do_reset;
    int unsigned timeout_cycles = 200;

    // outputs
    logic signed [(2*DATA_WIDTH)-1:0] c00, c01, c10, c11;

    function new(string name="tpu_seq_item");
        super.new(name);
    endfunction

    // print out for debugging
    function string print_transactions();
        return $sformatf(
          "transpose_b=%0d A=[[%0d,%0d],[%0d,%0d]] B=[[%0d,%0d],[%0d,%0d]] C(observed)=[[%0d,%0d],[%0d,%0d]]",
          transpose_b, a00, a01, a10, a11, b00, b01, b10, b11, c00, c01, c10, c11
        );
    endfunction

endclass : tpu_seq_item