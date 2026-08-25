
// TODO
class i2c_scoreboard extends uvm_object;

    `uvm_component_utils(i2c_monitor)

    uvm_analysis_port #(i2c_seq_item) ap;

    virtual i2c_if sline;

    i2c_agent_config cfg;

    logic clk;

    /* events */
    event startbit_evt;
    event stopbit_evt;
    event databit_evt;
    event reset_evt;

    i2c_seq_item seq_item;

    typedef enum {
        IDLE, 		// monitor is idle, waiting on startbit to sample communication
        SAMPLE,		// monitor samples data bit by bit
        ACK,		// monitor sampled data amount of `WORD_SIZE`, now expects ack/nack
    	END			// NACK has occured, ending sequence is expected & go to IDLE
    } t_state;

    localparam int WORD_SIZE = 8;

    /* constructor */
    function new(string name = "i2c_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
      ap = new("i2c_ap", this);

      if (!uvm_config_db #(i2c_agent_config)::get(this, "", "i2c_agent_config", cfg) )
         `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration i2c_agent_config from uvm_config_db. Have you set() it?")

    endfunction: build_phase

    task run_phase(uvm_phase phase);
      begin
          /* wait for any monitored event on the bus*/
          fork
              startbit;
              stopbit;
              databit;
              reset;

              monitor;
          join_none
      end
    endtask : run_phase

    task startbit;
        forever begin
            @(negedge sline.sda iff (sline.scl_w === 1'b1 && sline.rst_n === 1'b1));
            -> startbit_evt;
        end
    endtask: startbit

    task stopbit;
        forever begin
            @(posedge sline.sda iff (sline.scl_w === 1'b1 && sline.rst_n === 1'b1));
            -> stopbit_evt;
        end
    endtask: stopbit

    task databit;
        forever begin
            @(posedge sline.scl iff (sline.rst_n === 1'b1));
            -> databit_evt;
        end
    endtask: databit

    task reset;
        forever begin
            @(negedge sline.rst_n);
            -> reset_evt;
        end
    endtask: reset

    task monitor;
        automatic logic data[];
        automatic t_state state = IDLE;
    	automatic bit db = 1'b0;

        forever begin

            case (state)

    			// Monitor now awaits start of the communication (STARTBIT) or reset. 
    			// Every other event is considered as error.
    			// STARTBIT leads to SAMPLE state
                IDLE: begin
                    data.delete();
                    @(startbit_evt or stopbit_evt or databit_evt or reset_evt);

    				if (reset_evt.triggered) begin
                        automatic i2c_seq_item i2c_item = i2c_seq_item::type_id::create("seq_item");
    					seq_item.data = '{1'bX};
    					ap.write(seq_item);
    				end

                    else if (startbit_evt.triggered && sline.rst_n === 1'b1) begin
                        state = SAMPLE;
                    end
                    else if (databit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", $sformatf("IDLE: Unexpected databit")); //TODO msg
                    end
                    else if (stopbit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", $sformatf("IDLE: Unexpected stopbit"));
                    end
                end

    			// Monitor begins to sample databits to its internal array `data` 
    			// and continues so until the limit defined by `WORD_SIZE`.
    			// Every other event (than DATABIT) is considered as an error.
    			// After filling `data` monitor goes to state ACK
                SAMPLE: begin
                    @(startbit_evt or stopbit_evt or databit_evt or reset_evt);

                    if (reset_evt.triggered) begin
                        state = IDLE;
                    end

                    else if (databit_evt.triggered && sline.rst_n === 1'b1) begin
                        /* data sample */
                        data = {sline.sda_w, data};

                        if (data.size() == WORD_SIZE) begin
                            state = ACK;
                        end
                    end

                    else if (stopbit_evt.triggered && sline.rst_n === 1'b1) begin
                        automatic i2c_seq_item seq_item = i2c_seq_item::type_id::create("seq_item");
                        seq_item.stopbit = 1'b1;
                        ap.write(seq_item);

                        state = IDLE;
                    end

                    else if (startbit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", "unexpected startbit");
                        state = IDLE;
                    end
                end
            
    			// Monitor now expects ack (databit with 1'b0) or nack (databit with 1'b1).
    			// If ack: monitor goes to SAMPLE state and continues to sample databits
    			// If nack: monitor goes to END state and aborts further sample.
    			// Any other event (than DATABIT) considered as an error.
                ACK: begin
                    @(startbit_evt or databit_evt or stopbit_evt or reset_evt);

                    if (reset_evt.triggered) begin
                        state = IDLE;
                    end

                    else if (databit_evt.triggered && sline.rst_n === 1'b1) begin

                        /* ACK */
                        if (sline.sda_w === 1'b0) begin
                            automatic i2c_seq_item seq_item = i2c_seq_item::type_id::create("seq_item");
                            seq_item.data = data;
                            ap.write(seq_item);
                            state = SAMPLE;
                            data.delete();
                        end
                        /* NACK */
                        else begin
    						db = 1'b0;
                            state = END;
                        end

                    end

                    else if (startbit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", "ACK: unexpected startbit");
                        state = IDLE;
                    end

                    else if (stopbit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", "ACK: unexpected stopbit");
                        state = IDLE;
                    end

                end
            
    			// Monitor received ack/nack and now the ending sequence is expected
    			// ending sequence is as follows: DATABIT-STOPBIT
    			// ("extra" databit before stopbit is expected bcs SCL needs to go 1'b1 when SDA = 1'b1 for stopbit to happen)
    			// After receiveing this sequence, state goes to IDLE
    			END: begin
                    @(startbit_evt or databit_evt or stopbit_evt or reset_evt);

                    if (reset_evt.triggered) begin
                        state = IDLE;
                    end

                    else if (databit_evt.triggered && sline.rst_n === 1'b1) begin
    					if (!db)
    						db = 1'b1;
    					else begin
    						`uvm_error("", "END: unexpected databit!");
    					end

                    end

                    else if (startbit_evt.triggered && sline.rst_n === 1'b1) begin
                        `uvm_error("", "END: unexpected startbit");
                        state = IDLE;
                    end

                    else if (stopbit_evt.triggered && sline.rst_n === 1'b1) begin
    					automatic i2c_seq_item seq_item = i2c_seq_item::type_id::create("seq_item");
                        seq_item.stopbit = 1'b1;
                        ap.write(seq_item);

    					state = IDLE;
    					if (!db)
    						`uvm_error("", "END: databit expected first...");
                    end
    			end
            endcase
        end

    endtask: monitor

    task bitPeriod;
      begin
        repeat(16)
          @(posedge sline.clk);
      end
    endtask

endclass: i2c_monitor
