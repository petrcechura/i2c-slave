

module i2c_slave#(
    parameter int REG_COUNT = 1,
    parameter bit[6:0] SLAVE_ADDR
) (
    input logic clk,
    input logic arst,

`ifndef USING_VERILATOR
    inout wire sda,
    inout wire scl,
`else
    input  wire sda_i,
    output wire sda_o,
    output wire sda_t,
    input  wire scl_i,
    output wire scl_o,
    output wire scl_t,
`endif

    output logic[7:0] regs[REG_COUNT] 
);

    typedef enum logic[2:0] {  
        ADDR,           // 000
        REG_WR_SEL,     // 001
        REG_WR_VAL,     // 010
        REG_RD_SEL,     // 011
        REG_RD_VAL      // 100
    } state_i2c_t;

    state_i2c_t state_i2c_d, state_i2c_q;

    logic      i2c_sc_tx_enable;
    logic      i2c_sc_rx_done;
    logic      i2c_sc_tx_done;
    logic      i2c_sc_core_processing;
    logic      i2c_sc_ack_in;
    logic      i2c_sc_ack_out;
    logic[7:0] i2c_sc_data_in;
    logic[7:0] i2c_sc_data_out;

    // ==============================
    // ==== I2C slave registers =====
    // ==============================
    // guard against negative bounds
    localparam int SEL_WIDTH = (REG_COUNT > 1) ? $clog2(REG_COUNT) : 1;
    
    logic[7:0] regs_d[REG_COUNT];
    logic[7:0] regs_q[REG_COUNT];
    logic[SEL_WIDTH-1:0] reg_sel_d, reg_sel_q;


    always_ff @(posedge clk or posedge arst) begin
        if (arst) begin
            state_i2c_q <= ADDR;
            regs_q <= '{default: 8'b0};
            reg_sel_q <= '0;
        end else begin
            state_i2c_q <= state_i2c_d;
            regs_q <= regs_d;
            reg_sel_q <= reg_sel_d;
        end
    end

    always_comb begin
        state_i2c_d = state_i2c_q;
        i2c_sc_ack_in = 1'b1;
        regs_d = regs_q;
        reg_sel_d = reg_sel_q;
        i2c_sc_tx_enable = 1'b0;
        
        case (state_i2c_q)
            ADDR: begin
                if (i2c_sc_rx_done && i2c_sc_data_out[7:1] == SLAVE_ADDR) begin
                    if (i2c_sc_data_out[0] == 1'b1) begin
                        state_i2c_d = REG_WR_SEL;
                    end else begin
                        state_i2c_d = REG_RD_SEL;
                    end
                end
            end

            REG_WR_SEL: begin
                i2c_sc_ack_in = 1'b0;

                if (i2c_sc_rx_done) begin
                    reg_sel_d = i2c_sc_data_out[SEL_WIDTH-1:0];
                    state_i2c_d = REG_WR_VAL;
                end
            end

            REG_WR_VAL: begin
                i2c_sc_ack_in = 1'b0;
                
                if (i2c_sc_rx_done) begin
                    regs_d[reg_sel_q] = i2c_sc_data_out;
                end

                if (!i2c_sc_core_processing) begin
                    state_i2c_d = ADDR;
                end
            end

            REG_RD_SEL: begin
                i2c_sc_ack_in = 1'b0;

                if (i2c_sc_rx_done) begin
                    reg_sel_d = i2c_sc_data_out[SEL_WIDTH-1:0];                    
                    state_i2c_d = REG_RD_VAL;
                end
            end

            REG_RD_VAL: begin
                i2c_sc_ack_in = 1'b0;
                i2c_sc_tx_enable = 1'b1;

                if (!i2c_sc_core_processing) begin
                    state_i2c_d = ADDR;
                end
            end
        endcase
    end

    i2c_slave_core i2c_slave_core_i(
        .clk(clk),
        .arst(arst),
`ifndef USING_VERILATOR
        .sda(sda),
        .scl(scl),
`else        
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
`endif

        .tx_enable(i2c_sc_tx_enable),
        .rx_done(i2c_sc_rx_done),
        .tx_done(i2c_sc_tx_done),
        .core_processing(i2c_sc_core_processing),
        .ack_in(i2c_sc_ack_in),
        .ack_out(i2c_sc_ack_out),
        .data_in(i2c_sc_data_in),
        .data_out(i2c_sc_data_out)
    );


    assign regs = regs_q;
    assign i2c_sc_data_in = regs[reg_sel_q];

endmodule