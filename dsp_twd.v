module dsp_twd (
    input wire clk,
    input wire is_last_iteration,
    input wire [9:0] twd_addr,
    
    input wire [17:0] in0_re, input wire [17:0] in0_im,
    input wire [17:0] in1_re, input wire [17:0] in1_im,
    input wire [17:0] in2_re, input wire [17:0] in2_im,
    input wire [17:0] in3_re, input wire [17:0] in3_im,

    output reg [15:0] out0_re, output reg [15:0] out0_im,
    output reg [15:0] out1_re, output reg [15:0] out1_im,
    output reg [15:0] out2_re, output reg [15:0] out2_im,
    output reg [15:0] out3_re, output reg [15:0] out3_im
);

    reg [15:0] rom_cos [0:1023];
    reg [15:0] rom_sin [0:1023];
    
    integer k;
    initial begin
        // Initialize the entire ROM to 1.0 (0x7FFF) for cosine and 0 for sine 
        // to prevent 'X' propagation during testbench runs
        for (k = 0; k < 1024; k = k + 1) begin
            rom_cos[k] = 16'h7FFF; 
            rom_sin[k] = 16'h0000;
        end
    end

    reg [15:0] cos_reg, sin_reg;
    always @(posedge clk) begin
        cos_reg <= rom_cos[twd_addr];
        sin_reg <= rom_sin[twd_addr];
    end

    // Pipeline registers for all channels
    reg [17:0] r0_re, r0_im, r1_re, r1_im, r2_re, r2_im, r3_re, r3_im;
    always @(posedge clk) begin
        r0_re <= in0_re; r0_im <= in0_im;
        r1_re <= in1_re; r1_im <= in1_im;
        r2_re <= in2_re; r2_im <= in2_im;
        r3_re <= in3_re; r3_im <= in3_im;
    end

    // Multipliers for all 3 channels requiring twiddle rotations
    wire signed [33:0] prod_1re_cos = $signed(r1_re) * $signed(cos_reg);
    wire signed [33:0] prod_1im_sin = $signed(r1_im) * $signed(sin_reg);
    wire signed [33:0] prod_1re_sin = $signed(r1_re) * $signed(sin_reg);
    wire signed [33:0] prod_1im_cos = $signed(r1_im) * $signed(cos_reg);

    wire signed [33:0] prod_2re_cos = $signed(r2_re) * $signed(cos_reg);
    wire signed [33:0] prod_2im_sin = $signed(r2_im) * $signed(sin_reg);
    wire signed [33:0] prod_2re_sin = $signed(r2_re) * $signed(sin_reg);
    wire signed [33:0] prod_2im_cos = $signed(r2_im) * $signed(cos_reg);

    wire signed [33:0] prod_3re_cos = $signed(r3_re) * $signed(cos_reg);
    wire signed [33:0] prod_3im_sin = $signed(r3_im) * $signed(sin_reg);
    wire signed [33:0] prod_3re_sin = $signed(r3_re) * $signed(sin_reg);
    wire signed [33:0] prod_3im_cos = $signed(r3_im) * $signed(cos_reg);

    // Squared Power Magnitudes calculation arrays for the final stage
    wire [35:0] pwr0 = $signed(in0_re)*$signed(in0_re) + $signed(in0_im)*$signed(in0_im);
    wire [35:0] pwr1 = $signed(in1_re)*$signed(in1_re) + $signed(in1_im)*$signed(in1_im);
    wire [35:0] pwr2 = $signed(in2_re)*$signed(in2_re) + $signed(in2_im)*$signed(in2_im);
    wire [35:0] pwr3 = $signed(in3_re)*$signed(in3_re) + $signed(in3_im)*$signed(in3_im);

    always @(posedge clk) begin
        if (is_last_iteration) begin
            out0_re <= pwr0[31:16]; out0_im <= 16'd0;
            out1_re <= pwr1[31:16]; out1_im <= 16'd0;
            out2_re <= pwr2[31:16]; out2_im <= 16'd0;
            out3_re <= pwr3[31:16]; out3_im <= 16'd0;
        end else begin
            out0_re <= r0_re[17:2]; 
            out0_im <= r0_im[17:2];
            out1_re <= (prod_1re_cos - prod_1im_sin) >>> 15;
            out1_im <= (prod_1re_sin + prod_1im_cos) >>> 15;
            out2_re <= (prod_2re_cos - prod_2im_sin) >>> 15;
            out2_im <= (prod_2re_sin + prod_2im_cos) >>> 15;
            out3_re <= (prod_3re_cos - prod_3im_sin) >>> 15;
            out3_im <= (prod_3re_sin + prod_3im_cos) >>> 15;
        end
    end
endmodule