`include "./definitions.v"

module handshake1
#(
    parameter BIT0 = 8
)
(
    input reset,

    input [BIT0 - 1 : 0] dt_0,df_0,

    output ack_prev,
    input  ack_nxt
);

    wire verify, fire;
    reg  busy;

    assign verify = (dt_0 ^ df_0 == {BIT0{`ON}})  ? `ON  :
                    (dt_0 ^ df_0 == {BIT0{`OFF}}) ? `OFF : verify;

    assign fire = (verify ^ busy) & ~ack_nxt;

    assign ack_prev = busy;

    always @(posedge fire or posedge reset) begin

        if (reset) busy <= `OFF;

        else busy <= ~busy;
        
    end
    
endmodule