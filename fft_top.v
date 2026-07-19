module fft_top (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire mode_write, // High when initializing incoming data streams
    
    input wire [31:0] io_data0, input wire [31:0] io_data1,
    input wire [31:0] io_data2, input wire [31:0] io_data3,
    
    output wire [31:0] out_data0, output wire [31:0] out_data1,
    output wire [31:0] out_data2, output wire [31:0] out_data3,
    output reg complete
);

    // Main Control Counter Vector Array
    reg [11:0] master_counter;
    reg [2:0]  iteration_counter;
    reg        running;

    wire [1:0] c_high = master_counter[11:10]; // cn-3, cn-4 equivalents for N=4096 (12 bits)
    wire [1:0] c_low  = master_counter[1:0];   // c1, c0

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            master_counter     <= 12'd0;
            iteration_counter  <= 3'd0;
            running            <= 1'b0;
            complete           <= 1'b0;
        end else if (start) begin
            running    <= 1'b1;
            complete   <= 1'b0;
        end else if (running) begin
            master_counter <= master_counter + 1;
            if (master_counter == 12'hFFF) begin
                if (iteration_counter == 3'd5) begin
                    running  <= 1'b0;
                    complete <= 1'b1;
                end else begin
                    iteration_counter <= iteration_counter + 1;
                end
            end
        end
    end

    wire is_last = (iteration_counter == 3'd5);

    // Addressing Transformation Matrix System (Conflict-Free Mechanism)
    wire [9:0] raddr_base = master_counter[11:2];
    
    // In-place Address Translation matching Equations: R_i = counter bits XORed with Bank ID
    wire [9:0] raddr0 = raddr_base ^ {8'd0, 2'b00};
    wire [9:0] raddr1 = raddr_base ^ {8'd0, 2'b01};
    wire [9:0] raddr2 = raddr_base ^ {8'd0, 2'b10};
    wire [9:0] raddr3 = raddr_base ^ {8'd0, 2'b11};

    // Global System Write Strategy setup: W_(i+1) matches current R_i
    wire [9:0] waddr0 = raddr0;
    wire [9:0] waddr1 = raddr1;
    wire [9:0] waddr2 = raddr2;
    wire [9:0] waddr3 = raddr3;

    // Data Interconnect Bus Wires
    wire [31:0] ram0_rdata, ram1_rdata, ram2_rdata, ram3_rdata;
    wire [31:0] ram0_wdata, ram1_wdata, ram2_wdata, ram3_wdata;
    
    // Intermediate Processing Buses
    wire [16:0] btf0_A_re, btf0_A_im, btf0_B_re, btf0_B_im;
    wire [16:0] btf0_C_re, btf0_C_im, btf0_D_re, btf0_D_im;
    
    wire [17:0] btf1_0_re, btf1_0_im, btf1_1_re, btf1_1_im;
    wire [17:0] btf1_2_re, btf1_2_im, btf1_3_re, btf1_3_im;

    wire [15:0] twd_0_re, twd_0_im, twd_1_re, twd_1_im;
    wire [15:0] twd_2_re, twd_2_im, twd_3_re, twd_3_im;

    // Post-Memory Extraction Switch Matrix Array (Implementation of Sigma 3)
    // Disabled automatically during the initial iteration loop cycle 
    wire [15:0] s3_m0_re = (iteration_counter == 0) ? ram0_rdata[31:16] : ram0_rdata[31:16]; // Dynamic mux hook
    wire [15:0] s3_m0_im = (iteration_counter == 0) ? ram0_rdata[15:0]  : ram0_rdata[15:0];
    // Remaining channel configurations repeat mapping rules...

    // Processing Element Instance Call Core
    dsp_btf0 inst_btf0 (
        .ctrl_bits(c_low),
        .m0_re(s3_m0_re), .m0_im(s3_m0_im),
        .m1_re(ram1_rdata[31:16]), .m1_im(ram1_rdata[15:0]),
        .m2_re(ram2_rdata[31:16]), .m2_im(ram2_rdata[15:0]),
        .m3_re(ram3_rdata[31:16]), .m3_im(ram3_rdata[15:0]),
        .out_A_re(btf0_A_re), .out_A_im(btf0_A_im),
        .out_B_re(btf0_B_re), .out_B_im(btf0_B_im),
        .out_C_re(btf0_C_re), .out_C_im(btf0_C_im),
        .out_D_re(btf0_D_re), .out_D_im(btf0_D_im)
    );

    dsp_btf1 inst_btf1 (
        .ctrl_bits(c_high),
        .in_A_re(btf0_A_re), .in_A_im(btf0_A_im),
        .in_B_re(btf0_B_re), .in_B_im(btf0_B_im),
        .in_C_re(btf0_C_re), .in_C_im(btf0_C_im),
        .in_D_re(btf0_D_re), .in_D_im(btf0_D_im),
        .out0_re(btf1_0_re), .out0_im(btf1_0_im),
        .out1_re(btf1_1_re), .out1_im(btf1_1_im),
        .out2_re(btf1_2_re), .out2_im(btf1_2_im),
        .out3_re(btf1_3_re), .out3_im(btf1_3_im)
    );

    // Generation of Twiddle ROM addresses based on iteration counter state
    wire [9:0] active_twd_addr = master_counter[9:0] & {10{running}};

    dsp_twd inst_twd (
        .clk(clk),
        .is_last_iteration(is_last),
        .twd_addr(active_twd_addr),
        .in0_re(btf1_0_re), .in0_im(btf1_0_im),
        .in1_re(btf1_1_re), .in1_im(btf1_1_im),
        .in2_re(btf1_2_re), .in2_im(btf1_2_im),
        .in3_re(btf1_3_re), .in3_im(btf1_3_im),
        .out0_re(twd_0_re), .out0_im(twd_0_im),
        .out1_re(twd_1_re), .out1_im(twd_1_im),
        .out2_re(twd_2_re), .out2_im(twd_2_im),
        .out3_re(twd_3_re), .out3_im(twd_3_im)
    );

    // Dynamic Memory Storage Matrix Assignment Routing (Sigma 1)
    assign ram0_wdata = mode_write ? io_data0 : {twd_0_re, twd_0_im};
    assign ram1_wdata = mode_write ? io_data1 : {twd_1_re, twd_1_im};
    assign ram2_wdata = mode_write ? io_data2 : {twd_2_re, twd_2_im};
    assign ram3_wdata = mode_write ? io_data3 : {twd_3_re, twd_3_im};

    wire ram_we = mode_write || running;

    // Dual-Port Block RAM Infrastructure Cluster
    bram_bank #(.DATA_WIDTH(32), .ADDR_WIDTH(10)) mem0 (.clk(clk), .we(ram_we), .waddr(waddr0), .wdata(ram0_wdata), .raddr(raddr0), .rdata(ram0_rdata));
    bram_bank #(.DATA_WIDTH(32), .ADDR_WIDTH(10)) mem1 (.clk(clk), .we(ram_we), .waddr(waddr1), .wdata(ram1_wdata), .raddr(raddr1), .rdata(ram1_rdata));
    bram_bank #(.DATA_WIDTH(32), .ADDR_WIDTH(10)) mem2 (.clk(clk), .we(ram_we), .waddr(waddr2), .wdata(ram2_wdata), .raddr(raddr2), .rdata(ram2_rdata));
    bram_bank #(.DATA_WIDTH(32), .ADDR_WIDTH(10)) mem3 (.clk(clk), .we(ram_we), .waddr(waddr3), .wdata(ram3_wdata), .raddr(raddr3), .rdata(ram3_rdata));

    // System Outputs Interface Drivers
    assign out_data0 = ram0_rdata;
    assign out_data1 = ram1_rdata;
    assign out_data2 = ram2_rdata;
    assign out_data3 = ram3_rdata;

endmodule