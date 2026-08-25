
package i2c_slave_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import i2c_agent_pkg::*;
    
    import i2c_slave_env_pkg::*;
    import i2c_slave_seq_pkg::*;
    
    `include "i2c_slave_test_base.svh"
    `include "i2c_slave_test_rw.svh"

endpackage: i2c_slave_test_pkg
