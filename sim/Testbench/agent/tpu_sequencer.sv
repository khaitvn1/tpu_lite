class tpu_sequencer extends uvm_sequencer #(tpu_seq_item);
    `uvm_component_utils(tpu_sequencer)

    function new(string name = "tpu_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : tpu_sequencer