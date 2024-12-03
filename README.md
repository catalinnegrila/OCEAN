## Quick Setup Notes

### For the live environment

Setup `ModrawServer.py` on DEV1:
1. Copy to and run from DEV1 `./ModrawServer/ModrawServer.py`
2. You will want to edit this script and set `source_dir` appropriately near the top.
3. Leaving all other options to default should have this script run in non-simulated
mode over the TCP socket.
4. Running this script from any other machine than DEV1 will erase any performance
benefits over reading data from an SMB share.

Setup `ModrawVis` on DEV3:
1. Build the app using `./ModrawVis/build.sh`
2. By editing this script, it can be configured to automatically install the application
to a network location. If you have access to the **Desktop** or **Applications** folders on
DEV3, you can point it there.
3. If you want to manually copy the app, you will find it in `./ModrawVis/bin` after
running `./ModrawVis/build.sh` assuming no errors.
4. You can now start `ModrawVis` on DEV3.
5. Select **File -> Connect to DEV1** to have it automatically connect to 192.168.1.168.
6. If the IP has changed, you will need to recompile `ModrawVis` with the new address.
Search and replace it files, it should be in the `./ModrawVis/src/Views/FileMenuCommands.swift`
7. If you're able to `pip install zeroconf` on DEV1, that will allow `ModrawServer` to advertise
itself over the network. You can then simply select **File -> Connect with Bonjour** to
automatically discover the IP of DEV1.
8. If all else fails, you can always **File -> Open Folder...** to go in the usual
folder scanning mode. Note that this will introduce a lag as that folder gets
updated over SMB during acquisition.

Setup the iPad winch app:
1. Building and installing is not yet automated as this needs an Apple Developer Account,
being an iOS App Store app. The source code is in `./WinchApp`.
2. For the app to plot real time Z acceleration information, it needs to be
running on the same network as `ModrawVis`. The current setup naturally meets
this criteria as all the iPads are on the same network with DEV1 to receive
CTD data, and DEV3 is there to ingest the modraw files over the SMB share.

### For the development environment

You'll have a similar setup but on your own local dev box:
1. Run `ModrawServer` in the background, setup to run in simulator mode and
pointed to a local folder containing the .modraw files you want to stream.
2. Run `ModrawVis` from XCode. It will remember the last connection and attempt
to reconnect. `ModrawServer` will also restart the simulation from the beginning
of the folder each time a new connection is detected.
3. You can either select **File -> Connect to localhost**, or **File -> Connect to Local IP**,
or make sure you have `zeroconf` installed and do **File -> Connect with Bonjour** for
zero configuration magic.

The old Swift-based simulator (`sim`) has been rebranded as `ModrawSim` and is now
even easier to build and use:
1. Invoke `./ModrawSim/build.sh` to build and auto-install the app to your `/usr/local/bin` folder.
2. From this point on you can simply type `ModrawSim -i source/folder -o dest/folder`
3. This may be useful for modraw files-in-folder-based Matlab development that
expects modraw files to be streamed one full packet at a time. Otherwise `ModrawServer`
achieves the same goals with higher fidelity and configurability.
4. Note that the modraw files in the destination folder will not be identical to the
sources (unlike when running `ModrawServer`) but they will contain all the necessary data
to parse all data stream contents.

## ModrawVis

This is the hub presenting real time data to the lab operator. It is modeled after
the Matlab version with EPSI and FCTD layouts based on the Modraw header fishflag
and optimized for real time acquisition and display.

It can acquire data from multiple sources.

If a .modraw or .mat file (with the necessary FCTD/EPSI data channels present) is
opened, a static view of the entire timeline in the file is presented.

If a folder is opened, we optimally parse and display only the most recent 20
seconds of data, similar to how the Matlab visualization operates. If this folder
is being actively written to (either by the acquistion software, or the DEV1 -> DEV3
rsync script, or by one of the simulators), we read and parse in real time the
newly appended data for a continuous display.

The two key features of this app that enable it to plot the data with minimal
latency are:

- Progressive parsing of .modraw files. A file is parsed as far as data is both
available and consistent (a file may abruptly end in a partial packet) and parsing
is resumed from the last valid position as soon as more data becomes available.

- Acquiring .modraw data via a TCP socket instead of just the file system. Due
to the specific hardware architecture of the system (data acquisition and visualization
happening on different machines) and limitations in the refresh rate of SMB shares
not designed for real time data transfer, we need to have a server running on the
acquisition machine and transfering the data to the visualization box through a
socket as soon as the data becomes available.

