import ParserLib

# *STW (kts) speed through water [$INVBW, ]
# *SOG speed over ground (kts) [$INRMC,INVTG speed]
# *COG course over ground (deg) [$INRMC,INVTG course]
# *Heading direction ship is pointed (deg) [$INHDT,INTHS,PSXN20,PSXN23 head]
# Surface Current (kts) [$INVBW, ]
# Surface Current Heading (deg) [$INVBW, ]
# *Ocean Depth Multibeam (m)

# $INVBW,lwspeed,twspeed,Aw,lgspeed,tgspeed,Ag,stwspeed,At,stgspeed,As*csum term
# ['$INVBW', '', '', 'V', '11.05', '-0.01', 'A', '', 'V', '', 'V*4A']
invbw = ParserLib.WaitForMessage(52200, '$INVBW')
lgspeed = float(invbw[4])
tgspeed = float(invbw[5])
calc_gspeed = ParserLib.CalcSpeed(lgspeed, tgspeed)
calc_ghead = ParserLib.CalcHead(lgspeed, tgspeed)

invtg = ParserLib.WaitForMessage(52200, '$INVTG')
course = invtg[1]
gspeed = invtg[5]
print(f'  SOG: {gspeed} kts')
print(f'  COG: {course} deg')

inhdt = ParserLib.WaitForMessage(52200, '$INHDT')
head = inhdt[1]
print(f'  Heading: {head} deg')

# SOW
# ['$VDVBW', '10.06', '0.12', 'A', '', '', '*24']
vdvbw = ParserLib.WaitForMessage(53135, '$VDVBW')
lwspeed = float(vdvbw[1])
twspeed = float(vdvbw[2])
calc_wspeed = ParserLib.CalcSpeed(lwspeed, twspeed)
calc_whead = ParserLib.CalcHead(lwspeed, twspeed)

current_head = ParserLib.CalcHead(lwspeed - lgspeed, twspeed - tgspeed)
current_speed = ParserLib.CalcSpeed(lwspeed - lgspeed, twspeed - tgspeed)

print('Calculated values:')
print(f"  SOG: {calc_gspeed} kts ([{lgspeed}, {tgspeed}])")
print(f'  COG: {calc_ghead} deg ([{lgspeed}, {tgspeed}])')
print(f"  SOW: {calc_wspeed} kts ( [{lwspeed}, {twspeed}])")
print(f'  Water Heading: {calc_whead} deg ([{lwspeed}, {twspeed}])')
print(f'  Current speed: {current_speed} kts')
print(f'  Current heading: {current_head} deg')

# ek80 depth, lds\docs\format_description
# ['$EMDBS', '13085.9', 'f', '3988.57', 'M', '2180.98', 'F*1A']
emdbs = ParserLib.WaitForMessage(55005, '$EMDBS')
depth = emdbs[3]
print(f'Ocean depth: {depth} m')

# Upload

sheet = ParserLib.OpenSheet()

ssid = "1MkdbDaoq77wdhYghtDvlUaKA76W28v1E2GF8xGBV-PI"
tabName = "[TEST] Copy of D1-Mako4-Transit"
firstCol = "K"
lastCol = "Q"

rangeName = f"{tabName}!{firstCol}1:{lastCol}"
result = (
    sheet.values()
    .get(spreadsheetId=ssid, range=rangeName)
    .execute()
)
values = result.get("values", [])

nextRow = len(values) + 1
print(f"Inserting on tab '{tabName}' row {nextRow}")
rangeName = f"{tabName}!{firstCol}{nextRow}"
values = {
    "range": rangeName,
    "majorDimension": "ROWS",               
    "values": [[calc_wspeed, gspeed, course, head, current_speed, current_head, depth]]
}
result = (
    sheet.values()
    .update(spreadsheetId=ssid, range=rangeName, valueInputOption="RAW", body=values)
    .execute()
)
