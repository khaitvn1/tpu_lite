class tpu_env extends uvm_env;
    `uvm_component_utils(tpu_env)

    tpu_agent agt;
    tpu_sb sb;

    function new(string name = "tpu_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = tpu_agent::type_id::create("agt", this);
        sb = tpu_sb::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.item_collect_port.connect(sb.item_collect_export);
    endfunction

endclass : tpu_env