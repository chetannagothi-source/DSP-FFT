`timescale 1ns / 1ps

module fft_top_tb;

    // Inputs to the Device Under Test (DUT)
    reg clk;
    reg rst_n;
    reg start;
    reg mode_write;
    reg [31:0] io_data0;
    reg [31:0] io_data1;
    reg [31:0] io_data2;
    reg [31:0] io_data3;

    // Outputs from the DUT
    wire [31:0] out_data0;
    wire [31:0] out_data1;
    wire [31:0] out_data2;
    wire [31:0] out_data3;
    wire complete;

    // Temporary variables for pure Verilog-2001 indexing
    reg [15:0] val0;
    reg [15:0] val1;
    reg [15:0] val2;
    reg [15:0] val3;

    // Instantiate the Top Module Design
    fft_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode_write(mode_write),
        .io_data0(io_data0),
        .io_data1(io_data1),
        .io_data2(io_data2),
        .io_data3(io_data3),
        .out_data0(out_data0),
        .out_data1(out_data1),
        .out_data2(out_data2),
        .out_data3(out_data3),
        .complete(complete)
    );

    // 200 MHz Clock Generator Logic System (5ns Period Cycle)
    always begin
        #2.5 clk = ~clk;
    end

    // Loop variables for initializing data
    integer i;

    initial begin
        // System Reset Initialization State
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        mode_write = 1'b0;
        io_data0 = 32'd0;
        io_data1 = 32'd0;
        io_data2 = 32'd0;
        io_data3 = 32'd0;

        // Apply Reset Pulse Sequence
        #20;
        rst_n = 1'b1;
        #10;

        // --- STAGE 1: LOAD MEMORIES WITH VERIFICATION DATA ---
        $display("[TB INFO] Starting Data Load Phase into Parallel Banks...");
        @(posedge clk);
        mode_write = 1'b1; // Capture data lanes control routing matrix

        // Write sample data sequentially into the 1024 unique addresses of the four BRAM banks
        for (i = 0; i < 1024; i = i + 1) begin
            // Perform additions out of line to comply with Verilog-2001 syntax limitations
            val0 = i;
            val1 = i + 1024;
            val2 = i + 2048;
            val3 = i + 3072;

            io_data0 = {val0, 16'h0000}; 
            io_data1 = {val1, 16'h0000};
            io_data2 = {val2, 16'h0000};
            io_data3 = {val3, 16'h0000};
            @(posedge clk);
        end

        // Close input write matrix interface configuration
        mode_write = 1'b0;
        io_data0 = 32'd0;
        io_data1 = 32'd0;
        io_data2 = 32'd0;
        io_data3 = 32'd0;
        #20;

        // --- STAGE 2: TRIGGER CORE COMPUTATION LOOP ---
        $display("[TB INFO] Launching Radix-4 Processing Core Execution...");
        @(posedge clk);
        start = 1'b1; // Fire computation pipeline flag
        @(posedge clk);
        start = 1'b0;

        // --- STAGE 3: WAIT FOR COMPLETION FLAG ---
        fork
            begin
                // Timeout Watchdog safety boundary handler
                #200000; // 200 microseconds limit safety pad
                $display("[TB ERROR] Simulation Timeout reached before processing loop could finish.");
                $finish;
            end
            begin
                // Synchronous wait block monitoring for computation conclusion
                @(posedge complete);
                $display("[TB SUCCESS] FFT computation loop cycle completed safely.");
                
                // Allow pipeline structural delays to push final values cleanly through outputs
                #50;
                
                // Print a brief snapshot preview sample of the resulting output register data lines
                $display("[DATA LOG] Out0: Real=0x%h Imag=0x%h", out_data0[31:16], out_data0[15:0]);
                $display("[DATA LOG] Out1: Real=0x%h Imag=0x%h", out_data1[31:16], out_data1[15:0]);
                $display("[DATA LOG] Out2: Real=0x%h Imag=0x%h", out_data2[31:16], out_data2[15:0]);
                $display("[DATA LOG] Out3: Real=0x%h Imag=0x%h", out_data3[31:16], out_data3[15:0]);
                
                $finish;
            end
        join
    end

endmodule