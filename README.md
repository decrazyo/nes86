
![NES86 logo](https://github.com/decrazyo/nes86/blob/main/img/nes86.png)

# NES86
NES86 is an IBM PC emulator for the NES.  
The goal of this project is to emulate an Intel 8086 processor and supporting PC hardware
well enough to run the
[Embeddable Linux Kernel Subset (ELKS)](https://github.com/ghaerr/elks),
including a shell and utilities.
It should be possible to run other x86 software
as long as it doesn't require more than a simple serial terminal.

[Watch the video!](https://www.youtube.com/watch?v=OooHTDMUSGY)


## How to run NES86
![FCEUX running NES86](https://github.com/decrazyo/nes86/blob/main/img/fceux.png)

Download the NES ROM containing NES86 and ELKS from the [releases](https://github.com/decrazyo/nes86/releases) page.
See the [Binaries](#binaries) section for descriptions of the available binaries.
NES86 is not supported on all platforms.
The following platforms have been tested and Mesen2 or an Everdrive N8 Pro is recommended.

| platform | working? | issues |
|----------|----------|---------|
| [Mesen2](https://www.mesen.ca/) | ✅ | none |
| [FCEUX](https://fceux.com/web/home.html) | ✅ | overscan, keyboard detection |
| [Rustico](https://rustico.reploid.cafe/) | ✅ | overscan, no keyboard |
| [ksNes (Animal Crossing)](https://rustico.reploid.cafe/) | ✅ | overscan, no keyboard, special ROM required, mapper hack required |
| [Nestopia](https://nestopia.sourceforge.net/) | ❌ | not enough cartridge RAM |
| [Mesen](https://www.mesen.ca/oldindex.php) | ❌ | not enough cartridge RAM |
| [BizHawk](https://tasvideos.org/BizHawk) | ❌ | not enough cartridge RAM |
| [Everdrive N8 Pro](https://krikzz.com/our-products/cartridges/everdrive-n8-pro-72pin.html) | ✅ | none |
| [Everdrive N8](https://krikzz.com/our-products/legacy/edn8-72pin.html) | ✅ | special ROM required, mapper hack required |
| [PowerPak](https://www.nesdev.org/wiki/PowerPak) | ❌ | many |


## Binaries
| file | description |
|------|-------------|
| nes86.nes | standard NES86 ROM |
| nes86.dbg | standard NES86 ROM debug symbols |
| nes86_ksnes.nes | NES86 ROM built for Animal Crossing |
| animal_crossing.gci | Animal Crossing save file with an NES item |
| mmc5_patch.gci | Animal Crossing MMC5 mapper patch |
| nes86.gci | NES86 ROM injected in a GameCube save file for use with Animal Crossing |
| nes86_edfc.nes | NES86 ROM built for the original Everdrive N8 |
| 005.RBF | Everdrive N8 MMC5 mapper patched to support NES86 |


## Controls

### Family BASIC Keyboard
NES86 supports the [Family BASIC Keyboard](https://www.nesdev.org/wiki/Family_BASIC_Keyboard) as an input device.
If a keyboard is detected at boot then it will be used automatically.

### On-screen Keyboard
If no keyboard is detected at boot then an on-screen keyboard will be made available.
Pressing **SELECT** will open/close the on-screen keyboard.
With the keyboard open, pressing **B** will type the selected key and **A** serves as a dedicated **Enter** key.

### Joypad Mapping
Joypad buttons are mapped directly to the following keys when the on-screen keyboard is closed.
This is done to make it easier to play `ttytetris` without a keyboard.
| joypad button | keyboard key | purpose |
|---------------|--------------|---------|
A | k | rotate clockwise
B | j | rotate counterclockwise
START | p | pause
SELECT |  | open keyboard
UP | Space | hard drop
DOWN | s | soft drop
LEFT | h | move left
RIGHT | l | move right


## How to build NES86
1. Clone the project and its submodules.  
`git clone --recurse-submodules https://github.com/decrazyo/nes86.git`
2. Install dependencies.  
`apt install make cc65 gcc-ia16-elf`

### Build ELKS
The following steps will build an ELKS image that is compatible with NES86.

 1. Enter the `elks` directory.  
`cd nes86/data/elks/elks/`
 2. Create a `cross` directory.  
`mkdir cross`
 3. Setup your environment.  
`. ./env.sh`  
 4. Build the cross tool chain. This will take a while.  
`tools/build.sh`
 5. Copy or rename the provided configuration file.  
`cp nes86.config .config`
 6. Build ELKS.  
`make all`

### Build NES86
By default, the NES86 build process will use the ELKS image that was built in the previous step.
If you would like to run some other x86 software then you'll probably need to modify
`data/Makefile`, `src/x86/rom.s`, and `conf/ld.cfg`

1. Return to the top level NES86 directory.  
`cd ../../../`
2. Build NES86.  
`make all`

The resulting NES ROM can be found at `nes86/bin/nes86.nes`.

## Contributing to NES86
Contributions and ports are welcome.
See
[STYLE.md](https://github.com/decrazyo/nes86/blob/main/STYLE.md)
for the project's coding style guidelines.
