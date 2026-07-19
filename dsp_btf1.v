module dsp_btf1 (
    input wire [1:0] ctrl_bits, // cn-3, cn-4
    // Inputs from BTF0 layer
    input wire [16:0] in_A_re, input wire [16:0] in_A_im,
    input wire [16:0] in_B_re, input wire [16:0] in_B_im,
    input wire [16:0] in_C_re, input wire [16:0] in_C_im,
    input wire [16:0] in_D_re, input wire [16:0] in_D_im,
    // Output complex channels
    output reg [17:0] out0_re, output reg [17:0] out0_im,
    output reg [17:0] out1_re, output reg [17:0] out1_im,
    output reg [17:0] out2_re, output reg [17:0] out2_im,
    output reg [17:0] out3_re, output reg [17:0] out3_im
);

    // Dynamic arithmetic selection matching Table II 
    // J factors logic (Multiplication by j translates to: Real_out = -Imag_in, Imag_out = Real_in)
    always @(*) begin
        case (ctrl_bits)
            2'b00: begin
                out0_re = $signed(in_A_re) + $signed(in_B_re);
                out0_im = $signed(in_A_im) + $signed(in_B_im);
                out1_re = $signed(in_A_re) - $signed(in_B_re);
                out1_im = $signed(in_A_im) - $signed(in_B_im);
                out2_re = $signed(in_C_re) - $signed(in_D_im);
                out2_im = $signed(in_C_im) + $signed(in_D_re);
                out3_re = $signed(in_C_re) + $signed(in_D_im);
                out3_im = $signed(in_C_im) - $signed(in_D_re);
            end
            2'b01: begin
                out0_re = $signed(in_A_re) - $signed(in_B_re);
                out0_im = $signed(in_A_im) - $signed(in_B_im);
                out1_re = $signed(in_A_re) + $signed(in_B_re);
                out1_im = $signed(in_A_im) + $signed(in_B_im);
                out2_re = $signed(in_C_re) + $signed(in_D_im);
                out2_im = $signed(in_C_im) - $signed(in_D_re);
                out3_re = $signed(in_C_re) - $signed(in_D_im);
                out3_im = $signed(in_C_im) + $signed(in_D_re);
            end
            2'b10: begin
                out0_re = $signed(in_C_re) - $signed(in_D_im);
                out0_im = $signed(in_C_im) + $signed(in_D_re);
                out1_re = $signed(in_C_re) + $signed(in_D_im);
                out1_im = $signed(in_C_im) - $signed(in_D_re);
                out2_re = $signed(in_A_re) + $signed(in_B_re);
                out2_im = $signed(in_A_im) + $signed(in_B_im);
                out3_re = $signed(in_A_re) - $signed(in_B_re);
                out3_im = $signed(in_A_im) - $signed(in_B_im);
            end
            2'b11: begin
                out0_re = $signed(in_C_re) + $signed(in_D_im);
                out0_im = $signed(in_C_im) - $signed(in_D_re);
                out1_re = $signed(in_C_re) - $signed(in_D_im);
                out1_im = $signed(in_C_im) + $signed(in_D_re);
                out2_re = $signed(in_A_re) - $signed(in_B_re);
                out2_im = $signed(in_A_im) - $signed(in_B_im);
                out3_re = $signed(in_A_re) + $signed(in_B_re);
                out3_im = $signed(in_A_im) + $signed(in_B_im);
            end
        endcase
    end
endmodule