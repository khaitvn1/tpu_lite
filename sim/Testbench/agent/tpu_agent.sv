class tpu_agent extends uvm_agent;
    `uvm_component_utils(tpu_agent)

    tpu_driver drv;
    tpu_monitor mon;
    tpu_sequencer seqr;

    function new(string name = "tpu_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            drv  = tpu_driver::type_id::create("drv", this);
            seqr = tpu_sequencer::type_id::create("seqr", this);
        end
        mon = tpu_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass : tpu_agent