import os
import math
import numpy

from NmeaOverUdpLib import wait_for_message
from GoogleApiAuthLib import get_sheets

sheet_id = "1MkdbDaoq77wdhYghtDvlUaKA76W28v1E2GF8xGBV-PI"
tab_name = "D1-FCTD2-Transit_Test"
first_col = "K"
last_col = "Q"

def calc_speed(l, t):
    return round(math.sqrt(l*l + t*t), 2)

def calc_head(l, t):
    n = math.sqrt(l*l + t*t)
    return round(numpy.arccos(numpy.clip(numpy.dot([l/n, t/n], [1, 0]), -1.0, 1.0)) * 180 / math.pi, 2)

# *STW (kts) speed through water [$INVBW, ]
# *SOG speed over ground (kts) [$INRMC,INVTG speed]
# *COG course over ground (deg) [$INRMC,INVTG course]
# *Heading direction ship is pointed (deg) [$INHDT,INTHS,PSXN20,PSXN23 head]
# Surface Current (kts) [$INVBW, ]
# Surface Current Heading (deg) [$INVBW, ]
# *Ocean Depth Multibeam (m)

# $INVBW,lwspeed,twspeed,Aw,lgspeed,tgspeed,Ag,stwspeed,At,stgspeed,As*csum term
# ['$INVBW', '', '', 'V', '11.05', '-0.01', 'A', '', 'V', '', 'V*4A']
invbw = wait_for_message(52200, '$INVBW')
if invbw:
    lgspeed = float(invbw[4])
    tgspeed = float(invbw[5])
    calc_gspeed = calc_speed(lgspeed, tgspeed)
    calc_ghead = calc_head(lgspeed, tgspeed)

invtg = wait_for_message(52200, '$INVTG')
if invtg:
    course = invtg[1]
    gspeed = invtg[5]
    print(f'  SOG: {gspeed} kts')
    print(f'  COG: {course} deg')
else:
    course = "n/a"
    gspeed = "n/a"

inhdt = wait_for_message(52200, '$INHDT')
if inhdt:
    head = inhdt[1]
    print(f'  Heading: {head} deg')
else:
    head = "n/a"

# SOW
# ['$VDVBW', '10.06', '0.12', 'A', '', '', '*24']
vdvbw = wait_for_message(53135, '$VDVBW')
if vdvbw:
    lwspeed = float(vdvbw[1])
    twspeed = float(vdvbw[2])
    calc_wspeed = calc_speed(lwspeed, twspeed)
    calc_whead = calc_head(lwspeed, twspeed)
else:
    calc_wspeed = "n/a"

if invbw and vdvbw:
    current_head = calc_head(lwspeed - lgspeed, twspeed - tgspeed)
    current_speed = calc_speed(lwspeed - lgspeed, twspeed - tgspeed)
else:
    current_head = "n/a"
    current_speed = "n/a"

# ek80 depth, lds\docs\format_description
# ['$EMDBS', '13085.9', 'f', '3988.57', 'M', '2180.98', 'F*1A']
emdbs = wait_for_message(55005, '$EMDBS')
if emdbs:
    depth = emdbs[3]
else:
    depth = "n/a"

print(f"Calculated values:")
#print(f"  SOG: {calc_gspeed} kts")
#print(f"  COG: {calc_ghead} deg")
print(f"  SOW: {calc_wspeed} kts")
#print(f"  Water Heading: {calc_whead} deg")
print(f"  Current speed: {current_speed} kts")
print(f"  Current heading: {current_head} deg")
print(f'Ocean depth: {depth} m')

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
    "values": [[calc_wspeed, gspeed, course, head, current_speed, current_head, depth]]
}
result = (
    sheets.values()
    .update(spreadsheetId=sheet_id, range=range_name, valueInputOption="RAW", body=values)
    .execute()
)
print("\033[1;32mSuccess!\033[0m")
