# i2c-slave
This repository holds simple implementation of 7bit I2C slave.

> [!WARNING]
> This repository is under development and this README now serves for notes rather than for description.

## Specification
- Bus width: 8bit
- Slave address width: 7bit


## Verification
Tests:
- Simple R/W
- Two subsequent reads
- Two subsequent writes
- Invalid slave address
- Asynchronous reset
- Communication interrupt