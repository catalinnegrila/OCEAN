import os
from datetime import datetime, timezone

import pandas as pd
import xarray as xr
import numpy as np

from GoogleApiAuthLib import get_gmail
from GmailUtils import search_messages, read_message

our_email = "xeos.motive.2024@gmail.com"
reported_gps_signature = "Reported GPS Positions"
script_dir = os.path.dirname(os.path.abspath(__file__))

def parse_location_from_Email(text):
    packet = {}
    packet['time'] = "n/a"
    packet['lat'] = "n/a"
    packet['lon'] = "n/a"
    packet['rover_id'] = "n/a"
    prev_line = ""
    for line in text.splitlines():
        line = line.lstrip("> \t")
        if not line:
            continue
        if line.startswith("Timestamp\t"):
            t = line.split("\t")[1]
            #t = t.replace("Z", "")
            #t = np.datetime64(t)
            #t = pd.DatetimeIndex([t])[0]
            packet['time'] = t
        elif line.startswith("Latitude\t"):
            packet['lat'] = float(line.split("\t")[1])
        elif line.startswith("Longitude\t"):
            packet['lon'] = float(line.split("\t")[1])
        elif line == "Key\tValue":
            packet['rover_id'] = prev_line
        elif line == reported_gps_signature:
            return packet
        prev_line = line
    return {}


def get_all_locations():
    all_emails_path = os.path.join(script_dir, "all_emails.csv")
    return pd.read_csv(all_emails_path, parse_dates=False)


    print(f"Querying '{our_email}'...")
    service = get_gmail(script_dir)
    results = search_messages(service, reported_gps_signature)

    all_emails_path = os.path.join(script_dir, "all_emails.csv")
    try:
        all_emails = pd.read_csv(all_emails_path, parse_dates=False)
        if len(all_emails) == 0:
            raise Exception("Empty file.")

        filtered_results = []
        for msg in results:
            if msg["id"] not in all_emails["id"].values:
                filtered_results.append(msg)

        if len(filtered_results) == 0:
            print(f"No new E-mails to download.")
        else:
            print(f"Downloading {len(filtered_results)} of {len(results)} new E-mails.")

        results = filtered_results
    except:
        print(f"First run, downloading all {len(results)} E-mails.")
        with open(all_emails_path, 'x') as f:
            f.write("id,time,lat,lon,rover_id\n")

    msgIndex = 1
    try:
        for msg in results:
            text = read_message(service, msg)
            packet = parse_location_from_Email(text)
            if len(packet) > 0:
                print(f"[{msgIndex}/{len(results)}]: {packet['time']} {packet['rover_id']}")
                with open(all_emails_path, 'a') as f:
                    f.write(f"{msg['id']},{packet['time']},{packet['lat']},{packet['lon']},{packet['rover_id']}\n")
            else:
                print(f"[{msgIndex}/{len(results)}]: no location data")
            msgIndex += 1
    except KeyboardInterrupt:
        print(f"Only {msgIndex-1} of {len(results)} locations downloaded. Re-run the script to get the rest.")

    return pd.read_csv(all_emails_path, parse_dates=False)


names_mapped = {
    "ECOHAB 3": "WW1",
    "Sunrise 3": "WW2",
    "1431 300434068514310": "WW3",
    "ECOHAB 23-3": "WW4",
    "1073": "WW1",
    "1095": "WW2",
    "1431": "WW3",
}

def df_to_ds(df):
    wws = dict()
    for i, (name, mapped_name) in enumerate(names_mapped.items()):
        filtered_df = df[df["rover_id"] == name]
        ds = filtered_df.to_xarray()
        ds.attrs["name"] = mapped_name
        ds = ds.set_coords("time")
        ds = ds.swap_dims(index="time")
        ds = ds.sortby("time")
        if mapped_name not in wws.keys():
            wws[mapped_name] = ds
        else:
            wws[mapped_name] = xr.concat([wws[mapped_name], ds], "time")
    return wws


def save_netcdf(wws):
    for name, wwi in wws.items():
        wwi.to_netcdf(os.path.join(script_dir, f"{wwi.name}_locations.nc"))


def lon_str(lon):
    if lon > 180:
        lon = lon - 360
    EW = "W" if lon < 0 else "E"
    lon_degrees = np.trunc(lon)
    lon_minutes = np.abs(lon - lon_degrees) * 60
    return f"{int(np.abs(lon_degrees)):3d}° {lon_minutes:6.3f}' {EW}"


def lat_str(lat):
    NS = "N" if lat > 0 else "S"
    lat_degrees = np.trunc(lat)
    lat_minutes = np.abs(lat - lat_degrees) * 60
    return f"{int(np.abs(lat_degrees)):3d}° {lat_minutes:6.3f}' {NS}"


def current_loc_to_ascii(wws):
    file_name = os.path.join(script_dir, "current_locations.txt")
    with open(file_name, "w") as file:
        now_utc = datetime.now(timezone.utc)
        formatted_time = now_utc.strftime("%Y-%m-%dT%H:%M:%S")
        file.write(f"Locations as of {formatted_time} UTC:\n")
        file.write("\n")
        for i, (name, ds) in enumerate(wws.items()):
            p = ds.isel(time=-1)
            file.write(f"{p.name} {p.time.data} UTC, ")
            file.write(f"{lon_str(p.lon)}, {lat_str(p.lat)}\n")


if __name__ == "__main__":
    df = get_all_locations()

    if len(df) == 0:
        print("No locations found to process.")
        exit(1)

    wws = df_to_ds(df)
    save_netcdf(wws)
    current_loc_to_ascii(wws)
