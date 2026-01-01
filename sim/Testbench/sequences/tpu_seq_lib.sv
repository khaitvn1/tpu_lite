class simple_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(simple_tpu_seq)

    function new(string name = "simple_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        tr = tpu_seq_item::type_id::create("tr");
        `uvm_info(get_type_name(), "Running simple_tpu_seq", UVM_LOW)

        start_item(tr);
        // A = [[1,0],[0,1]]
        tr.a00 = 8'sd1;
        tr.a01 = 8'sd0;
        tr.a10 = 8'sd0;
        tr.a11 = 8'sd1;

        // B = [[3,4],[5,6]]
        tr.b00 = 8'sd3;
        tr.b01 = 8'sd4;
        tr.b10 = 8'sd5;
        tr.b11 = 8'sd6;

        tr.transpose_b = 1'b0;
        tr.do_reset = 1'b0;
        tr.timeout_cycles = 200;

        finish_item(tr);
    endtask
endclass : simple_tpu_seq


class identity_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(identity_tpu_seq)

    function new(string name="identity_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        tr = tpu_seq_item::type_id::create("tr");
        `uvm_info(get_type_name(), "Running identity_tpu_seq (A=I, random B)", UVM_LOW)

        start_item(tr);

        // A = I
        tr.a00 = 8'sd1; tr.a01 = 8'sd0;
        tr.a10 = 8'sd0; tr.a11 = 8'sd1;

        // randomize B (but moderate to avoid overflow)
        if (!tr.randomize() with {
            b00 inside {[-16:16]};
            b01 inside {[-16:16]};
            b10 inside {[-16:16]};
            b11 inside {[-16:16]};
            // allow both paths
            transpose_b dist {0:=1, 1:=1};
            do_reset == 0;
        }) begin
            `uvm_fatal(get_type_name(), "Randomize failed in identity_tpu_seq")
        end

        tr.timeout_cycles = 400;
        finish_item(tr);
    endtask
    endclass : identity_tpu_seq


    class zeros_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(zeros_tpu_seq)

    function new(string name="zeros_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        tr = tpu_seq_item::type_id::create("tr");
        `uvm_info(get_type_name(), "Running zeros_tpu_seq (random A, B=0)", UVM_LOW)

        start_item(tr);

        // B = 0 => C should be 0 regardless of A/transpose
        tr.b00 = '0; tr.b01 = '0;
        tr.b10 = '0; tr.b11 = '0;

        if (!tr.randomize() with {
            a00 inside {[-32:32]};
            a01 inside {[-32:32]};
            a10 inside {[-32:32]};
            a11 inside {[-32:32]};
            transpose_b dist {0:=1, 1:=1};
            do_reset == 0;
        }) begin
            `uvm_fatal(get_type_name(), "Randomize failed in zeros_tpu_seq")
        end

        tr.timeout_cycles = 300;
        finish_item(tr);
    endtask
endclass : zeros_tpu_seq


class negmix_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(negmix_tpu_seq)

    function new(string name="negmix_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        tr = tpu_seq_item::type_id::create("tr");
        `uvm_info(get_type_name(), "Running negmix_tpu_seq (signed negatives + positives)", UVM_LOW)

        start_item(tr);

        // mixing inputs to hit signed multiply/add paths
        tr.a00 = -8'sd3; tr.a01 =  8'sd7;
        tr.a10 =  8'sd5; tr.a11 = -8'sd2;

        tr.b00 = -8'sd4; tr.b01 =  8'sd6;
        tr.b10 =  8'sd1; tr.b11 = -8'sd8;

        tr.transpose_b = 1'b0;
        tr.do_reset = 1'b0;
        tr.timeout_cycles = 400;

        finish_item(tr);
    endtask
endclass : negmix_tpu_seq


class overflow_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(overflow_tpu_seq)

    function new(string name="overflow_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        tr = tpu_seq_item::type_id::create("tr");
        `uvm_info(get_type_name(), "Running overflow_tpu_seq (hit 8b extremes)", UVM_LOW)

        start_item(tr);

        // apply extreme inputs (127 and -128) to test overflow
        tr.a00 =  8'sd127; tr.a01 = -8'sd128;
        tr.a10 = -8'sd128; tr.a11 =  8'sd127;

        tr.b00 = -8'sd128; tr.b01 =  8'sd127;
        tr.b10 =  8'sd127; tr.b11 = -8'sd128;

        tr.transpose_b = 1'b1;
        tr.do_reset  = 1'b0;
        tr.timeout_cycles = 600;

        finish_item(tr);
    endtask
endclass : overflow_tpu_seq


class random_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(random_tpu_seq)

    function new(string name="random_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;

        `uvm_info(get_type_name(), "Running random_tpu_seq", UVM_LOW)

        repeat (50) begin
            tr = tpu_seq_item::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { do_reset == 0; transpose_b inside {0,1}; })
                else `uvm_fatal(get_type_name(), "Randomize failed in random_tpu_seq");
            tr.timeout_cycles = 600;
            finish_item(tr);
        end
    endtask
endclass


class transpose_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(transpose_tpu_seq)

    function new(string name="transpose_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr0, tr1;
        `uvm_info(get_type_name(), "Running transpose_tpu_seq (same A/B, transpose_b=0 then 1)", UVM_LOW)

        // transpose_b = 0
        tr0 = tpu_seq_item::type_id::create("tr_t0");
        start_item(tr0);
        if (!tr0.randomize() with {
            a00 inside {[-16:16]}; a01 inside {[-16:16]};
            a10 inside {[-16:16]}; a11 inside {[-16:16]};
            b00 inside {[-16:16]}; b01 inside {[-16:16]};
            b10 inside {[-16:16]}; b11 inside {[-16:16]};
            transpose_b == 0;
            do_reset == 0;
        }) `uvm_fatal(get_type_name(), "Randomize failed for tr0")
        tr0.timeout_cycles = 600;
        finish_item(tr0);

        // same A/B but transpose_b = 1
        tr1 = tpu_seq_item::type_id::create("tr_t1");
        start_item(tr1);
        tr1.a00 = tr0.a00; tr1.a01 = tr0.a01; tr1.a10 = tr0.a10; tr1.a11 = tr0.a11;
        tr1.b00 = tr0.b00; tr1.b01 = tr0.b01; tr1.b10 = tr0.b10; tr1.b11 = tr0.b11;
        tr1.transpose_b = 1;
        tr1.do_reset = 0;
        tr1.timeout_cycles = 600;
        finish_item(tr1);
    endtask
endclass : transpose_tpu_seq


class reset_tpu_seq extends base_tpu_seq;
    `uvm_object_utils(reset_tpu_seq)

    function new(string name="reset_tpu_seq");
        super.new(name);
    endfunction

    virtual task body();
        tpu_seq_item tr;
        `uvm_info(get_type_name(), "Running reset_tpu_seq (reset interleaved with ops)", UVM_LOW)

        // apply a reset
        tr = tpu_seq_item::type_id::create("tr_reset0");
        start_item(tr);
        tr.do_reset = 1'b1;
        tr.transpose_b = 1'b0;
        tr.timeout_cycles = 50;
        tr.a00='0; tr.a01='0; tr.a10='0; tr.a11='0;
        tr.b00='0; tr.b01='0; tr.b10='0; tr.b11='0;
        finish_item(tr);

        // apply a few random ops after reset
        for (int i = 0; i < 10; i++) begin
            tr = tpu_seq_item::type_id::create($sformatf("tr_op_%0d", i));
            start_item(tr);
            if (!tr.randomize() with {
                a00 inside {[-16:16]}; a01 inside {[-16:16]};
                a10 inside {[-16:16]}; a11 inside {[-16:16]};
                b00 inside {[-16:16]}; b01 inside {[-16:16]};
                b10 inside {[-16:16]}; b11 inside {[-16:16]};
                transpose_b dist {0:=1, 1:=1};
                do_reset == 0;
            }) `uvm_fatal(get_type_name(), $sformatf("Randomize failed post-reset i=%0d", i))
            tr.timeout_cycles = 600;
            finish_item(tr);
        end
    endtask
endclass : reset_tpu_seq