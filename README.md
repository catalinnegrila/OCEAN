# OCEAN

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

The ModrawServer resolves the SMB file share performance bottleneck and naturally
integrates as a simulator in the development cycle.

It's a simple single-client TCP socket server. If the Python `zeroconf` package is
installed, if advertises itself via mDNS for easy discovery by ModrawVis. If
`zeroconf` is not installed, ModrawVis can still connect using an IP and port
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
useful for development of both ModrawVis but more importantly, other
Matlab-based visualization tools without the physical data acquisition
infrastructure.

## ModrawSim

This is the legacy modraw file simulator written in Swift. It has since been
superceded by the Python ModrawServer, but it does have the key features of
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

`build.sh` automatically installs ModrawSim to `/usr/local/bin` so it becomes
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
 data from the visualization app instead (ModrawVis). A similar UDP channel is used
 and a snapshot of the last 5 seconds is compacted in <200 bytes in each packet. This
 architectural decision will be trivial to change in the future.

 ## SiqualikScripts

 This is a collection of scripts used during the MOTIVE (Nov 2024) Cruise on the Sikuliaq.

 - ParseAndUpload.py - listens to ship telemetry over different UDP ports and uploads
 various data (SOG, course, heading, depth, and inferred current data and SOW) to the
 FCTD/EPSI note taking Google Sheet.
 - WireWalkerEmails.py - downloads positioning data that the wire walkers were reporting
 over E-mail and stores it as .csv in a different file per wire walker.
 - download_currents.sh - simple script to automate downloading of current information
 snapshots during c-pie deployments.