module bram_bank #(
    parameter DATA_WIDTH = 32, // 16-bit Real + 16-bit Imag
    parameter ADDR_WIDTH = 10  // 1024 words per bank for N=4096
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] waddr,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we) begin
            ram[waddr] <= wdata;
        end
        rdata <= ram[raddr];
    end

endmodule