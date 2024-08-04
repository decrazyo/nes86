
![NES86 logo](https://github.com/decrazyo/nes86/blob/main/img/nes86.jpg)

# NES86
NES86 is an IBM PC emulator for the NES.  
The goal of this project is to emulate an Intel 8086 processor and supporting PC hardware
well enough to run an unmodified Linux kernel, shell, and utilities.
The emulator is currently capable of running the
[Embeddable Linux Kernel Subset (ELKS)](https://github.com/ghaerr/elks).
Limited RAM prevent ELKS from running more than the Stand-Alone Shell (sash)
and builtin shell utilities.
It should be possible to run other x86 software
as long as it doesn't require more than a simple serial terminal.
<!-- TODO: add a link to the youtube video when i make one -->

## How to run NES86
![Mesen2 running NES86](https://github.com/decrazyo/nes86/blob/main/img/mesen.jpg)

Download an NES ROM containing NES86 and ELKS from the releases page
or build ELKS and NES86 from source.
The only currently known way to run NES86 is with
[my modified version of Mesen2](https://github.com/decrazyo/Mesen2).
NES86 uses a mapper configuration that is theoretically valid
but generally not supported by emulators nor flash cartridges.
I've modified Mesen2 to support the mapper configuration that NES86 uses.

## How to build NES86
Before building NES86, we need to build some software for NES86 to run.

### Build ELKS
The following steps will build an ELKS image that is compatible with NES86.
These steps are provided for your convenience.
See the
[official ELKS build instructions](https://github.com/ghaerr/elks/blob/master/BUILD.md)
for the most up-to-date info.

 1. Enter the `elks` directory.
`cd data/elks/`
 2. Create a `cross` directory.
`mkdir cross`
 3. Build the cross tool chain. This will take a while.
`tools/build.sh`
 4. Setup your environment.
`. ./env.sh`
 5. Copy the provided configuration file to the `elks` directory.
`cp ../nes86-rom.config ./.config`
 6. Modify the configuration to your liking (optional).
`make menuconfig`
 7. Build ELKS.
`make all`

### Build NES86
By default, the NES86 build process will use the ELKS image that was built in the previous step.
If you would like to run some other x86 software then you'll probably need to modify
`data/Makefile`, `src/x86/rom.s`, and `conf/ld.cfg`

 1. Install dependencies.
`apt install make cc65 gcc-ia16-elf`
 2. Build NES86.
`make all`

The resulting NES ROM can be found at `bin/nes86.nes`.

## Contributing to NES86
Contributions and ports are welcome.
See
[STYLE.md](https://github.com/decrazyo/nes86/blob/main/STYLE.md)
for the project's coding style guidelines.
