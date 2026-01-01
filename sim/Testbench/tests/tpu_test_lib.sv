class simple_tpu_test extends base_tpu_test;
    `uvm_component_utils(simple_tpu_test)

    function new(string name = "simple_tpu_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "env.agt.seqr.run_phase",
                                "default_sequence",
                                simple_tpu_seq::get_type());
        super.build_phase(phase);
    endfunction : build_phase
    
endclass : simple_tpu_test

class all_tpu_test extends base_tpu_test;
    `uvm_component_utils(all_tpu_test)

    function new(string name = "all_tpu_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this, "all_tpu_test start");

        begin
            simple_tpu_seq s0 = simple_tpu_seq ::type_id::create("s0", this);
            s0.start(env.agt.seqr);
        end

        begin
            identity_tpu_seq s1 = identity_tpu_seq::type_id::create("s1", this);
            s1.start(env.agt.seqr);
        end

        begin
            zeros_tpu_seq s2 = zeros_tpu_seq::type_id::create("s2", this);
            s2.start(env.agt.seqr);
        end

        begin
            mix_tpu_seq s3 = mix_tpu_seq::type_id::create("s3", this);
            s3.start(env.agt.seqr);
        end

        begin
            overflow_tpu_seq s4 = overflow_tpu_seq::type_id::create("s4", this);
            s4.start(env.agt.seqr);
        end

        begin
            transpose_tpu_seq s5 = transpose_tpu_seq::type_id::create("s5", this);
            s5.start(env.agt.seqr);
        end

        begin
            reset_tpu_seq s6 = reset_tpu_seq::type_id::create("s6", this);
            s6.start(env.agt.seqr);
        end

        begin
            random_tpu_seq s7 = random_tpu_seq::type_id::create("s7", this);
            s7.start(env.agt.seqr);
        end

        phase.drop_objection(this, "all_tpu_test done");
    endtask : run_phase

endclass : all_tpu_test