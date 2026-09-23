# Google OAuth setup for the check-in Web App

The student check-in page is rendered inside an Apps Script HTML Service iframe.
Its generated `script.googleusercontent.com` sandbox host cannot be registered
reliably as an OAuth JavaScript origin. The Apps Script UI therefore uses Google
Identity Services **redirect mode**, not popup mode.

## OAuth web client

- Client ID: `222111384223-rk24tqqmdp7bof592plvogk5u2ng2ci0.apps.googleusercontent.com`
- Application type: **Web application**
- Authorized redirect URI:
  `https://script.google.com/macros/s/AKfycbwhbrv6Y76dGETuwDeMqObH1Dvf9RwQ5obDkxuuR-x5m2T3JoCByY0EuuB4ptuTHC3cwA/exec`

Open Google Cloud Console, select the project that owns the client ID, then go
to **Google Auth Platform > Clients**, open this Web client, add the complete URL
above under **Authorized redirect URIs**, and save. It must match exactly,
including the `/exec` path and without a query string or trailing slash.

If the standalone Flutter web application is also used locally, add its exact
development origin under **Authorized JavaScript origins**, for example
`http://localhost:7357`. Production static hosts must likewise be listed as
their own HTTPS origins.

After changing an OAuth client, allow several minutes for the setting to
propagate, open a fresh incognito window, and test with a newly generated QR.
