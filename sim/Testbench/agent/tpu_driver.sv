class tpu_driver extends uvm_driver #(tpu_seq_item);
    `uvm_component_utils(tpu_driver)

    virtual tpu_if.drv vif;

    function new(string name = "tpu_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual tpu_if.drv)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "vif not set (expected virtual tpu_if.drv)")
        end
    endfunction

    task automatic drive_reset(int unsigned n_cycles = 5);
        vif.drv_cb.wr_en <= 1'b0;
        vif.drv_cb.wr_addr <= '0;
        vif.drv_cb.wr_data <= '0;
        vif.drv_cb.start <= 1'b0;
        vif.drv_cb.transpose_b <= 1'b0;
        vif.drv_cb.rst <= 1'b1;
        repeat (n_cycles) @(vif.drv_cb);
        vif.drv_cb.rst <= 1'b0;
        @(vif.drv_cb);
    endtask

    task automatic write_reg(logic [2:0] addr, logic signed [tpu_seq_item::DATA_WIDTH-1:0] data);
        vif.drv_cb.wr_addr <= addr;
        vif.drv_cb.wr_data <= data;
        vif.drv_cb.wr_en <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.wr_en <= 1'b0;
        @(vif.drv_cb);
    endtask

    task automatic pulse_start;
        vif.drv_cb.start <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.start <= 1'b0;
    endtask

    task automatic wait_done(int unsigned timeout_cycles = 200);
        int unsigned t = 0;
        do begin
            @(vif.drv_cb);
            t++;
            if (t > timeout_cycles) begin
                `uvm_fatal(get_type_name(), $sformatf("Timeout waiting for done after %0d cycles", timeout_cycles))
            end
        end while (vif.drv_cb.done !== 1'b1);
    endtask

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        drive_reset(5);
        
        forever begin
            tpu_seq_item tr;
            seq_item_port.get_next_item(tr);
            vif.drv_cb.transpose_b <= tr.transpose_b;

            // Write A and B (addr map: 0..3 A00,A01,A10,A11 ; 4..7 B00,B01,B10,B11)
            write_reg(3'd0, tr.a00);
            write_reg(3'd1, tr.a01);
            write_reg(3'd2, tr.a10);
            write_reg(3'd3, tr.a11);

            write_reg(3'd4, tr.b00);
            write_reg(3'd5, tr.b01);
            write_reg(3'd6, tr.b10);
            write_reg(3'd7, tr.b11);

            pulse_start();

            wait_done(tr.timeout_cycles);

            seq_item_port.item_done();
        end
    endtask
endclass : tpu_driver