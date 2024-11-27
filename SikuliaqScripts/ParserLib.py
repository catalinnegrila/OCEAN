import select
import socket
import time

def WaitForMessage(port, name):
    startTime = time.time()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('', port))
    sock.setblocking(0)
    msg_timeout = 10
    message = None    
    while message == None:
        ready = select.select([sock], [], [], msg_timeout + 1)
        if ready[0]:
            message = None
            data, addr = sock.recvfrom(1024)
            for line in data.decode("utf-8").splitlines():
                x = line.replace('\n', '').split(',')
                if x[0] == name:
                    message = x
                    break
        crTime = time.time()
        if crTime - startTime > msg_timeout:
            print(f"Timeout waiting for '{name}' on UDP port {port}")
            message = ["n/a"] * 7
            break 
    sock.close()
    return message

import math
import numpy

def CalcSpeed(l, t):
    return round(math.sqrt(l*l + t*t), 2)

def CalcHead(l, t):
    n = math.sqrt(l*l + t*t)
    return round(numpy.arccos(numpy.clip(numpy.dot([l/n, t/n], [1, 0]), -1.0, 1.0)) * 180 / math.pi, 2)

import os.path
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google.auth.exceptions import RefreshError

def OpenSheet():
    # If modifying these scopes, delete the file token.json.
    scopes = ["https://www.googleapis.com/auth/spreadsheets"]

    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists("token.json"):
      creds = Credentials.from_authorized_user_file("token.json", scopes)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
      try:
        creds.refresh(Request())
        creds_refreshed = True
      except RefreshError as e:
        print("\033[1mRefresh failed. Going through the regular authentication flow.\033[0m")
        print(f"  {e}")
        creds_refreshed = False
      if not creds_refreshed:
        flow = InstalledAppFlow.from_client_secrets_file(
          "credentials.json", scopes
        )
        creds = flow.run_local_server(port=0)
      # Save the credentials for the next run
      with open("token.json", "w") as token:
        token.write(creds.to_json())

    service = build("sheets", "v4", credentials=creds)
    return service.spreadsheets()
