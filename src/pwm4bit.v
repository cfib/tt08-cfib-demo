module pwm4bit (input wire clock, input wire reset, input wire ena, input wire [3:0] sample, output reg pwm);

    reg [3:0] cntr;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pwm  <= 1'b0;
            cntr <= 4'b0;
        end else if (ena) begin
            cntr <= cntr + 4'b1;
            pwm  <= cntr < sample;
        end
    end
endmodule
