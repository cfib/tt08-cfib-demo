module sndgen #(parameter SAMPLE_RATE=16384) (input wire clock, input wire sample_ena, input wire reset, output wire [3:0] sample,
                                             output wire [3:0] s1_o, output wire [3:0] s2_o, output wire [3:0] s3_o, output wire [3:0] s4_o);

    reg [5:0] sample_int;
    
    localparam TIMESLOT  = SAMPLE_RATE/8;
    localparam BARSLOT   = 16;
    localparam LFSRTIME  = SAMPLE_RATE-128;
    
    reg [$clog2(SAMPLE_RATE)-1:0]      phacc1;
    reg [$clog2(SAMPLE_RATE)-1:0]      phacc2;
    reg [$clog2(SAMPLE_RATE)-1:0]      phacc3;
    reg [$clog2(SAMPLE_RATE)-1:0]      phacc4;
    reg [$clog2(TIMESLOT)+$clog2(BARSLOT)-1:0] slot_counter;
    reg [3:0]                          mask_1;
    reg                                mask_2;
    
    reg [3:0]                          s1;
    reg                                s2;
    reg                                s3;
    reg                                s4;
    
    reg [3:0]                          c1;
    reg [3:0]                          c2;
    reg [3:0]                          c3;
    reg [3:0]                          c4;
    
    reg [15:0] lfsr;
   
   
    localparam D=1;
    localparam DIS=2;
    localparam E=3;
    localparam F=4;
    localparam FIS=5;
    localparam G=6;
    localparam GIS=7;
    localparam A=8;
    localparam AIS=9;
    localparam H=10;
    localparam C=11;
    
    assign sample = sample_int[5:2];
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            lfsr <= 16'hdead;
        end else begin
            lfsr <= lfsr[15] ? {lfsr[14:0],1'b1} ^ 16'h0805 : {lfsr[14:0],1'b0};
        end
    end
        
    reg [$clog2(SAMPLE_RATE)-1:0] rom_out;
    reg [3:0]                     rom_addr;
        
    always @(*) begin
        case (rom_addr)
            D   : rom_out = 277;
            //DIS : rom_out = 294;
            E   : rom_out = 311;
            F   : rom_out = 330;
            FIS : rom_out = 369;
            G   : rom_out = 392;
            GIS : rom_out = 415;
            //A   : rom_out = 440;
            AIS : rom_out = 466;
            //H   : rom_out = 494;
            C   : rom_out = 261;
            default: rom_out = 0;
        endcase
    end
    
    wire [$clog2(SAMPLE_RATE)-1:0] sample_rom_out = SAMPLE_RATE-rom_out;
    
    reg [3:0]  sample_ena_delay;
    reg [$clog2(SAMPLE_RATE)-1:0] p_c2;
    reg [$clog2(SAMPLE_RATE)-1:0] p_c3;
    reg [$clog2(SAMPLE_RATE)-1:0] p_c4;

    always @(posedge clock or posedge reset)
        if (reset) begin
            sample_ena_delay = 4'b0;
            p_c2 <= 0;
            p_c3 <= 0;
            p_c4 <= 0;
            rom_addr <= 0;
        end else begin
            sample_ena_delay = {sample_ena_delay[2:0],sample_ena};
            if (sample_ena_delay[0]) begin
                rom_addr <= c2;
            end
            if (sample_ena_delay[1]) begin
                p_c2 <= sample_rom_out;
                rom_addr <= c3;
            end
            if (sample_ena_delay[2]) begin
                p_c3 <= sample_rom_out;
                rom_addr <= c4;
            end
            if (sample_ena_delay[3]) begin
                p_c4 <= sample_rom_out;
            end
        end
        
    wire [$clog2(BARSLOT)-1:0] bar_counter = slot_counter[$clog2(TIMESLOT)+:$clog2(BARSLOT)];
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            slot_counter   <= 0;
            c1             <= 2;
            c2             <= 3;
            c3             <= 4;
            c4             <= 5;
            mask_1         <= 4'hf;
            mask_2         <= 1'b1;
            phacc1         <= 0;
            phacc2         <= 0;
            phacc3         <= 0;
            phacc4         <= 0;
        end else if (sample_ena) begin
            slot_counter <= slot_counter + 1;
            
            /* generate masks at start of new bar */
            if (& slot_counter) begin
                mask_1 <=   lfsr[5+:4];
                mask_2 <= | lfsr[7+:4];
            end
            
            if (& slot_counter[$clog2(TIMESLOT)-1:0]) begin
                
                /* generate perc note */
                case (bar_counter[2:0])
                    0 : c1 <= 2'd2;
                    1 : c1 <= 2'd0;
                    2 : c1 <= 2'd1;
                    3 : c1 <= 2'd0;
                    4 : c1 <= 2'd2;
                    5 : c1 <= 2'd1;
                    6 : c1 <= 2'd1;
                    7 : c1 <= 2'd0;
                endcase
                
                /* generate bass note */
                if (bar_counter[1:0] == 2'b11) begin
                    case (bar_counter[3:2])
                        2'b00 : c2 <= D;
                        2'b01 : c2 <= E;
                        2'b10 : c2 <= G;
                        2'b11 : c2 <= F;
                    endcase
                end
                
                /* generate melody note */
                case ({lfsr[13],lfsr[8],lfsr[3]})
                    3'b100  : begin c3 <= D;   c4 <= FIS;   end
                    3'b101  : begin c3 <= E;   c4 <= GIS;   end
                    3'b110  : begin c3 <= FIS; c4 <= AIS;   end
                    3'b111  : begin c3 <= GIS; c4 <= C;     end
                    default : begin c3 <= 0;   c4 <= 0;     end
                endcase
            end
            
            /* generate tones */
            phacc1 <= (phacc1 + LFSRTIME);
            if (&slot_counter[1:0]) begin
                phacc2 <= (phacc2 + p_c2);
            end
            phacc3 <= (phacc3 + p_c3);
            phacc4 <= (phacc4 + p_c4);
        end
    end
        
    always @(*) begin
        /* generate samples */
        if ((slot_counter[$clog2(TIMESLOT)-1:0] > (TIMESLOT*3)/4) || ({mask_1[0],mask_2} == 2'b0) || (~phacc1[$clog2(SAMPLE_RATE)-1]) || (c1 == 0)) begin
            s1 = 4'b0;
        end else begin
            s1 = (c1 == 2'b1) ? {1'b0,lfsr[8+:3]} : lfsr[8+:4];
        end
        
        s2     = phacc2[$clog2(SAMPLE_RATE)-1] && mask_1[1];
        s3     = phacc3[$clog2(SAMPLE_RATE)-1] && mask_1[2];
        s4     = phacc4[$clog2(SAMPLE_RATE)-1] && mask_1[3];
    
        /* mix samples */
        sample_int = s1 + {4{s2}} + {4{s3}} + {4{s4}};
    end
        
    assign {s1_o, s2_o, s3_o, s4_o} = {s1, {4{s2}}, {4{s3}}, {4{s4}}};

endmodule