## ModrawServer

The `ModrawServer` resolves the SMB file share performance bottleneck and naturally
integrates as a simulator in the development cycle.

It's a simple single-client TCP socket server. If the Python `zeroconf` package is
installed, if advertises itself via mDNS for easy discovery by `ModrawVis`. If
`zeroconf` is not installed, `ModrawVis` can still connect using an IP and port
combination.

The server can stream data from 2 different sources, to 2 different types of
destinations, for 4 distinct and versatile roles, or modes it can operate in.

Sources:
1. From the acquisition folder on disk, listening to file updates from the acquisition
software.
2. From a simulated folder on disk, progressively delivering data at a fixed
rate. This is used in development scenarios.

Destinations:
1. A TCP socket, piping the same modraw data contained in the files via  simple protocol.
2. A different folder from the source, actively keeping both in sync.

The 4 different roles it can play:
1. From the acquisition folder on disk to a TCP socket. This is enables
real time visualization on a different machine.
2. From the acquisition folder on disk to another folder. One of these 2 will
typically be an SMB share on a different machine. This was a proof of concept
to isolate the performance bottleneck between rsync and the SMB protocol, but
it may still be useful for backups or data synchronization.
3. From a simulated folder on disk, to a TCP socket. This mode is used
during development for fast iteration and quick restarting of simulated streams.
4. From a simulated folder on disk, to another folder. This mode is
useful for development of both `ModrawVis` but more importantly, other
Matlab-based visualization tools without the physical data acquisition
infrastructure.

## ModrawSim

This is the legacy modraw file simulator written in Swift. It has since been
superceded by the Python `ModrawServer`, but it does have the key features of
streaming whole modraw packets and attempting to reproduce the original time
flow based on packet timestamps (such as they are).

Command line parameters:
```
USAGE: sim --input-file-path <input-file-path> --output-file-path <output-file-path> [--speed <multiplier>]

OPTIONS:
  -i, --input-file-path <input-file-path>
                          Input .modraw file path, or folder to scan for
                          .modraw files.
  -o, --output-file-path <output-file-path>
                          Output .modraw file path, or folder to write to.
  -s, --speed <multiplier>
                          Time multiplier. (default: 1.0)
  -h, --help              Show help information.
```

Building and invoking:
```
./ModrawSim/build.sh
ModrawSim -i original.modraw -o simulated.modraw -s 2
ModrawSim -i ./one_folder -o ./another_folder
```

`build.sh` automatically installs `ModrawSim` to `/usr/local/bin` so it becomes
immediately available on the command line.

Output can be a single .modraw file (which is permitted only if the input is a single
.modraw file as well), or more flexibly it may be a folder. If this folder doesn't exist
it gets created. If the output folder already contains the same files about to be simulated
based on the contents of the input folder, those files are deleted, however any files with
different names already present in the output folder will be preserved. This is to both
avoid data loss while making repeated simulations painless during development.
 
 ## WinchApp

 This is the existing iPad app used at the winch to display real time CTD and winch data.

 We have added support for displaying a fixed scale graph of the last few seconds of Z
 acceleration data (A1) so the winch operator can receive real time feedback.

 This data (EPSI A1) is available in the data acquisition app running on DEV1 and having
 that app send this additional data alonside the CTD Depth information on the same UDP
 channel would have made most architectural sense. To reduce the risk of data loss by changing
 the acquisition software with no test infrastructure, we made the decision to get this
 data from the visualization app instead (`ModrawVis`). A similar UDP channel is used
 and a snapshot of the last 5 seconds is compacted in <200 bytes in each packet. This
 architectural decision will be trivial to change in the future.

 ## SiqualikScripts

 This is a collection of scripts used during the MOTIVE (Nov 2024) Cruise on the Sikuliaq.

 - `ParseAndUpload.py` - listens to ship telemetry over different UDP ports and uploads
 various data (SOG, course, heading, depth, and inferred current data and SOW) to the
 FCTD/EPSI note taking Google Sheet.
 - `WireWalkerEmails.py` - downloads positioning data that the wire walkers were reporting
 over E-mail and stores it as .csv in a different file per wire walker.
 - `download_currents.sh` - simple script to automate downloading of current information
 snapshots during c-pie deployments.