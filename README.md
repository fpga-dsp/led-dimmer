# VHDL LED Dimmer

A configurable PWM generator in VHDL for driving RGB LEDs with independent brightness control per channel. The design supports three independent PWM channels (Red, Green, Blue). A top-level wrapper for the Digilent Arty A7-100 (Artix-7) board is included, along with a sample constraints file to simplify project setup and synthesis in Xilinx Vivado.

## 🛠️ Features

- Independent PWM generation for Red, Green, and Blue channels
- Configurable duty cycle for each channel (0.1% resolution)
- Adjustable PWM frequency and input clock via generics
- Enable signal to gate output activity
- Includes wrapper for the Arty A7-100
- Includes a constraints file for the Arty A7-100
- Self-checking testbench for simulation-based verification

## 📁 File Overview

| File                         | Description                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| `led_dimmer.vhd`             | Core VHDL module with configurable PWM outputs               |
| `led_dimmer_arty_a7_top.vhd` | Arty A7-100-specific top-level wrapper with input sync logic |
| `led_dimmer_tb.vhd`          | Testbench with PWM verification logic                        |
| `arty_a7_led_dimmer.xdc`     | Constraints file for Arty A7-100                             |

## 🧪 Simulation

The testbench (`led_dimmer_tb.vhd`) validates the generated PWM signal for each channel against expected values, based on the configured duty cycles and clock frequency.

### Sim Tools

- **Simulators**: ModelSim, Vivado Simulator
- **Testbench**: Self-checking, no user input required

## 🚀 Synthesis & Deployment (Arty A7-100)

1. Launch Xilinx Vivado and create a new project targeting the **Digilent Arty A7-100** board.
2. Add `led_dimmer.vhd` and `led_dimmer_arty_a7_top.vhd` as design sources.
3. Set `led_dimmer_arty_a7_top.vhd` as the top module.
4. Add `led_dimmer_tb.vhd` as a simulation source (if simulation in Vivado).
5. Add `arty_a7_led_dimmer.xdc` as a constraints file.
6. Synthesize, implement, and program the bitstream to the FPGA.

### Board Defaults

This project is configured by default to use physical switch `sw0` as the enable input and RGB LED `led0` for PWM output on the Digilent Arty A7-100 board. These pin assignments can be modified by editing the `arty_a7_led_dimmer.xdc` constraints file.

By default, the LED color is set to a magenta (22% red, 0% green, 22% blue). You can change the color, as well as the clock speeds, in the top-level wrapper. Refer to the [Digilent Arty A7-100 reference manual](https://digilent.com/reference/programmable-logic/arty-a7/start) for guidance on making changes to pin assignments or available peripherals.

## ⚙️ Configuration Parameters

These generics allow fine-tuned control over the PWM signal characteristics:

- `r_duty_cycle` (0–1000) — Red duty cycle (0.1% per step)
- `g_duty_cycle` (0–1000) — Green duty cycle
- `b_duty_cycle` (0–1000) — Blue duty cycle
- `pwm_freq_hz` (10_000–20_000) — PWM output frequency
- `clk_freq_hz` (50_000_000–200_000_000) — System clock frequency

## 📌 Limitations

- This module **does not support dynamic brightness fading**. Duty cycles are static and set via generics.
- No interface for runtime control (e.g., switches, serial input) is provided out of the box — but can be added easily.

## 🧰 Tool Versions

- Last compiled with **Vivado v2023.1 (64-bit)**
- Simulated with **ModelSim - Intel FPGA Starter Edition 10.5b (Revision: 2016.10)**

## 📚 Article Series

Want a deeper look at the thought process and design behind this project?

Check out the LinkedIn article series:

- [FPGA-Based LED Dimmer: From Concept to Hardware (Part 1)](https://www.linkedin.com/pulse/fpga-based-led-dimmer-from-concept-hardware-part-1-hamdan-ph-d--awduc/?trackingId=dDCipr6%2BS8CEv0n0AmaguA%3D%3D)

More parts coming soon!

## 📜 License

[MIT License](https://github.com/fpga-dsp/led-dimmer/blob/main/LICENSE)

---

© 2025 Eric Hamdan (fpga.dsp@gmail.com)
