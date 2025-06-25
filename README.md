# Pong_Boot_Sector
This is a minimal implementation of the classic Pong game that runs without an operating system in 16-bit real mode. The game executes primarily from the boot sector (first 512 bytes of the disk), with supporting image data loaded from subsequent disk sectors into memory. It boots straight into the game on real hardware or in an emulator, showcasing low-level x86 programming and direct hardware control.

### Assembling and running
