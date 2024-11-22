********************* PURPOSE:
- Acquire CTD and PCode's data via serial ports.
- Communicate with Winch via net work: TCP/IP port
	¥ Get the Red Lion string: status of the fish 
      	¥ Send Winch's data: cond, temp and depth.
- Has option to send data UDP broadcast.
- Also has option sending data via serial port.

********************* USAGE:

SETUP FILE:
1. The setup file must be at the working directory:
   - In Xcode: "Setup" file is at the same location with executed file. In other word, it is at ".../build/Deployment"
   - If you run FastCTD app by dragging it in terminal, you must copy "Setup" file from ".../build/Deployment" to the current your working directory.

2. Setup file format:
   - '%' for comment, use '%' if not apply.
   - Acquire CTD and PCode via serial port.
   - "CTD.CTDPortName=USA49W1811P1.1": serial port name for CTD.
     (Serial port name can be found by using zterm or system: use termial, type "ls /dev", you will see there are the list of serial ports name, i.e: cu.USA49W1811P1.1 or tty.USA49W1811P1.1, but only use "USA49W1811P1.1")
   - "dropnumBaseonWinch=1": 1 (base on winch's data)
			     0 (base on the fish's data: pressure)
   - "RecHeader.totalDrops=4": the file cotains 4 drops.
   - "fpData[0].dataFileSize=50000": size of the data file, if size is 0, 

HOW TO RUN:
1. Check all options in "Setup" file to meet your deployment.
2. Run application.
3. Data will save in the path as provided in setup file.
   Setup file will save in the same folder with executable file. (build/Deployment/) with the format: "Setupyyyymmddhhmm"s