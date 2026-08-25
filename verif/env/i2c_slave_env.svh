import uvm_pkg::*;
import i2c_agent_pkg::*;
import clk_agent_pkg::*;
import rst_agent_pkg::*;

class i2c_slave_env extends uvm_component;

    `uvm_component_utils(i2c_slave_env)
    
    // I2C agent
    // ---------
    i2c_agent m_i2c_agent;
    i2c_agent_config m_i2c_agent_config;

    // CLK agent
    // ---------
    clk_agent       #(.CLK_COUNT(i2c_slave_env_pkg::_CLK_COUNT)) m_clk_agent;
    clk_agent_config#(.CLK_COUNT(i2c_slave_env_pkg::_CLK_COUNT)) m_clk_agent_config;

    // RST agent
    // ---------
    rst_agent       #(.RST_COUNT(i2c_slave_env_pkg::_RST_COUNT)) m_rst_agent;
    rst_agent_config#(.RST_COUNT(i2c_slave_env_pkg::_RST_COUNT)) m_rst_agent_config;
    
    extern function new(string name = "i2c_slave_env", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass

function i2c_slave_env::new(string name = "i2c_slave_env", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void i2c_slave_env::build_phase(uvm_phase phase);

    // Set RST active level values
    // --------------------------- 
    uvm_config_db#(bit)::set(null, "rst_agent", $sformatf("active_level_%0d", i2c_slave_env_pkg::RST_I2C_SLAVE), 1'b1);


    // instantiate I2C agent & its config
    // ----------------------------------
    m_i2c_agent = i2c_agent::type_id::create("m_i2c_agent", this);
    m_i2c_agent_config = i2c_agent_config::type_id::create("m_i2c_agent_config", this);

    // instantiate CLK agent & its config
    // ----------------------------------
    m_clk_agent = clk_agent#(.CLK_COUNT(i2c_slave_env_pkg::_CLK_COUNT))::type_id::create("m_clk_agent", this);
    m_clk_agent_config = clk_agent_config#(.CLK_COUNT(i2c_slave_env_pkg::_CLK_COUNT))::type_id::create("m_clk_agent_config", this);

    // instantiate RST agent & its config
    // ----------------------------------
    m_rst_agent = rst_agent#(.RST_COUNT(i2c_slave_env_pkg::_RST_COUNT))::type_id::create("m_rst_agent", this);
    m_rst_agent_config = rst_agent_config#(.RST_COUNT(i2c_slave_env_pkg::_RST_COUNT))::type_id::create("m_rst_agent_config", this);


    // Connect interfaces to from config_db to the agents
    // --------------------------------------------------

    // -- I2C agent interface --
    if (uvm_config_db#(virtual i2c_if)::exists(null, "uvm_test_top", "i2c_ifc")) begin
        uvm_config_db#(virtual i2c_if)::get(null, 
                                        "uvm_test_top",
                                        "i2c_ifc",
                                        m_i2c_agent_config.sline);
    end
    else begin
        `uvm_fatal("build_phase", "Unable to find I2C interface in the uvm_config_db");
    end

    // -- CLK agent interface --
    if (uvm_config_db#(virtual clk_if)::exists(null, "uvm_test_top", "clk_ifc")) begin
        uvm_config_db#(virtual clk_if)::get(null, 
                                        "uvm_test_top",
                                        "clk_ifc",
                                        m_clk_agent_config.sline);
    end
    else begin
        `uvm_fatal("build_phase", "Unable to find CLK interface in the uvm_config_db");
    end

    // -- RST agent interface --
    if (uvm_config_db#(virtual rst_if)::exists(null, "uvm_test_top", "rst_ifc")) begin
        uvm_config_db#(virtual rst_if)::get(null, 
                                        "uvm_test_top",
                                        "rst_ifc",
                                        m_rst_agent_config.sline);
    end
    else begin
        `uvm_fatal("build_phase", "Unable to find RST interface in the uvm_config_db");
    end

    // store i2c_agent & its config to config_db
    // -----------------------------------------
    m_i2c_agent.m_i2c_agent_config = m_i2c_agent_config;
    uvm_config_db#(i2c_agent_config)::set(null, "i2c_slave", "i2c_agent_config", m_i2c_agent.m_i2c_agent_config);

    // store clk_agent & its config to config_db
    // -----------------------------------------
    m_clk_agent.m_clk_agent_config = m_clk_agent_config;
    uvm_config_db#(clk_agent_config)::set(null, "i2c_slave", "clk_agent_config", m_clk_agent.m_clk_agent_config);

    // store rst_agent & its config to config_db
    // -----------------------------------------
    m_rst_agent.m_rst_agent_config = m_rst_agent_config;
    uvm_config_db#(rst_agent_config)::set(null, "i2c_slave", "rst_agent_config", m_rst_agent.m_rst_agent_config);


endfunction: build_phase

// TODO
function void i2c_slave_env::connect_phase(uvm_phase phase);

endfunction: connect_phase
