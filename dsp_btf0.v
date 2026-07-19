module dsp_btf0 (
    input wire [1:0] ctrl_bits, // c1, c0
    // Inputs from individual BRAM blocks
    input wire [15:0] m0_re, input wire [15:0] m0_im,
    input wire [15:0] m1_re, input wire [15:0] m1_im,
    input wire [15:0] m2_re, input wire [15:0] m2_im,
    input wire [15:0] m3_re, input wire [15:0] m3_im,
    // Output channels
    output reg [16:0] out_A_re, output reg [16:0] out_A_im,
    output reg [16:0] out_B_re, output reg [16:0] out_B_im,
    output reg [16:0] out_C_re, output reg [16:0] out_C_im,
    output reg [16:0] out_D_re, output reg [16:0] out_D_im
);

    // Dynamic arithmetic calculation mapping derived from paper Table I
    always @(*) begin
        case (ctrl_bits)
            2'b00: begin
                out_A_re = $signed(m0_re) + $signed(m2_re);
                out_A_im = $signed(m0_im) + $signed(m2_im);
                out_B_re = $signed(m1_re) + $signed(m3_re);
                out_B_im = $signed(m1_im) + $signed(m3_im);
                out_C_re = $signed(m0_re) - $signed(m2_re);
                out_C_im = $signed(m0_im) - $signed(m2_im);
                out_D_re = $signed(m1_re) - $signed(m3_re);
                out_D_im = $signed(m1_im) - $signed(m3_im);
            end
            2'b01: begin
                out_A_re = $signed(m1_re) + $signed(m3_re);
                out_A_im = $signed(m1_im) + $signed(m3_im);
                out_B_re = $signed(m0_re) + $signed(m2_re);
                out_B_im = $signed(m0_im) + $signed(m2_im);
                out_C_re = $signed(m1_re) - $signed(m3_re);
                out_C_im = $signed(m1_im) - $signed(m3_im);
                out_D_re = $signed(m0_re) - $signed(m2_re);
                out_D_im = $signed(m0_im) - $signed(m2_im);
            end
            2'b10: begin
                out_A_re = $signed(m2_re) + $signed(m0_re);
                out_A_im = $signed(m2_im) + $signed(m0_im);
                out_B_re = $signed(m3_re) + $signed(m1_re);
                out_B_im = $signed(m3_im) + $signed(m1_im);
                out_C_re = $signed(m2_re) - $signed(m0_re);
                out_C_im = $signed(m2_im) - $signed(m0_im);
                out_D_re = $signed(m3_re) - $signed(m1_re);
                out_D_im = $signed(m3_im) - $signed(m1_im);
            end
            2'b11: begin
                out_A_re = $signed(m3_re) + $signed(m1_re);
                out_A_im = $signed(m3_im) + $signed(m1_im);
                out_B_re = $signed(m2_re) + $signed(m0_re);
                out_B_im = $signed(m2_im) + $signed(m0_im);
                out_C_re = $signed(m3_re) - $signed(m1_re);
                out_C_im = $signed(m3_im) - $signed(m1_im);
                out_D_re = $signed(m2_re) - $signed(m0_re);
                out_D_im = $signed(m2_im) - $signed(m0_im);
            end
        endcase
    end
endmodule