# i2c-slave

A simple, generic **7-bit I²C slave** implementation with a register-based interface and UVM verification environment.

> [!WARNING]
> **This repository is currently under development.**
>
> The README is currently used partly as development notes and may not yet fully describe the implemented functionality.

## Features

* **7-bit I²C slave address**
* **8-bit register/data interface**
* Register-based interface for easy integration into larger systems
* Handles I²C link-layer communication internally
* **UVM-based verification environment**
* Clock stretching — **not implemented yet**

For low-level details of the I²C protocol, see the [I²C-bus specification (UM10204)](https://www.nxp.com/docs/en/user-guide/UM10204.pdf).

---

## Overview & Usage

`i2c-slave` is designed to be a **generic and simple-to-integrate I²C slave**.

The module handles the low-level I²C communication as well as the link-layer protocol, including:

* slave address detection
* register address handling
* read/write direction
* data transfer
* ACK/NACK handling

The user-facing interface exposes only the register interface. The actual registers and their behaviour are implemented by the surrounding system.

### Integration

A typical integration looks like this:

<p align="center">
  <img src="pics/i2c_slave_regs.png" width="900" alt="I2C slave integrated into a larger design">
</p>

The `i2c-slave` module therefore acts as an interface between the physical I²C bus and a set of application-specific registers.

### I²C Link Layer

The top-level design follows a common I²C link-layer pattern:

<p align="center">
  <img src="pics/i2c_link_layer.png" width="900" alt="I²C link-layer communication">
</p>

This behaviour is implemented inside `i2c-slave` and builds on the lower-level [`i2c_slave_core.sv`](src/i2c_slave_core.sv) module.

`i2c_slave_core.sv` operates on individual bits and does not interpret the higher-level meaning of the received data. This separation makes it possible to reuse the core when implementing a different link-layer protocol or communication pattern.

---

## Verification

Verification is managed using [open-chip-flow (OCF)](https://github.com/petrcechura/open-chip-flow), with a dedicated UVM library and custom verification agents for I²C, clocking, and other interfaces.

### Getting the repository

Clone the repository together with its submodules:

```bash
git clone --recurse-submodules git@github.com:petrcechura/i2c-slave.git
cd i2c-slave
```

### Running verification

A symbolic link to `run.py` is provided in the repository root.

To see the available OCF options:

```bash
python3 run.py --help
```

For example, to run the read/write test:

```bash
python3 run.py verif i2c_slave.yaml --test i2c_slave_test_rw
```

## TODO

* [ ] Implement clock stretching
* [ ] Create verification matrix
* [ ] Implement all the tests
