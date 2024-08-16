module vga(input wire clock,   input wire reset,  input wire ena, 
           input wire [5:0] dat,
           input wire [3:0] s1, input wire[3:0] s2, input wire [3:0] s3, input wire [3:0] s4,
           output reg hsync,   output reg vsync, 
           output wire hline,
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
    
    localparam HVIS=10'd640;
    localparam VVIS=10'd480;
    localparam HFP=10'd16;
    localparam HSYNC=10'd96;
    localparam VFP=10'd10;
    localparam VSYNC=10'd2;
    
    localparam SPACE=10'd26;
    localparam CHANNEL=10'd128;
    
    reg  [3:0] sx1, sr1;
    reg  sx2, sx3, sx4, sr2, sr3, sr4;
    reg  [7:0] x1;
    wire [5:0] bg = {x[1+:6] ^ y [1+:6]} & 6'b011000;
    wire [5:0] nbg = 6'h3f;
    reg  [3:0] xmin;
    reg  [3:0] xmax;
    
    localparam START1 = 320-128;  //SPACE;
    localparam END1   = 320+128; //START1+CHANNEL;
    //localparam START2 = 160+320-64;  //SPACE;
    //localparam END2   = 160+320+64; //START1+CHANNEL;

    assign hline = (x == HVIS & y[0]) & ena;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            x1    <= 8'b0;
            sr1   <= 4'b0;
            sr2   <= 1'b0;
            sr3   <= 1'b0;
            sr4   <= 1'b0;
            sx1   <= 4'b0;
            sx2   <= 1'b0;
            sx3   <= 1'b0;
            sx4   <= 1'b0;
            xmin  <= 4'b0;
            xmax  <= 4'b0;
        end else if (ena) begin

            if (hline) begin
                {sr1, sx1} <= {sx1, s1};
            /*
                {sr2, sx2} <= {sx2, s2[3]};
                {sr3, sx3} <= {sx3, s3[3]};
                {sr4, sx4} <= {sx4, s4[3]};
            */
            end

            if (x < START1) begin
                x1           <= 8'b0;
                {xmin, xmax} <= (sx1 < sr1) ? {sx1, sr1} : {sr1, sx1};
            /*
            end else if (x >= END1 && x < START2) begin
                x1           <= 7'b0;
                {xmin, xmax} <= (sr2) ? {{4{sx2}}, {4{sr2}}} : {{4{sr2}}, {4{sx2}}};
            end else if (x >= END1 && x < START2) begin
                x1           <= 7'b0;
                {xmin, xmax} <= (sr3) ? {{4{sx3}}, {4{sr3}}} : {{4{sr3}}, {4{sx3}}};
            end else if (x >= END3 && x < START4) begin
                x1           <= 7'b0;
                {xmin, xmax} <= (sr4) ? {{4{sx4}}, {4{sr4}}} : {{4{sr4}}, {4{sx4}}};
            */
            end else begin
                x1           <= x1 + 1'b1;
            end
                
        end
    end
    
    always @(*) begin
        hsync = !(x > HVIS+HFP && x < HVIS+HFP+HSYNC);
        vsync = !(y > VVIS+VFP && y < VVIS+VFP+VSYNC);
        {r, g, b} = 6'b0;
        if ((x >= START1   && x < END1)) begin
            {r, g, b} = (x1[7:4] >= xmin  && x1 <= {xmax,4'b0011}) ? nbg : bg;
        end else if (x < HVIS && y < VVIS) begin
            {r, g, b} = bg;
        end
    end


endmodule
