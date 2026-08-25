class i2c_slave_test_rw extends i2c_slave_test_base;

    `uvm_component_utils(i2c_slave_test_rw)

    extern function new(string name = "i2c_slave_test_rw", uvm_component parent = null);
    extern task run_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);

endclass: i2c_slave_test_rw

function i2c_slave_test_rw::new(string name = "i2c_slave_test_rw", uvm_component parent = null);
    super.new(name, parent);
endfunction

task i2c_slave_test_rw::run_phase(uvm_phase phase);

    i2c_slave_seq_rw seq_rw = i2c_slave_seq_rw::type_id::create("i2c_slave_seq_rw");

    phase.raise_objection(this);

    seq_rw.start(m_i2c_slave_env.m_i2c_agent.m_i2c_sequencer);

    phase.drop_objection(this);
endtask: run_phase

function void i2c_slave_test_rw::report_phase(uvm_phase phase);
    `uvm_info("", "TEST RW DONE", UVM_LOW)

endfunction: report_phase
