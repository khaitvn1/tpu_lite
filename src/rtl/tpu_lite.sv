module tpu_lite #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk, // 100 MHz clock on Basys 3
    input logic btnC, // write
    input logic btnU, // start
    input logic btnD, // reset
    input logic [15:0] sw,
    output logic [15:0] led
);

    function automatic logic rising_edge(input logic curr, input logic prev);
        rising_edge = curr && !prev;
    endfunction

    // previous button states for edge detection
    logic btnC_q, btnU_q, btnD_q;
    logic btnC_s, btnU_s, btnD_s;

    always_ff @(posedge clk) begin
        btnC_q <= btnC;
        btnU_q <= btnU;
        btnD_q <= btnD;
        btnC_s <= btnC_q;
        btnU_s <= btnU_q;
        btnD_s <= btnD_q;
    end

    logic load_pulse, start_pulse, reset_pulse;
    assign load_pulse = rising_edge(btnC_s, btnC_q);
    assign start_pulse = rising_edge(btnU_s, btnU_q);
    assign reset_pulse = rising_edge(btnD_s, btnD_q);

    // switches for input data
    logic transpose_b;
    logic [1:0] out_sel;
    logic [2:0] mem_addr;
    logic signed [DATA_WIDTH-1:0] mem_wdata;

    assign transpose_b = sw[15];
    assign out_sel = sw[13:12];
    assign mem_addr = sw[11:9];
    assign mem_wdata = sw[DATA_WIDTH-1:0];

    logic signed [DATA_WIDTH-1:0] a00, a01, a10, a11;
    logic signed [DATA_WID TH-1:0] b00, b01, b10, b11;

    memory #(.DATA_WIDTH(DATA_WIDTH)) mem_a_inst (
        .clk(clk),
        .rst(reset_pulse),
        .load_en(load_pulse),
        .addr(mem_addr),
        .data_in(mem_wdata),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11)
    );

    logic signed [DATA_WIDTH-1:0] a_row0_in, a_row1_in, b_col0_in, b_col1_in;
    logic clear00, clear01, clear10, clear11;
    logic busy, done;

    mmu #(.DATA_WIDTH(DATA_WIDTH)) mmu_inst (
        .clk(clk),
        .rst(reset_pulse),
        .start(start_pulse),
        .transpose_b(transpose_b),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11),
        .a_data0(a_row0_in), .a_data1(a_row1_in),
        .b_data0(b_col0_in), .b_data1(b_col1_in),
        .clear00(clear00), .clear01(clear01),
        .clear10(clear10), .clear11(clear11),
        .busy(busy),
        .done(done)
    );

    // systolic array
    logic signed [(2*DATA_WIDTH)-1:0] c00_w, c01_w, c10_w, c11_w;

    systolic_array #(.DATA_WIDTH(DATA_WIDTH)) sa_inst (
        .clk(clk),
        .rst(reset_pulse),
        .a_row0_in(a_row0_in), .a_row1_in(a_row1_in),
        .b_col0_in(b_col0_in), .b_col1_in(b_col1_in),
        .clear00(clear00), .clear01(clear01),
        .clear10(clear10), .clear11(clear11),
        .c00_out(c00_w), .c01_out(c01_w),
        .c10_out(c10_w), .c11_out(c11_w)
    );

    // latch done on outputs
    logic signed [(2*DATA_WIDTH)-1:0] c00_r, c01_r, c10_r, c11_r;
    logic done_r;

    always_ff @(posedge clk) begin
        if (reset_pulse) begin
            c00_r <= '0;
            c01_r <= '0;
            c10_r <= '0;
            c11_r <= '0;
            done_r <= 1'b0;
        end else begin
            if (start_pulse) begin
                done_r <= 1'b0;
            end
            if (done) begin
                c00_r <= c00_w;
                c01_r <= c01_w;
                c10_r <= c10_w;
                c11_r <= c11_w;
                done_r <= 1'b1;
            end
        end
    end

    // LED output logic
    logic [15:0] led_out;
    always_comb begin
        unique case (out_sel)
            2'b00: led_out = c00_r[15:0];
            2'b01: led_out = c01_r[15:0];
            2'b10: led_out = c10_r[15:0];
            2'b11: led_out = c11_r[15:0];
            default: led_out = 16'h0000;
        endcase
    end

    always_comb begin
        led = led_out;
        led[15] = busy;
        led[14] = done_r;
    end

endmodule