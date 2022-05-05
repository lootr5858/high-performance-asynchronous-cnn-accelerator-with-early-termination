`include "./definitions.v"

module buffer
#(
    parameter SIZE  = 8,
    parameter CYCLE = 8,
    parameter BITi  = 16,
    parameter BITo  = 128
 )
(
    input clock, reset,

    input  signed [BITi - 1 : 0] d,
    output signed [BITo - 1 : 0] q
);
    
    localparam BITc = $clog2(SIZE);
    localparam BITa = $clog2(CYCLE);

    reg signed [BITi - 1 : 0] mem [0 : SIZE - 1];
    reg        [BITc - 1 : 0] cnt;
    reg        [BITa - 1 : 0] cycle;

    integer ri, li;
    genvar i;

    generate

        for (i = 0; i < SIZE; i = i + 1) assign q [BITi * (i + 1) - 1 : BITi * i] = mem[i];
        
    endgenerate

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            cnt   <= {BITc{`OFF}};
            cycle <= {BITa{`OFF}};

            for (ri = 0; ri < SIZE; ri = ri + 1) mem [ri] <= {BITi{`OFF}};
            
        end

        else if (cycle == CYCLE) begin

            cycle <= {BITa{`OFF}};

            mem [cnt] <= d;

            if (cnt == SIZE) cnt <= {BITc{`OFF}};
            else             cnt <= cnt + 1;
            
        end

        else cycle <= cycle + 1;
        
    end
    
endmodule