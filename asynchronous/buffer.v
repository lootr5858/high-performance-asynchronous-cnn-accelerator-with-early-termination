`include "./definitions.v"
`include "./handshake1.v"

module buffer
#(
    parameter SIZE  = 8,
    parameter BITi  = 16,
    parameter BITo  = 128
 )
(
    input reset,

    input  signed [BITi - 1 : 0] dt, df,
    output signed [BITo - 1 : 0] qt, qf
);
    
    localparam BITc = $clog2(SIZE);

    reg signed [BITi - 1 : 0] mem_t [0 : SIZE - 1],
                              mem_f [0 : SIZE - 1];
    reg        [BITc - 1 : 0] cnt;

    integer ri, li;
    genvar i;

    generate

        for (i = 0; i < SIZE; i = i + 1) begin
            
            assign qt [BITi * (i + 1) - 1 : BITi * i] = mem_t[i];
            assign qf [BITi * (i + 1) - 1 : BITi * i] = mem_f[i];

        end
        
    endgenerate

    handshake1 #(.BIT0 (BITi)) handshake_mem
    (
        .reset (reset),

        .ack_prev (ack_prev),
        .ack_nxt  (ack_nxt),

        .dt_0 (dt),
        .df_0 (df)
    );

    always @(posedge ack_prev or posedge (reset | ack_nxt)) begin

        if (reset | ack_nxt) begin

            for (ri = 0; ri < SIZE; ri = ri + 1) mem_t [ri] <= {BITi{`OFF}};
            
        end

        else begin
            
            mem_t [cnt] <= dt;
            mem_f [cnt] <= df;

        end
        
    end

    always @(posedge ack_prev or posedge reset) begin

        if (reset) cnt <= {BITc{`OFF}};

        else if (cnt == SIZE - 1) cnt <= {BITc{`OFF}};

        else cnt <= cnt + 1;
        
    end
    
endmodule