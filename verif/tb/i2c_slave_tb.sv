`include "uvm.sv"
`include "uvm_macros.svh"

`define USING_VERILATOR

module i2c_slave_tb;

    import uvm_pkg::*;
    import i2c_slave_env_pkg::*;

    // Interfaces
    // ----------
    i2c_slave_if i2c_slave_ifc();
    i2c_if i2c_ifc();
    clk_if clk_ifc();
    rst_if rst_ifc();

    // Connect interfaces
    // ------------------
`ifndef USING_VERILATOR
    assign i2c_slave_core_ifc.sda = i2c_ifc.sda_wire;
    assign i2c_slave_core_ifc.scl = i2c_ifc.scl_wire;
`else
    assign sda_t[1] = i2c_ifc.sda_en;
    assign i2c_ifc.sda_i = sda_i[1];
    assign sda_o[1] = i2c_ifc.sda_o;
    assign scl_t[1] = i2c_ifc.scl_en;
    assign i2c_ifc.scl_i = scl_i[1];
    assign scl_o[1] = i2c_ifc.scl_o;
`endif
    assign i2c_ifc.clk = clk_ifc.clk[i2c_slave_env_pkg::CLK_I2C_SLAVE];
    assign i2c_ifc.rst = rst_ifc.rst[i2c_slave_env_pkg::RST_I2C_SLAVE];
`ifndef USING_VERILATOR
    assign i2c_slave_ifc.sda = i2c_slave_core_ifc.sda;
    assign i2c_slave_ifc.scl = i2c_slave_core_ifc.scl;
`else
    assign sda_t[0] = i2c_slave_ifc.sda_t;
    assign i2c_slave_ifc.sda_i = sda_i[0];
    assign sda_o[0] = i2c_slave_ifc.sda_o;
    assign scl_t[0] = i2c_slave_ifc.scl_t;
    assign i2c_slave_ifc.scl_i = scl_i[0];
    assign scl_o[0] = i2c_slave_ifc.scl_o;
`endif

    // I2C slave instance
    // -----------------------
    i2c_slave dut
    (
        .slave_addr(7'b0000110),
        .clk(   clk_ifc.clk),
        .arst(  rst_ifc.rst),
        .i2c_slave_ifc(i2c_slave_ifc),
        .reg_select(rbank_select),
        .reg_val_in(rbank_val_out),
        .reg_val_out(rbank_val_in),
        .reg_val_valid(rbank_we)
    );
    
    logic[7:0] rbank_select;    
    logic[7:0] rbank_val_in;
    logic[7:0] rbank_val_out;
    logic      rbank_we;
    reg_bank reg_bank_i
    (
        .clk( clk_ifc.clk),
        .arst(rst_ifc.rst),
        .reg_select(rbank_select),
        .reg_val_in(rbank_val_in),
        .reg_val_out(rbank_val_out),
        .reg_we(rbank_we)
    );

`ifdef USING_VERILATOR
    logic[1:0] scl_t, scl_o, scl_i;
    logic[1:0] sda_t, sda_o, sda_i;
    i2c_bus#(.DEVICE_COUNT(2)) i2c_bus_i
    (
        .sda_i(sda_i),
        .sda_t(sda_t),
        .sda_o(sda_o),
        .scl_i(scl_i),
        .scl_t(scl_t),
        .scl_o(scl_o)
    );
`endif

    // Test run
    // -----------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
        uvm_config_db #(virtual i2c_slave_if)::set(null, "uvm_test_top", "i2c_slave_ifc", i2c_slave_ifc);
        uvm_config_db #(virtual i2c_if)::set(null, "uvm_test_top", "i2c_ifc", i2c_ifc);
        uvm_config_db #(virtual clk_if)::set(null, "uvm_test_top", "clk_ifc", clk_ifc);
        uvm_config_db #(virtual rst_if)::set(null, "uvm_test_top", "rst_ifc", rst_ifc);
        run_test();
    end

endmodule
