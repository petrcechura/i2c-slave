
/** Generic 7bit register-bank based I2C module. 
  * 
  * Module handles low-level I2C communication and exposes its registers 
  * outside so other modules wrapping up this one can use the registers
  * to transfer data over the bus.
  * */
module i2c_slave(
    input logic clk,
    input logic arst,

    i2c_slave_if i2c_slave_ifc,

    input logic[6:0] slave_addr,

    /** Exposed `reg select` register value */ 
    output logic[7:0] reg_select,
    /** Input register value, shall depend on `reg_select` value from wrapper using this module.
      *
      * This value is eventually transmited over the bus when master requests a read.
      */
    input  logic[7:0] reg_val_in,
    /** Exposed register value, valid only when `reg_val_valid` is high.
      *
      * Contains a value received over the bus via write command.
      */
    output logic[7:0] reg_val_out,
    /** Is 1'b1 when `reg_val_out` is of valid value */
    output logic      reg_val_valid
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
    
    logic[7:0] reg_sel_d, reg_sel_q;
    logic[7:0] reg_val_d, reg_val_q;
    logic      reg_val_valid_d, reg_val_valid_q;


    always_ff @(posedge clk or posedge arst) begin
        if (arst) begin
            state_i2c_q <= ADDR;
            reg_sel_q <= '0;
            reg_val_q <= '0;
            reg_val_valid_q <= 1'b0;
        end else begin
            state_i2c_q <= state_i2c_d;
            reg_sel_q <= reg_sel_d;
            reg_val_q <= reg_val_d;
            reg_val_valid_q <= reg_val_valid_d;
        end
    end

    always_comb begin
        state_i2c_d = state_i2c_q;
        i2c_sc_ack_in = 1'b1;
        reg_sel_d = reg_sel_q;
        reg_val_d = reg_val_q;
        reg_val_valid_d = reg_val_valid_q;
        i2c_sc_tx_enable = 1'b0;
        
        case (state_i2c_q)
            ADDR: begin
                if (i2c_sc_rx_done && i2c_sc_data_out[7:1] == slave_addr) begin
                    if (i2c_sc_data_out[0] == 1'b1) begin
                        state_i2c_d = REG_WR_SEL;
                    end else begin
                        state_i2c_d = REG_RD_SEL;
                    end
                end
            end

            REG_WR_SEL: begin
                i2c_sc_ack_in = 1'b0;
                reg_val_valid_d = 1'b0;

                if (i2c_sc_rx_done) begin
                    reg_sel_d = i2c_sc_data_out;
                    state_i2c_d = REG_WR_VAL;
                end
            end

            REG_WR_VAL: begin
                i2c_sc_ack_in = 1'b0;
                
                if (i2c_sc_rx_done) begin
                    reg_val_d = i2c_sc_data_out;
                    reg_val_valid_d = 1'b1;
                end

                if (!i2c_sc_core_processing) begin
                    state_i2c_d = ADDR;
                end
            end

            REG_RD_SEL: begin
                i2c_sc_ack_in = 1'b0;
                reg_val_valid_d = 1'b0;

                if (i2c_sc_rx_done) begin
                    reg_sel_d = i2c_sc_data_out;                    
                    state_i2c_d = REG_RD_VAL;
                end
            end

            REG_RD_VAL: begin
                i2c_sc_ack_in = 1'b0;
                i2c_sc_tx_enable = 1'b1;
                reg_val_valid_d = 1'b0;

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
        .sda(i2c_slave_ifc.sda),
        .scl(i2c_slave_ifc.scl),
`else        
        .sda_i(i2c_slave_ifc.sda_i),
        .sda_o(i2c_slave_ifc.sda_o),
        .sda_t(i2c_slave_ifc.sda_t),
        .scl_i(i2c_slave_ifc.scl_i),
        .scl_o(i2c_slave_ifc.scl_o),
        .scl_t(i2c_slave_ifc.scl_t),
`endif

        .tx_enable(i2c_sc_tx_enable),
        .rx_done(i2c_sc_rx_done),
        .tx_done(i2c_sc_tx_done),
        .core_processing(i2c_sc_core_processing),
        .ack_in(i2c_sc_ack_in),
        .ack_out(i2c_sc_ack_out),
        .data_in(reg_val_in),
        .data_out(i2c_sc_data_out)
    );

    assign reg_select = reg_sel_q;
    assign reg_val_out = reg_val_q;
    assign reg_val_valid = reg_val_valid_q;

endmodule