#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Module underway.network with functions for the local ship network.
"""

from pathlib import Path
import subprocess
import os
import requests


def connect_server(server, drive):
    """Connect to a drive on a server. Uses Apple's osascript.

    Parameters
    ----------
    server : str
        Server name or IP address
    drive : str
        Drive name

    Returns
    -------
    output : subprocess returns
    """

    command = 'mount volume "smb://{}/{}"'.format(server, drive)
    output = subprocess.run(["osascript", "-e", command], capture_output=True)
    return output


# == VESSEL SPECIFIC ==

# -> R/V SIKULIAQ
def connect_servers_sikuliaq():
    """
    Connect to drives share-data and share-sci on R/V Sikuliaq
    """
    vol = Path("/Volumes/")
    server_sci = "share-sci.sikuliaq.alaska.edu"
    server_data = "share-data.sikuliaq.alaska.edu"
    servers = [server_sci, server_data]
    drives = ["sci", "data"]
    drives_local = [vol.joinpath(si) for si in drives]

    # see if drives are connected already
    volg = list(vol.glob("*"))
    conn = {}
    serv = {}
    for si, server in zip(drives, servers):
        sil = vol.joinpath(si)
        conn[si] = False if sil in volg else True
        serv[si] = server

    for k, v in conn.items():
        if v:
            print("connecting to {}...".format(k))
            out = connect_server(serv[k], k)
            if out.returncode == 0:
                print("connected")
            else:
                print(out.stdout.decode("utf-8"))
                print(out.stderr.decode("utf-8"))

# -> R/V REVELLE
def connect_servers_revelle():
    """
    Connect to drives cruise and science_party_share on R/V Revelle
    """
    vol = Path("/Volumes/")
    server = "rr-sci-filesvr.ucsd.edu"
    drives = ["cruise", "science_party_share"]
    drives_local = [vol.joinpath(si) for si in drives]
    # see if drives are connected already
    volg = list(vol.glob("*"))
    conn = {}
    for si in drives:
        sil = vol.joinpath(si)
        conn[si] = False if sil in volg else True

    for k, v in conn.items():
        if v:
            print("connecting to {}...".format(k))
            out = connect_server(server, k)
            if out.returncode == 0:
                print("connected")
            else:
                print(out.stdout.decode("utf-8"))
                print(out.stderr.decode("utf-8"))


# -> R/V ARMSTRONG
def connect_servers_armstrong():
    """
    Connect to drives data_on_memory and science_share on R/V Armstrong
    """
    vol = Path("/Volumes/")
    server = "10.100.100.30"
    drives = ["data_on_memory", "science_share"]
    drives_local = [vol.joinpath(si) for si in drives]
    # see if drives are connected already
    volg = list(vol.glob("*"))
    conn = {}
    for si in drives:
        sil = vol.joinpath(si)
        conn[si] = False if sil in volg else True

    for k, v in conn.items():
        if v:
            print("connecting to {}...".format(k))
            out = connect_server(server, k)
            if out.returncode == 0:
                print("connected")
            else:
                print(out.stdout.decode("utf-8"))
                print(out.stderr.decode("utf-8"))


def get_position_armstrong():
    r = requests.get("http://www.armstrong.whoi.edu/cgi-bin/sssg_gps.pl")
    posdict = dict(lon="Longitude", lat="Latitude")
    pos = dict()
    for k, v in posdict.items():
        lati = r.text.find(v)
        latiend = r.text[lati:].find("</br>")
        latstr = (
            r.text[lati + 10 : lati + latiend]
            .replace(" &#176 ", " ")
            .strip()
            .replace("  ", " ")
            .split(" ")
        )
        dec = float(latstr[0]) + float(latstr[1]) / 60
        dec = -1 * dec if latstr[2] == "W" or latstr[2] == "S" else dec
        pos[k] = dec
    return pos


# -> RRS Discovery
def connect_servers_discovery():
    """
    Connect to drives data_on_memory and science_share on RRS Discovery
    """
    vol = Path("/Volumes/")
    server = "10.100.100.30"
    server = "dynas1.discovery.local"
    drives = ["Public", "current_cruise"]
    drives_local = [vol.joinpath(si) for si in drives]
    # see if drives are connected already
    volg = list(vol.glob("*"))
    conn = {}
    for si in drives:
        sil = vol.joinpath(si)
        conn[si] = False if sil in volg else True

    for k, v in conn.items():
        if v:
            print("connecting to {}...".format(k))
            out = connect_server(server, k)
            if out.returncode == 0:
                print("connected")
            else:
                print(out.stdout.decode("utf-8"))
                print(out.stderr.decode("utf-8"))
