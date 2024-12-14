# Based on: https://thepythoncode.com/article/use-gmail-api-in-python
# pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib
# mount | grep smbfs

import os
import sys
import pickle
# Gmail API utils
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.auth.exceptions import RefreshError
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

class HTMLFilter(HTMLParser):
    text = ""
    def handle_data(self, data):
        self.text += data
    def handle_starttag(self, tag, attrs):
        if tag == 'td':
            self.text += '\t'
        elif tag == 'tr':
            self.text += '\r\n'

def html_to_text(data):
    f = HTMLFilter()
    f.feed(data)
    return f.text

# Request all access (permission to read/send/receive emails, manage the inbox, and more)
SCOPES = ['https://mail.google.com/']
our_email = 'xeos.motive.2024@gmail.com'
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
    try:
      creds.refresh(Request())
      creds_refreshed = True
    except RefreshError as e:
      print("\033[1mRefresh failed. Going through the regular authentication flow.\033[0m")
      print(f"  {e}")
      creds_refreshed = False
    if not creds_refreshed:
      credentials_json_path = os.path.join(script_dir, "credentials.json")
      flow = InstalledAppFlow.from_client_secrets_file(credentials_json_path, SCOPES)
      creds = flow.run_local_server(port=0)
    # save the credentials for the next run
    with open(token_pickle_path, "wb") as token:
      pickle.dump(creds, token)
  return build('gmail', 'v1', credentials=creds)

# get the Gmail API service
service = gmail_authenticate()

def search_messages(service, query):
    result = service.users().messages().list(userId='me',q=query).execute()
    messages = [ ]
    if 'messages' in result:
        messages.extend(result['messages'])
    while 'nextPageToken' in result:
        page_token = result['nextPageToken']
        result = service.users().messages().list(userId='me',q=query, pageToken=page_token).execute()
        if 'messages' in result:
            messages.extend(result['messages'])
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
                #if data:
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
                            attachment = service.users().messages() \
                                        .attachments().get(id=attachment_id, userId='me', messageId=message['id']).execute()
                            data = attachment.get("data")
                            #if data:
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
    msg = service.users().messages().get(userId='me', id=message['id'], format='full').execute()
    # parts can be the message body, or attachments
    payload = msg['payload']
    headers = payload.get("headers")
    parts = payload.get("parts")
    has_subject = False
    return parse_parts(service, parts, message)

def mark_as_read(service, query):
    messages_to_mark = search_messages(service, query)
    print(f"Matched emails: {len(messages_to_mark)}")
    return service.users().messages().batchModify(
      userId='me',
      body={
          'ids': [ msg['id'] for msg in messages_to_mark ],
          'removeLabelIds': ['UNREAD']
      }
    ).execute()


reported_gps_signature = "Reported GPS Positions" 
query = f"\"{reported_gps_signature}\""
if len(sys.argv) > 1:
    query += f" {sys.argv[1]}"

print(f"\033[1mEmail query: '{query}'\033[0m")
invalid_rover_id = "<parse_error_check_format>"
results = search_messages(service, query)

data = {}
i = 1
for msg in results:
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
            timestamp = line.split("\t")[1]
        elif line.startswith("Latitude\t"):
            lat = line.split("\t")[1]
        elif line.startswith("Longitude\t"):
            lon = line.split("\t")[1]
        elif line == "Key\tValue":
            rover_id = prev_line
        elif line == reported_gps_signature:
            if rover_id == invalid_rover_id:
                print(text)
            if not rover_id in data:
                data[rover_id] = list()
            csv_entry = f"{timestamp},{lat},{lon},\"{rover_id}\""
            print(f"[{i}/{len(results)}]: {csv_entry}")
            data[rover_id].append(f"{csv_entry}\n")
            break
        prev_line = line
    i += 1

if len(data) == 0:
    print("\033[1;31mNo Emails found matching your query.\033[0m")
    exit()

print("Writing data into separate files by rover id:")
for _, (key, value) in enumerate(data.items()):
    csv_path = os.path.join(script_dir, f"{key}.csv")
    if os.path.exists(csv_path):
        prefix = "Overwriting"
        os.remove(csv_path)
    else:
        prefix = "Creating"
    print(f"  {prefix} {csv_path}, {len(value)} line(s)")
    with open(csv_path, 'x') as f:
        f.write("  Timestamp,Lat,Lon,\"Rover Id\"\n")
        for entry in sorted(value):
            f.write(entry)
