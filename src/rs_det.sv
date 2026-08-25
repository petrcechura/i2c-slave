module rs_det #(
    parameter int FF_COUNT = 2,
    parameter bit EDGE_DETECT = 1
)(
    input  logic clk,
    input  logic sig_in,
    output logic sig_out,
    output logic rise_edge,
    output logic fall_edge
);

    logic [FF_COUNT-1:0] ff_q;

    always_ff @(posedge clk) begin
        ff_q[0] <= sig_in;

        for (int i = 1; i < FF_COUNT; i++)
            ff_q[i] <= ff_q[i-1];
    end

    assign sig_out = ff_q[FF_COUNT-2];

    if (EDGE_DETECT) begin : g_edge
        assign fall_edge = ff_q[FF_COUNT-1] & ~ff_q[FF_COUNT-2];
        assign rise_edge = ~ff_q[FF_COUNT-1] & ff_q[FF_COUNT-2];
    end
    else begin : g_no_edge
        assign rise_edge = 1'b0;
        assign fall_edge = 1'b0;
    end

endmodule
