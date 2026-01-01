class tpu_monitor extends uvm_monitor;
    `uvm_component_utils(tpu_monitor)

    virtual tpu_if.mon vif;

    uvm_analysis_port #(tpu_seq_item) item_collect_port;

    logic signed [7:0] mem [0:7];
    bit transpose_b_q;

    function new(string name = "tpu_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collect_port = new("item_collect_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual tpu_if.mon)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "vif not set (expected virtual tpu_if.mon)")
        end
    endfunction

    task automatic init();
        for (int i = 0; i < 8; i++) begin
            mem[i] = '0;
        end
        transpose_b_q <= 1'b0;
    endtask

    task run_phase(uvm_phase phase);
        tpu_seq_item tr;

        init();

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.rst) begin
                init();
                continue;
            end

            transpose_b_q = vif.mon_cb.transpose_b;

            if (vif.mon_cb.wr_en) begin
                mem[vif.mon_cb.wr_addr] = vif.mon_cb.wr_data;
            end

            if (vif.mon_cb.start) begin
                tr = tpu_seq_item::type_id::create("tr", this);
                tr.transpose_b = transpose_b_q;
                
                tr.a00 = mem[0];
                tr.a01 = mem[1];
                tr.a10 = mem[2];
                tr.a11 = mem[3];

                tr.b00 = mem[4];
                tr.b01 = mem[5];
                tr.b10 = mem[6];
                tr.b11 = mem[7];

                do @(vif.mon_cb); while (vif.mon_cb.done !== 1'b1);

                tr.c00 = vif.mon_cb.c00;
                tr.c01 = vif.mon_cb.c01;
                tr.c10 = vif.mon_cb.c10;
                tr.c11 = vif.mon_cb.c11;

                item_collect_port.write(tr);
            end
        end
    endtask
endclass : tpu_monitor