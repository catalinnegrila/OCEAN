# OCEAN

## Running the simulator

Command line parameters:
```
USAGE: sim --input-file-path <input-file-path> --output-file-path <output-file-path> [--speed <multiplier>] [--verbose]

OPTIONS:
  -i, --input-file-path <input-file-path>
                          Input .modraw file path, or @listOfFiles.txt, or
                          folder to scan for .modraw files.
  -o, --output-file-path <output-file-path>
                          Output .modraw file path, or folder to write to.
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
.build/release/sim -i ./one_folder/original.modraw -o ./another_folder -s 2 -v
.build/release/sim -i ./folder_of_modraws -o ./output_folder -s 2 -v
.build/release/sim -i @list_of_modraws.txt -o ./output_folder -s 2 -v
```

Input can be:
- a single .modraw file, or
- a folder that will be scanned for all .modraw files, or
- a text file containing a list of .modraw file names or paths.

If a text file is passed in, the path to the file must be prefixed by a "@" character.

If the file names or paths contained in this text-based list file are relative (i.e. they
don't start with "/"), they will be considered relative to the location where the text file is located,
as opposed to the current folder or wherever the simulator resides. The order of the .modraw
files in this list is respected. Lines beginning with '#' are considered comments and ignored.

If a folder gets passed in as input, the .modraw files contained within will be processed
in alphabetical order. To process them in any other order you will have to create a list
file with the specific .modraw file paths you want and pass it in via the `-i @mylist.txt` syntax.

Output can be a single .modraw file (which is permitted only if the input is a single
.modraw file as well), or more flexibly it may be a folder. This folder must already exist so be sure
to manually create it before invoking the simulator. Files in the output folder will be created
with names mirroring the files in the input folder or text-based file list. If files with those same names
already exist in the output folder they will be deleted, however any files with different names
already present in the output folder will be preserved.
 