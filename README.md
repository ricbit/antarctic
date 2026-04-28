# Antarctic Adventure

Complete disassembly of the MSX game by Konami, 1983-1984.

These sources produce bit-perfect binaries of all three known cartridge 
variants of the game. Compile using [sjasmplus](https://github.com/z00m128/sjasmplus).

## Files

| File              | ROM variant          | MD5        |
| ----------------- | -------------------- | ---------- |
| `antarctic_1.asm` | First release  (JP)  | `97ee96f0` |
| `antarctic_2.asm` | Second release (JP)  | `31620f84` |
| `antarctic_3.asm` | Third release  (EU)  | `4b1b0ab3` |

## What's in here

The source has symbolic names for all routines and data. I tried to add
semantic information using macros, in order to explain most magic numbers.

## Differences between releases

### First release

- Made in 1983, japanese market.
- Contains typo on opening screen ("KEYBOABD").
- All access to the hardware is made by I/O ports.
- Initial logo is black with message "VIDEO CARTRIDGE".
- Some debug code left over by the developers is still present.

### Second release

- Made in 1984, japanese market.
- Fixed the typo.
- All access to the hardware is made using the BIOS.
- Initial logo is still the same black one.
- Debug code was removed.

### Third release

- Made in 1984, european market.
- Based on the second release, with extensive changes.
- Initial logo is blue with message "KONAMI SOFTWARE".
- Replaced the New Zealand station with another USA one.
- Stage order is remixed, the South Pole arrives at stage 2 instead of stage 9.
- Graphics changes to spell "S. Pole" instead of 南極点.
- Some stages have day and night flipped.
- Copy protection to ensure the game only runs from cartridges.
- Unknown data at the end of the ROM (possible easter egg?)

## Credits

Disassembly and annotations by Ricardo Bittencourt
(<bluepenguin@gmail.com>).

Presented for historic purposes only, if you are the owner of the IP please contact me.
