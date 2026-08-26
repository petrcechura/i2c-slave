module reg_bank (

    input  logic clk,
    input  logic arst, 

    input  logic[7:0] reg_select,
    input  logic[7:0] reg_val_in,
    output logic[7:0] reg_val_out,
    input  logic      reg_we
    );
    
    logic[7:0] regs_q[256];

    always_ff @(posedge clk or posedge arst) begin
        if (arst) begin
            for (int i = 0; i < 256; i++) begin
                regs_q[i] <= 8'h00;
            end
        end else begin
            if (reg_we) begin
                regs_q[reg_select] <= reg_val_in;
            end
        end
    end

    assign reg_val_out = regs_q[reg_select];

endmodule