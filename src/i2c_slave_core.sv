

// NOTE: Since Verilator does not support 4-state resolution
// for logic type, I2C interface tri-state buffers cannot
// be inside core itself and need to be "simulated" elsewhere,
// hence using tri-state signals instead
`define USING_VERILATOR


module i2c_slave_core
(
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

    /** When high during ACK/NACK process, subsequent transmittion is core sending
     *  contents from `data_in` vector. TX is immediately aborted when this signal
     *  goes low during the transmit. */
    input  logic tx_enable,
    /** 1-cycle long pulse signaling byte being succesfully read. */
    output logic rx_done,
    /** 1-cycle long pulse signaling byte being succesfully written. */
    output logic tx_done,
    /** When high, core is anywhere but in IDLE state. */
    output logic core_processing,
    /** ACK/NACK value from core to bus. Must be stable during entire ACK state. */
    input  logic ack_in,
    /** ACK/NACK value from bus to core. Stable during ACK state. */
    output logic ack_out,
    /** Data to be sent after TX is requested via `tx_enable`. */
    input  logic[7:0] data_in,
    /** Data read from the bus (RX). Valid when `rx_done` is high. */
    output logic[7:0] data_out
);

    typedef enum logic[2:0] {
        IDLE,       // 000
        DATA_RX,    // 001
        DATA_TX,    // 010
        ACK_TX,     // 011
        ACK_RX      // 100
    } state_t;

    logic[7:0] data_reg_d, data_reg_q;
    logic ack_out_d, ack_out_q;

    // Tri-state logic for I2C interface
    // -----------------------------------

`ifndef USING_VERILATOR
    logic sda_o, sda_i, sda_t;
    logic scl_o, scl_i, scl_t;
    
    assign sda = (sda_t) ? sda_o : 1'bZ;
    assign sda_i = sda;
    assign scl = (scl_t) ? scl_o : 1'bZ;
    assign scl_i = scl;
`endif

    // Metastability removal
    // ---------------------

    logic sda_latched;
    logic scl_latched;
    logic sda_rise;
    logic sda_fall;
    logic scl_rise;
    logic scl_fall;

    rs_det rs_sda_i(
        .clk(clk),
        .sig_in(sda_i),
        .sig_out(sda_latched),
        .rise_edge(sda_rise),
        .fall_edge(sda_fall)
    );

    rs_det rs_scl_i(
        .clk(clk),
        .sig_in(scl_i),
        .sig_out(scl_latched),
        .rise_edge(scl_rise),
        .fall_edge(scl_fall)
    );

    // 4bit counter
    // ------------
    logic[3:0] cntr_4b_q;
    logic cntr_4b_en;
    logic cntr_4b_incr;
    always_ff @(posedge clk or posedge arst) begin
        if (arst) begin
            cntr_4b_q <= '0;
        end
        else if (cntr_4b_en) begin
            if (cntr_4b_incr) begin
                cntr_4b_q <= cntr_4b_q + 1;
            end
            else begin
                cntr_4b_q <= cntr_4b_q;
            end
        end
        else begin
            cntr_4b_q <= '0;
        end
    end

    // Finite state machine
    // --------------------
    state_t state_d, state_q;

    always_ff @(posedge clk or posedge arst) begin
        if (arst) begin
            state_q <= IDLE;
            data_reg_q <= '0;
            ack_out_q <= 1'b0;
        end
        else begin
            state_q <= state_d;
            data_reg_q <= data_reg_d;
            ack_out_q <= ack_out_d;
        end
    end

    always_comb begin
        state_d = state_q;
        data_reg_d = data_reg_q;
        ack_out_d = ack_out_q;
        cntr_4b_en = 1'b0;
        cntr_4b_incr = 1'b0;
        scl_o = 1'b0;
        scl_t = 1'b0;
        sda_o = 1'b0;
        sda_t = 1'b0;
        rx_done = 1'b0;
        tx_done = 1'b0;
        ack_out = 1'b1;

        case (state_q)
            IDLE: begin
                // startbit condition
                if (sda_fall && scl_latched) begin
                    state_d = DATA_RX;
                end

                if (tx_enable) begin
                    state_d = DATA_TX;
                end
            end

            DATA_RX: begin
                cntr_4b_en = 1'b1;

                // max 8bit data
                if (cntr_4b_q == 4'd8 && scl_fall) begin
                    rx_done = 1'b1;
                    state_d = ACK_RX;
                end
                
                // sample data on scl rise
                if (scl_rise) begin
                    cntr_4b_incr = 1'b1;

                    // MSB first
                    data_reg_d[7:1] = data_reg_q[6:0];
                    data_reg_d[0] = sda_latched;
                end

                // stopbit condition
                if (scl_latched && sda_rise) begin
                    state_d = IDLE;
                end

            end


            DATA_TX: begin
                sda_t = 1'b1;
                cntr_4b_en = 1'b1;

                sda_o = data_in[7-cntr_4b_q];

                if (scl_fall) begin
                    cntr_4b_incr = 1'b1;

                    if (cntr_4b_q == 3'd7) begin
                        state_d = ACK_TX;
                    end
                end

                if (scl_rise && cntr_4b_q == 3'd7) begin
                    tx_done = 1'b1;
                end

                // undriven tx enable immediately aborts transmittion
                if (!tx_enable) begin
                    state_d = IDLE;
                end
            end

            ACK_RX: begin
                sda_t = 1'b1;
                sda_o = ack_in;

                if (scl_fall) begin
                    if (tx_enable) begin
                        // clear the counter in advance
                        cntr_4b_en = 1'b0;
                        state_d = DATA_TX;
                    end else begin
                        state_d = DATA_RX;
                    end
                end
            end 

            ACK_TX: begin
                
                if (~sda_latched) begin
                    ack_out_d = 1'b0;
                end else begin
                    ack_out_d = 1'b1;
                end
                
                if (scl_fall) begin
                    // ACK
                    if (~ack_out_q) begin
                        state_d = DATA_TX;
                    end 
                    // NACK
                    else begin
                        state_d = IDLE;
                    end
                end
            end

            default: begin

            end
        endcase
    end

    assign data_out = data_reg_q;
    assign core_processing = (state_q != IDLE) ? 1'b1 : 1'b0;
    assign ack_out = ack_out_q;

endmodule
