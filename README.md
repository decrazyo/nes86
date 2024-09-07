
![NES86 logo](https://github.com/decrazyo/nes86/blob/main/img/nes86.png)

# NES86
NES86 is an IBM PC emulator for the NES.  
The goal of this project is to emulate an Intel 8086 processor and supporting PC hardware
well enough to run the
[Embeddable Linux Kernel Subset (ELKS)](https://github.com/ghaerr/elks),
including a shell and utilities.
It should be possible to run other x86 software
as long as it doesn't require more than a simple serial terminal.
<!-- TODO: add a link to the youtube video when i make one -->


## How to run NES86
![FCEUX running NES86](https://github.com/decrazyo/nes86/blob/main/img/fceux.png)

<!-- TODO: add link to releases once i create a release-->
Download the NES ROM containing NES86 and ELKS from the releases page
or build ELKS and NES86 from source.
NES86 uses a mapper configuration that is theoretically valid
but generally not supported by emulators nor flash cartridges.
The following platforms have been tested.

| platform | working? |
|----------|----------|
| [FCEUX](https://fceux.com/web/home.html) | ✅ |
| [Nestopia](https://nestopia.sourceforge.net/) | ❌ |
| [Mesen](https://www.mesen.ca/oldindex.php) | ❌ |
| [Mesen2](https://www.mesen.ca/) | ❌ |
| [BizHawk](https://tasvideos.org/BizHawk) | ❌ |
| [Everdrive N8](https://krikzz.com/our-products/legacy/edn8-72pin.html) | ❌ |


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
