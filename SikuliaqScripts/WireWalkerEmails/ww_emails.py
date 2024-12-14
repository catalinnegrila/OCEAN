# https://thepythoncode.com/article/use-gmail-api-in-python

import os
import pickle
from pathlib import Path
import shutil

# Gmail API utils
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# for encoding/decoding messages in base64
from base64 import urlsafe_b64decode, urlsafe_b64encode

# for dealing with attachement MIME types
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from email.mime.audio import MIMEAudio
from email.mime.base import MIMEBase
from mimetypes import guess_type as guess_mime_type
from html.parser import HTMLParser

import pandas as pd
import xarray as xr
import numpy as np

import gvpy as gv

#import motive


class HTMLFilter(HTMLParser):
    text = ""

    def handle_data(self, data):
        self.text += data

    def handle_starttag(self, tag, attrs):
        if tag == "td":
            self.text += "\t"
        elif tag == "tr":
            self.text += "\r\n"


def html_to_text(data):
    f = HTMLFilter()
    f.feed(data)
    return f.text


# Request all access (permission to read/send/receive emails, manage the inbox, and more)
SCOPES = ["https://mail.google.com/"]
our_email = "xeos.motive.2024@gmail.com"
script_dir = os.path.dirname(os.path.abspath(__file__))


def gmail_authenticate():
    creds = None
    # the file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first time
    token_pickle_path = os.path.join(script_dir, "token.pickle")
    if os.path.exists(token_pickle_path):
        with open(token_pickle_path, "rb") as token:
            creds = pickle.load(token)
    # if there are no (valid) credentials availablle, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            credentials_json_path = os.path.join(script_dir, "credentials.json")
            flow = InstalledAppFlow.from_client_secrets_file(
                credentials_json_path, SCOPES
            )
            creds = flow.run_local_server(port=0)
        # save the credentials for the next run
        with open(token_pickle_path, "wb") as token:
            pickle.dump(creds, token)
    return build("gmail", "v1", credentials=creds)


# get the Gmail API service
service = gmail_authenticate()


def search_messages(service, query):
    result = service.users().messages().list(userId="me", q=query).execute()
    messages = []
    if "messages" in result:
        messages.extend(result["messages"])
    while "nextPageToken" in result:
        page_token = result["nextPageToken"]
        result = (
            service.users()
            .messages()
            .list(userId="me", q=query, pageToken=page_token)
            .execute()
        )
        if "messages" in result:
            messages.extend(result["messages"])
    return messages


# utility functions
def get_size_format(b, factor=1024, suffix="B"):
    """
    Scale bytes to its proper byte format
    e.g:
        1253656 => '1.20MB'
        1253656678 => '1.17GB'
    """
    for unit in ["", "K", "M", "G", "T", "P", "E", "Z"]:
        if b < factor:
            return f"{b:.2f}{unit}{suffix}"
        b /= factor
    return f"{b:.2f}Y{suffix}"


def clean(text):
    # clean text for creating a folder
    return "".join(c if c.isalnum() else "_" for c in text)


def parse_parts(service, parts, message):
    """
    Utility function that parses the content of an email partition
    """
    content = ""
    if parts:
        for part in parts:
            filename = part.get("filename")
            mimeType = part.get("mimeType")
            body = part.get("body")
            data = body.get("data")
            file_size = body.get("size")
            part_headers = part.get("headers")
            if part.get("parts"):
                # recursively call this function when we see that a part
                # has parts inside
                content += parse_parts(service, part.get("parts"), message)
            if mimeType == "text/plain":
                # if the email part is text plain
                pass
                # if data:
                #    content += urlsafe_b64decode(data).decode()
            elif mimeType == "text/html":
                content += html_to_text(urlsafe_b64decode(data).decode("utf-8"))
            else:
                # attachment other than a plain text or HTML
                for part_header in part_headers:
                    part_header_name = part_header.get("name")
                    part_header_value = part_header.get("value")
                    if part_header_name == "Content-Disposition":
                        if "attachment" in part_header_value:
                            # we get the attachment ID
                            # and make another request to get the attachment itself
                            attachment_id = body.get("attachmentId")
                            attachment = (
                                service.users()
                                .messages()
                                .attachments()
                                .get(
                                    id=attachment_id,
                                    userId="me",
                                    messageId=message["id"],
                                )
                                .execute()
                            )
                            data = attachment.get("data")
                            # if data:
                            #    content += urlsafe_b64decode(data)
    return content


def read_message(service, message):
    """
    This function takes Gmail API `service` and the given `message_id` and does the following:
        - Downloads the content of the email
        - Prints email basic information (To, From, Subject & Date) and plain/text parts
        - Creates a folder for each email based on the subject
        - Downloads text/html content (if available) and saves it under the folder created as index.html
        - Downloads any file that is attached to the email and saves it in the folder created
    """
    msg = (
        service.users()
        .messages()
        .get(userId="me", id=message["id"], format="full")
        .execute()
    )
    # parts can be the message body, or attachments
    payload = msg["payload"]
    headers = payload.get("headers")
    parts = payload.get("parts")
    has_subject = False
    return parse_parts(service, parts, message)


