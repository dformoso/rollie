# Motor SHIM for Pico — Product Brief

> **Manufacturer:** [Pimoroni](https://shop.pimoroni.com/products/motor-shim-for-pico)

---

## Overview

Motor SHIM for Pico is a neat little add-on board that lets you drive two micro metal gearmotors from a Raspberry Pi Pico — tiny robots ahoy!

Solder this SHIM to the back of your Pico and unlock the ability to plug in up to two micro metal gearmotors using [short motor cables](https://shop.pimoroni.com/products/motor-shim-cable). To connect them via cable, your motors will need to be equipped with [Motor Connector Shims](https://shop.pimoroni.com/products/motor-connector-shim) (also available [with motors pre-attached](https://shop.pimoroni.com/products/micro-metal-gearmotor-with-motor-connector-shim)).

In addition to the motor driver, Motor SHIM for Pico features a multi-purpose user button plus a Qw/ST connector so you can attach breakouts and give your robot some smarts.

Motor SHIM is designed to be as slimline as possible and uses minimal pins so it can be combined easily with other add-ons like [Pico Packs and Bases](https://shop.pimoroni.com/collections/pico).

## Key Features

- **Dual H-Bridge motor driver** (DRV8833)
- 2× JST-ZH connectors (2 pin) for attaching motors
- User button
- Qw/ST (Qwiic/STEMMA QT) connector for attaching breakouts
- Compatible with Raspberry Pi Pico
- Soldering required

## Dimensions

Approx **26mm × 21mm × 5mm** (L × W × H, including connectors)

## Assembly

Solder the SHIM to the back of your Pico, with the mounting holes lining up at the USB port end. The `PICO MOTOR SHIM` text on the SHIM and the pin labels on the back of the Pico should be facing each other.

## Software

### MicroPython

- [Download Pirate brand MicroPython](https://github.com/pimoroni/pimoroni-pico/releases)
- [MicroPython API documentation](https://github.com/pimoroni/pimoroni-pico/tree/main/micropython/modules/motor)
- [MicroPython examples](https://github.com/pimoroni/pimoroni-pico/tree/main/micropython/examples/pico_motor_shim)

### C++

- [C++ examples](https://github.com/pimoroni/pimoroni-pico/tree/main/examples/pico_motor_shim)

### CircuitPython

- [Getting Started with CircuitPython](https://learn.adafruit.com/welcome-to-circuitpython)
- [CircuitPython example](https://github.com/pimoroni/pico-circuitpython-examples/tree/main/pico_motor_shim)

## Resources

- [C++/MicroPython libraries (GitHub)](https://github.com/pimoroni/pimoroni-pico)
- [Schematic (PDF)](https://cdn.shopify.com/s/files/1/0174/1800/files/motor_shim_schematic.pdf?v=1652702111)

## Notes

- If you'd prefer not to attach Motor SHIM permanently to your Pico, consider soldering it to a pair of socket headers.
- For battery-powered robots, consider combining with a [LiPo SHIM for Pico](https://shop.pimoroni.com/products/pico-lipo-shim) or using a [Pimoroni Pico LiPo](https://shop.pimoroni.com/products/pimoroni-pico-lipo).
- Raspberry Pi Pico, headers and other components are sold separately.
