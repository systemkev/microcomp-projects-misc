# 6.115 Microcomputer Projects (8051 Assembly)

This repository contains a collection of 8051/8032 assembly programs written for the 6.115 Microcomputer Project Laboratory. These files cover everything from basic I/O and serial communication to complex hardware interfacing, including DACs, ADCs, LCD displays, and stepper motors. 

## Project Highlights

This repo is a mix of foundational labs and more advanced hardware control routines:

*   **The "Lazerdillo" (Laser Projector):** Uses a 256-step sine lookup table and Timer 0 interrupts (running at 5120 Hz) to drive X and Y DACs. Draws circles, Lissajous curves, and a "TIE Fighter" shape with a laser. Includes rotational math to spin the shapes in real-time via serial commands.
*   **"SpinDude" (Optical Scanner):** Controls a stepper motor via an 8255 PPI and an L293D driver to rotate a turntable. It fires specific LEDs, waits for the light to settle, reads the reflection intensity via an ADC, and prints the formatted hex values over serial.
*   **Digital Voltmeter:** Reads analog voltage from an ADC, performs 16-bit multiplication/division to scale the 0-255 reading to a 0-5000mV range, extracts the decimal digits, and prints the exact voltage to an LCD display.
*   **MINMON (Minimal Monitor):** A modified version of the Rigel Corp 8051 monitor program. Allows reading/writing to external memory, executing code at specific addresses, and downloading Intel Hex files directly into RAM over serial.
*   **Serial Calculator & Hardware Math:** Takes ASCII input from a terminal, converts it to binary, performs 16-bit addition, subtraction, multiplication, and division, and pushes the formatted result back to the screen.

## Hardware Architecture

The code is designed around a standard 8032/8051 architecture with external memory-mapped peripherals. Common memory addresses used across these files include:

*   **`0xFE00` - `0xFE14`:** Digital-to-Analog Converters (DACs) for X/Y vector graphics.
*   **`0xFE10` - `0xFE20`:** Analog-to-Digital Converters (ADC) for optical scanning and voltmeter readings.
*   **`0xFE30` - `0xFE33`:** 8255 Programmable Peripheral Interface (PPI). Used for LCD data/control lines and stepper motor phase switching.
*   **`0x9000` - `0x9007`:** External RAM addresses used for storing operands and results for memory-mapped math operations.

## Notes

*   Serial communication is universally set to **9600 baud** using Timer 1 (auto-reload mode) with an 11.0592 MHz crystal.
*   Wait states and nested delay loops are heavily utilized to accommodate the slow execution times of external hardware (such as HD44780 LCD controllers, ADC conversion times, and mechanical motor settling). 

---
*Party on in 6.115!*