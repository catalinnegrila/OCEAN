from NmeaOverUdpLib import WaitForMessage
from GoogleApiAuthLib import GetSheets
import math
import numpy

def CalcSpeed(l, t):
    return round(math.sqrt(l*l + t*t), 2)

def CalcHead(l, t):
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
invbw = WaitForMessage(52200, '$INVBW')
if invbw:
    lgspeed = float(invbw[4])
    tgspeed = float(invbw[5])
    calc_gspeed = CalcSpeed(lgspeed, tgspeed)
    calc_ghead = CalcHead(lgspeed, tgspeed)

invtg = WaitForMessage(52200, '$INVTG')
if invtg:
    course = invtg[1]
    gspeed = invtg[5]
    print(f'  SOG: {gspeed} kts')
    print(f'  COG: {course} deg')
else:
    course = "n/a"
    gspeed = "n/a"

inhdt = WaitForMessage(52200, '$INHDT')
if inhdt:
    head = inhdt[1]
    print(f'  Heading: {head} deg')
else:
    head = "n/a"

# SOW
# ['$VDVBW', '10.06', '0.12', 'A', '', '', '*24']
vdvbw = WaitForMessage(53135, '$VDVBW')
if vdvbw:
    lwspeed = float(vdvbw[1])
    twspeed = float(vdvbw[2])
    calc_wspeed = CalcSpeed(lwspeed, twspeed)
    calc_whead = CalcHead(lwspeed, twspeed)
else:
    calc_wspeed = "n/a"

if invbw and vdvbw:
    current_head = CalcHead(lwspeed - lgspeed, twspeed - tgspeed)
    current_speed = CalcSpeed(lwspeed - lgspeed, twspeed - tgspeed)
else:
    current_head = "n/a"
    current_speed = "n/a"

# ek80 depth, lds\docs\format_description
# ['$EMDBS', '13085.9', 'f', '3988.57', 'M', '2180.98', 'F*1A']
emdbs = WaitForMessage(55005, '$EMDBS')
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

sheets = GetSheets()
ssid = "1MkdbDaoq77wdhYghtDvlUaKA76W28v1E2GF8xGBV-PI"
tabName = "D1-FCTD2-Transit_Test"
firstCol = "K"
lastCol = "Q"

rangeName = f"{tabName}!{firstCol}1:{lastCol}"
result = (
    sheets.values()
    .get(spreadsheetId=ssid, range=rangeName)
    .execute()
)
values = result.get("values", [])

nextRow = len(values) + 1
print(f"Inserting on tab '{tabName}' row {nextRow}...")
rangeName = f"{tabName}!{firstCol}{nextRow}"
values = {
    "range": rangeName,
    "majorDimension": "ROWS",               
    "values": [[calc_wspeed, gspeed, course, head, current_speed, current_head, depth]]
}
result = (
    sheets.values()
    .update(spreadsheetId=ssid, range=rangeName, valueInputOption="RAW", body=values)
    .execute()
)
print("\033[1;32mSuccess!\033[0m")
