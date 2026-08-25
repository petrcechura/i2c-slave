
class i2c_slave_seq_rw extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_slave_seq_rw)

    function new(string name = "i2c_slave_seq_rw");
        super.new(name);
    endfunction

    const bit[6:0] ADDR = 7'b0000110;
    const bit      BIT_RD = 1'b0;
    const bit      BIT_WR = 1'b1;

    task body;
      	automatic i2c_seq_item frame = i2c_seq_item::type_id::create("frame");
        automatic logic[7:0] data[];

        // Set clock running (20ns)
        // ------------------------
        `uvm_info("application", "Setting a clock to 50 MHz.", UVM_MEDIUM);
        clk_set_period(i2c_slave_env_pkg::CLK_I2C_SLAVE, 20ns);
        clk_on(i2c_slave_env_pkg::CLK_I2C_SLAVE);

        // Resetting DUT
        // -------------
        `uvm_info("application", "Reseting DUT for 20ns...", UVM_MEDIUM);
        rst_assert(i2c_slave_env_pkg::RST_I2C_SLAVE, 200ns);

        `uvm_info("application", $sformatf("Setting device address to %b", ADDR), UVM_MEDIUM);
        frame.set_addr_default(ADDR);
        #2000ns;

      	// Send custom data
        // ----------------
        `uvm_info("application", "Writing data to first reg...", UVM_MEDIUM);
      	start_item(frame);

        frame.command_write(8'b1, '{8'b11001010});
      	finish_item(frame);
        frame.clear();

        #1000ns;

        `uvm_info("application", "Writing data to second reg...", UVM_MEDIUM);
      	start_item(frame);

        frame.command_write(8'b10, '{8'b11110010});
      	finish_item(frame);
        frame.clear();

        #1000ns;

        `uvm_info("application", "Trying to access unknown device...", UVM_MEDIUM);
      	start_item(frame);

        frame.addr = ~ADDR;
        frame.command_write(8'b10, '{8'b11100110});
      	finish_item(frame);
        frame.clear();
        frame.addr = ADDR;

        #1000ns;

        `uvm_info("application", "Reading first register...", UVM_MEDIUM);
      	start_item(frame);

        frame.command_read(8'b1, 2);
      	finish_item(frame);
        frame.clear();

        clk_off(i2c_slave_env_pkg::CLK_I2C_SLAVE);

    
    endtask: body

endclass: i2c_slave_seq_rw