def mark_as_read(service, query):
    messages_to_mark = search_messages(service, query)
    print(f"Matched emails: {len(messages_to_mark)}")
    return (
        service.users()
        .messages()
        .batchModify(
            userId="me",
            body={
                "ids": [msg["id"] for msg in messages_to_mark],
                "removeLabelIds": ["UNREAD"],
            },
        )
        .execute()
    )


def update_emails():
    print("updating ww emails...")
    all_emails = pd.read_csv("all_emails.csv", parse_dates=True)
    reported_gps_signature = "Reported GPS Positions"
    invalid_rover_id = "<parse_error_check_format>"
    results = search_messages(service, reported_gps_signature)

    data = []
    i = 1
    for msg in results:
        if msg["id"] not in all_emails["id"].values:
            packet = dict()
            packet["id"] = msg["id"]
            packet["threadId"] = msg["threadId"]
            text = read_message(service, msg)
            timestamp = "n/a"
            lat = "n/a"
            lon = "n/a"
            rover_id = invalid_rover_id
            prev_line = ""
            for line in text.splitlines():
                line = line.lstrip("> \t")
                if not line:
                    continue
                if line.startswith("Timestamp\t"):
                    packet["timestamp"] = np.datetime64(
                        line.split("\t")[1].replace("Z", "")
                    )
                    print(packet["timestamp"])
                elif line.startswith("Latitude\t"):
                    packet["lat"] = float(line.split("\t")[1])
                elif line.startswith("Longitude\t"):
                    packet["lon"] = float(line.split("\t")[1])
                elif line == "Key\tValue":
                    packet["rover_id"] = prev_line
                elif line == reported_gps_signature:
                    # if rover_id == invalid_rover_id:
                    # print(text)
                    # if not rover_id in data:
                    # data[rover_id] = list()
                    # csv_entry = f"{timestamp},{lat},{lon},\"{rover_id}\""
                    # print(f"[{i}/{len(results)}]: {csv_entry}")
                    print(
                        f"[{i}/{len(results)}]: {packet['timestamp']} {packet['rover_id']}"
                    )
                    data.append(packet)
                    break
                prev_line = line
            i += 1

    new_df = pd.DataFrame(data)

    df = pd.concat([all_emails, new_df])
    df["timestamp"] = pd.DatetimeIndex(df.timestamp)

    df.to_csv("all_emails.csv", index=False)

    return df


def df_to_ds(df):
    names = ["ECOHAB 3", "ECOHAB 23-3", "1431 300434068514310", "Sunrise 3", "1073", "1095", "1431"]
    names_mapped = {
        "ECOHAB 3": "WW1",
        "Sunrise 3": "WW2",
        "1431 300434068514310": "WW3",
        "ECOHAB 23-3": "WW4",
        "1073": "WW1",
        "1095": "WW2",
        "1431": "WW3",
    }

    wws = dict()
    for name in names:
        filtered_df = df[df["rover_id"] == name]
        ds = filtered_df.to_xarray()
        ds = ds.where(ds.lat < 3)
        ds.attrs["name"] = names_mapped[name]
        ds = ds.rename_vars(dict(timestamp="time"))
        ds = ds.set_coords("time")
        ds = ds.swap_dims(index="time")
        ds = ds.where(~np.isnat(ds.time), drop=True)
        ds = ds.sortby("time")
        if names_mapped[name] not in wws.keys():
            wws[names_mapped[name]] = ds
        else:
            wws[names_mapped[name]] = xr.concat([wws[names_mapped[name]], ds], "time")
    return wws


def save_netcdf(wws):
    for name, wwi in wws.items():
        wwi.to_netcdf(f"motive_ww_positions_{wwi.name}.nc")


def copy_nc_to_server():
    sci = Path("/Volumes/sci/shipside/SKQ202417S/")
    ww_dir = sci.joinpath("WireWalkerEmails/nc/")
    files = sorted(Path.cwd().glob("motive*.nc"))
    for file in files:
        shutil.copy(file, ww_dir.joinpath(file.name))


def copy_file_to_server(file):
    sci = Path("/Volumes/sci/shipside/SKQ202417S/")
    ww_dir = sci.joinpath("WireWalkerEmails/")
    shutil.copy(file, ww_dir.joinpath(file.name))


def current_loc_to_ascii(wws, file_name):
    with open(file_name, "w") as file:
        file.write(
            f"WireWalker locations as of {gv.time.datetime64_to_str(gv.time.now_utc(), 's')} UTC\n",
        )
        file.write("\n")
        for name in [
            "WW1",
            "WW2",
            "WW3",
        ]:
            ds = wws[name]
            p = ds.isel(time=-1)
            file.write(f"{p.name} {gv.time.datetime64_to_str(p.time.data, 's')} UTC\n")
            file.write(
                f"{gv.ocean.lonlatstr(p.lon, p.lat)[1]} , {gv.ocean.lonlatstr(p.lon, p.lat)[0]}\n"
            )
            file.write("\n")


if __name__ == "__main__":
    #S = motive.cruise.skq202417s()
    #S.connect()
    df = update_emails()
    wws = df_to_ds(df)
    save_netcdf(wws)
    copy_nc_to_server()
    current_loc_to_ascii(wws, "ww_current_locs.txt")
    copy_file_to_server(Path("ww_current_locs.txt"))
