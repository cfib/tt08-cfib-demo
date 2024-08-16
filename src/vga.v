module vga(input wire clock,   input wire reset,  input wire ena, 
           input wire [5:0] dat,
           input wire [3:0] s1, input wire[3:0] s2, input wire [3:0] s3, input wire [3:0] s4,
           output reg hsync,   output reg vsync, 
           output reg [1:0] r, output reg [1:0] g, output reg [1:0] b);
           

    reg [9:0] x;
    reg [9:0] y;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            x <= 10'b0;
            y <= 10'b0;
        end else if (ena) begin
            x <= x + 10'b1;
            if (x == 10'd799) begin
                x <= 10'b0;
                y <= y + 10'b1;
                if (y == 10'd524) begin
                    y <= 10'b0;
                end
            end
        end
    end 
    
    localparam HVIS=640;
    localparam VVIS=480;
    localparam HFP=16;
    localparam HSYNC=96;
    localparam VFP=10;
    localparam VSYNC=2;
    
    localparam SPACE=25;
    localparam CHANNEL=128;
    
    reg  [3:0] sx1, sx2, sx3, sx4;
    reg  [3:0] sr1, sr2, sr3, sr4;
    reg  [6:0] x1;
    wire [5:0] bg = {x[1+:6] ^ y [1+:6]} & 6'b011000;
    wire [5:0] nbg = 6'h3f;
    reg  [3:0] xmin;
    reg  [3:0] xmax;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
            r     <= 2'b0;
            g     <= 2'b0;
            b     <= 2'b0;
            x1    <= 7'b0;
            sr1   <= 4'b0;
            sr2   <= 4'b0;
            sr3   <= 4'b0;
            sr4   <= 4'b0;
            sx1   <= 4'b0;
            sx2   <= 4'b0;
            sx3   <= 4'b0;
            sx4   <= 4'b0;
        end else if (ena) begin
            hsync <= !(x > HVIS+HFP && x < HVIS+HFP+HSYNC);
            vsync <= !(y > VVIS+VFP && y < VVIS+VFP+VSYNC);
            if (x == HVIS && y[0]) begin
                {sr1, sx1} <= {sx1, s1};
                {sr2, sx2} <= {sx2, s2};
                {sr3, sx3} <= {sx3, s3};
                {sr4, sx4} <= {sx4, s4};
            end
            if (x < HVIS && y < VVIS) begin
                x1 <= x1 + 1'b1;
                if          (x < SPACE) begin
                    x1        <= 7'b0;
                    xmin      <= (sx1 < sr1) ? sx1  : sr1;
                    xmax      <= (sx1 > sr1) ? sx1  : sr1;
                    
                    {r, g, b} <= bg;
                end else if (x >= SPACE && x < SPACE+CHANNEL) begin
                    {r, g, b} <= (x1 > {xmin,3'b0}  && x1 <= {xmax,3'b11}) ? nbg : bg;
                end else if (x < 2*SPACE+CHANNEL) begin
                    x1        <= 7'b0;
                    xmin      <= (sx2 < sr2) ? sx2  : sr2;
                    xmax      <= (sx2 > sr2) ? sx2  : sr2;
                    
                    {r, g, b} <= bg;
                end else if (x >= 2*SPACE+CHANNEL   && x < 2*SPACE+2*CHANNEL) begin
                    {r, g, b} <= (x1 > {xmin,3'b0}  && x1 <= {xmax,3'b11}) ? nbg : bg;
                end else if (x < 3*SPACE+2*CHANNEL) begin
                    x1        <= 7'b0;
                    xmin      <= (sx3 < sr3) ? sx3  : sr3;
                    xmax      <= (sx3 > sr3) ? sx3  : sr3;
                    
                    {r, g, b} <= bg;
                end else if (x >= 3*SPACE+2*CHANNEL && x < 3*SPACE+3*CHANNEL) begin
                    {r, g, b} <= (x1 > {xmin,3'b0}  && x1 <= {xmax,3'b11}) ? nbg : bg;
                end else if (x < 4*SPACE+3*CHANNEL) begin
                    x1        <= 7'b0;
                    xmin      <= (sx4 < sr4) ? sx4  : sr4;
                    xmax      <= (sx4 > sr4) ? sx4  : sr4;
                    
                    {r, g, b} <= bg;
                end else if (x >= 4*SPACE+3*CHANNEL && x < 4*SPACE+4*CHANNEL) begin
                    {r, g, b} <= (x1 > {xmin,3'b0}  && x1 <= {xmax,3'b11}) ? nbg : bg;
                end else begin
                    {r, g, b} <= bg;
                    x1        <= 7'b0;
                end
            end else begin
                {r, g, b} <= 6'b0;
            end
        end
    end


endmodule
