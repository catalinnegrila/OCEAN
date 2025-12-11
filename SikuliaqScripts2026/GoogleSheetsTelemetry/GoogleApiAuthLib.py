# https://developers.google.com/sheets/api/quickstart/python

import os.path
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google.auth.exceptions import RefreshError

def get_creds(script_dir, scopes):
    tokenJsonPath = os.path.join(script_dir, "token.json")
    credentialsJsonPath = os.path.join(script_dir, "credentials.json")
    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists(tokenJsonPath):
        creds = Credentials.from_authorized_user_file(tokenJsonPath, scopes)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except RefreshError as e:
                print("\033[1mWARNING: credential refresh failed. Going through the regular authentication flow.\033[0m")
                print(f"  {e}")
                creds = None
        if not creds:        
            if not os.path.exists(credentialsJsonPath):
                print(f"\033[1;31mERROR: {credentialsJsonPath} not found in the current folder.\033[0m")
                print("Follow these instructions to create it: https://developers.google.com/sheets/api/quickstart/python")
                exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(credentialsJsonPath, scopes)
            creds = flow.run_local_server(port=0)
        if not creds or not creds.valid:
            print("\033[1mCouldn't obtain valid credentials.\033[0m")
            exit(1)
        # Save the credentials for the next run
        with open(tokenJsonPath, "w") as token:
            token.write(creds.to_json())
    return creds

def get_sheets(script_dir):
    creds = get_creds(script_dir, ["https://www.googleapis.com/auth/spreadsheets"])
    return build("sheets", "v4", credentials=creds).spreadsheets()

def get_gmail(script_dir):
    creds = get_creds(script_dir, ['https://mail.google.com/'])
    return build("gmail", "v1", credentials=creds)
