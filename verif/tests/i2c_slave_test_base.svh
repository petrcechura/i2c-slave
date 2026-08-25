import ocf_uvm_pkg::*;

class i2c_slave_test_base extends uvm_test;

    `uvm_component_utils(i2c_slave_test_base)

    i2c_slave_env m_i2c_slave_env;
    i2c_slave_env_config m_i2c_slave_env_config;

    ocf_report_server m_ocf_report_server;

    extern function new(string name = "i2c_slave_test_base", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);

endclass: i2c_slave_test_base

function i2c_slave_test_base::new(string name = "i2c_slave_test_base", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void i2c_slave_test_base::build_phase(uvm_phase phase);

    m_i2c_slave_env =        i2c_slave_env::type_id::create("m_i2c_slave_env", this);
    m_i2c_slave_env_config = i2c_slave_env_config::type_id::create("m_i2c_slave_env_config", this);

    uvm_config_db #(i2c_slave_env)::set(this, 
                                             "i2c_slave",
                                             "env",
                                             m_i2c_slave_env);

    uvm_config_db #(i2c_slave_env_config)::set(this, 
                                             "i2c_slave",
                                             "env_config",
                                             m_i2c_slave_env_config);

    
    m_ocf_report_server = ocf_report_server::type_id::create("m_ocf_report_server", this);
    uvm_report_server::set_server(m_ocf_report_server);

endfunction: build_phase
