#!/usr/bin/env -S uv run --script

import os
import math
import numpy

from NmeaOverUdpLib import wait_for_message
from GoogleApiAuthLib import get_sheets

sheet_id = "1r7ZQxEzOoz-FcUGdX939tG2JYMbvWgcxdEOTB1H6KHE"
tab_name = "d01_FCTD1_Test"
first_col = "P"
last_col = "V"

def calc_speed(l, t):
    return round(math.sqrt(l*l + t*t), 2)

def calc_head(l, t):
    n = math.sqrt(l*l + t*t)
    return round(numpy.arccos(numpy.clip(numpy.dot([l/n, t/n], [1, 0]), -1.0, 1.0)) * 180 / math.pi, 2)

# *STW (kts) speed through water [$VDVBW] 53135
# *SOG speed over ground (kts) [$GPVTG] 52119
# *COG course over ground (deg) [$GPVTG] 52119
# *Heading direction ship is pointed (deg) [$GPHDT 52119,PSXN20,PSXN23 head]
# Surface Current (kts)
# Surface Current Heading (deg)
# *Ocean Depth Multibeam (m) [$EMDBS] 55005
# 53135: adcp_speedlog   ADCP Speedlog

# $GPVTG,140.88,T,,M,8.04,N,14.89,K,D*05
# 0 Message ID $GPVTG
# 1 Track made good (degrees true)
# 2 T: track made good is relative to true north
# 3 Track made good (degrees magnetic)
# 4 M: track made good is relative to magnetic north
# 5 Speed, in knots
# 6 N: speed is measured in knots
# ins_seapath_position  SeaPath Nav 52119, 53119
gpvtg = wait_for_message(52119, '$GPVTG')
if gpvtg:
    gcourse = float(gpvtg[1])
    gspeed = float(gpvtg[5])
    print(f'  COG: {gcourse} deg')
    print(f'  SOG: {gspeed} kts')
else:
    course = "n/a"
    gspeed = "n/a"

# STW
# 53135: adcp_speedlog   ADCP Speedlog
# ['$VDVBW', '10.06', '0.12', 'A', '', '', '*24']
vdvbw = wait_for_message(53135, '$VDVBW')
if vdvbw:
    lwspeed = float(vdvbw[1])
    twspeed = float(vdvbw[2])
    calc_wspeed = calc_speed(lwspeed, twspeed)
    calc_whead = calc_head(lwspeed, twspeed)
else:
    calc_wspeed = "n/a"
    calc_whead = "n/a"
print(f"  STW: {calc_wspeed} kts")
print(f"  Current heading: {calc_whead} deg")

# $GPHDT,123.456,T*00
# 0 Message ID $GPHDT
# 1 Heading in degrees
# 2 T: Indicates heading relative to True North
# ins_seapath_position  SeaPath Nav 52119, 53119
gphdt = wait_for_message(52119, '$GPHDT')
if gphdt:
    ghead = gphdt[1]
else:
    ghead = "n/a"
print(f'  Heading: {ghead} deg')

# 55005: mb_em304_centerbeam EM304 Centerbeam Depth
# ek80 depth, lds\docs\format_description
# ['$EMDBS', '13085.9', 'f', '3988.57', 'M', '2180.98', 'F*1A']
emdbs = wait_for_message(55005, '$EMDBS')
if emdbs:
    depth = emdbs[3]
else:
    depth = "n/a"
print(f'  Ocean depth: {depth} m')

if vdvbw and gpvtg:
    current_head = calc_head(lwspeed - gspeed, twspeed)
    current_speed = calc_speed(lwspeed - gspeed, twspeed)
else:
    current_head = "n/a"
    current_speed = "n/a"

print(f"Calculated values:")
print(f"  Current speed: {current_speed} kts")
print(f"  Current heading: {current_head} deg")

# Upload
script_dir = os.path.dirname(os.path.abspath(__file__))
sheets = get_sheets(script_dir)

range_name = f"{tab_name}!{first_col}1:{last_col}"
result = (
    sheets.values()
    .get(spreadsheetId=sheet_id, range=range_name)
    .execute()
)
values = result.get("values", [])

next_row = len(values) + 1
print(f"Inserting on tab '{tab_name}' row {next_row}...")
range_name = f"{tab_name}!{first_col}{next_row}"
values = {
    "range": range_name,
    "majorDimension": "ROWS",               
    "values": [[calc_wspeed, gspeed, gcourse, ghead, current_speed, current_head, depth]]
}
result = (
    sheets.values()
    .update(spreadsheetId=sheet_id, range=range_name, valueInputOption="RAW", body=values)
    .execute()
)
print("\033[1;32mSuccess!\033[0m")
