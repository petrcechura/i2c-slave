

package i2c_slave_env_pkg;

    `include "i2c_slave_env_config.svh"
    `include "i2c_slave_env.svh"

    typedef enum int { 
        CLK_I2C_SLAVE,
        _CLK_COUNT
    } clk_id_t;

    typedef enum int {
        RST_I2C_SLAVE,
        _RST_COUNT
    } rst_id_t;

endpackage