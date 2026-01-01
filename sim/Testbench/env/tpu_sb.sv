class tpu_sb extends uvm_scoreboard;
    `uvm_component_utils(tpu_sb)
    uvm_analysis_imp #(tpu_seq_item, tpu_sb) item_collect_export;

    localparam int DATA_WIDTH = 8;

    int num_in, num_correct, num_incorrect;

    function new(string name="tpu_sb", uvm_component parent=null);
        super.new(name, parent);
        item_collect_export = new("item_collect_export", this);
        num_in = 0;
        num_correct = 0;
        num_incorrect = 0;
    endfunction

    // golden model for multiply-add
    function automatic logic signed [(2*DATA_WIDTH-1):0]
        mac2(logic signed [DATA_WIDTH-1:0] x0, 
            logic signed [DATA_WIDTH-1:0] y0,
            logic signed [DATA_WIDTH-1:0] x1,
            logic signed [DATA_WIDTH-1:0] y1);
        logic signed [(2*DATA_WIDTH)-1:0] p0, p1;
        begin
            p0 = x0 * y0;
            p1 = x1 * y1;
            mac2 = p0 + p1;
        end
    endfunction

    function void write(tpu_seq_item tr);
        logic signed [DATA_WIDTH-1:0] b00, b01, b10, b11;
        logic signed [(2*DATA_WIDTH)-1:0] exp00, exp01, exp10, exp11;

        num_in++;

        if (tr.transpose_b) begin
            b00 = tr.b00;
            b01 = tr.b10;
            b10 = tr.b01;
            b11 = tr.b11;
        end else begin
            b00 = tr.b00;
            b01 = tr.b01;
            b10 = tr.b10;
            b11 = tr.b11;
        end

        // expected C = A * B;
        exp00 = mac2(tr.a00, b00, tr.a01, b10);
        exp01 = mac2(tr.a00, b01, tr.a01, b11);
        exp10 = mac2(tr.a10, b00, tr.a11, b10);
        exp11 = mac2(tr.a10, b01, tr.a11, b11);

        // `uvm_info("TPU_SB", $sformatf("Observed transactions: %s", tr.print_transactions()), UVM_LOW);

        if ((tr.c00 !== exp00) || (tr.c01 !== exp01) || (tr.c10 !== exp10) || (tr.c11 !== exp11)) begin
            num_incorrect++;
            `uvm_info("TPU_SB", $sformatf("Observed transactions: %s", tr.print_transactions()), UVM_LOW);
            `uvm_error("TPU_SB", $sformatf(
                { "MISMATCH!\nA=[[ %0d, %0d ],[ %0d, %0d ]]\n",
                    "B=[[ %0d, %0d ],[ %0d, %0d ]]  (transpose_b=%0d)\n",
                    "EXP: C00=%0d (0x%0h) C01=%0d (0x%0h) C10=%0d (0x%0h) C11=%0d (0x%0h)\n",
                    "GOT: C00=%0d (0x%0h) C01=%0d (0x%0h) C10=%0d (0x%0h) C11=%0d (0x%0h)" },
                tr.a00, tr.a01, tr.a10, tr.a11,
                b00, b01, b10, b11, tr.transpose_b,
                exp00, exp00, exp01, exp01, exp10, exp10, exp11, exp11,
                tr.c00, tr.c00, tr.c01, tr.c01, tr.c10, tr.c10, tr.c11, tr.c11
            ));
        end else begin
            num_correct++;
            `uvm_info("TPU_SB", $sformatf(
                "PASS A*B (transpose_b=%0d): C=[[%0d,%0d],[%0d,%0d]]",
                tr.transpose_b, tr.c00, tr.c01, tr.c10, tr.c11
            ), UVM_LOW);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard: Total=%0d Correct=%0d Incorrect=%0d", num_in, num_correct, num_incorrect), UVM_LOW)
        
        if (num_incorrect > 0) begin
            `uvm_error(get_type_name(), "Simulation FAILED")
        end else begin
            `uvm_info(get_type_name(), "Simulation PASSED", UVM_LOW)
        end
    endfunction
endclass : tpu_sb
