


interface i2c_slave_if;

`ifndef USING_VERILATOR
    wire sda;
    wire scl;
`else
    wire sda_i;
    wire sda_o;
    wire sda_t;
    wire scl_i;
    wire scl_o;
    wire scl_t;
`endif

endinterface