
package i2c_slave_seq_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import i2c_agent_pkg::*;
    import clk_agent_pkg::*;
    import rst_agent_pkg::*;
    
    `include "i2c_slave_seq_rw.svh"

endpackage: i2c_slave_seq_pkg
