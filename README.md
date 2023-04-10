# OCEAN

## Running the simulator

Command line parameters:
```
USAGE: simulator --input-file-path <input.modraw> --output-file-path <output.modraw> [--speed <multiplier>] [--verbose]

OPTIONS:
  -i, --input-file-path <input.modraw>
                          Input .modraw file path.
  -o, --output-file-path <output.modraw>
                          Output .modraw file path.
  -s, --speed <multiplier>
                          Time multiplier. (default: 1.0)
  -v, --verbose           Show extra information.
  -h, --help              Show help information.
```

Building and invoking:
```
cd sim
swift build -c release
.build/release/sim -i original.modraw -o simulated.modraw -s 2 -v
```

One line way to build and run:
```
cd sim
swift run -c release sim -i original.modraw -o simulated.modraw -s 2 -v
```
