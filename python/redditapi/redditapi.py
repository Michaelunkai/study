CLIENT_ID = 't7CCtuZqJrrYWshOGSng5A'
SECRET_KEY = 'bMT5TZJko1dVT0k5f4gqgO9Lhs3UCA'
import requests
auth = requests.auth.HTTPBasicAuth(CLIENT_ID, SECRET_KEY)
with open('pw.txt', 'r') as f:
    pw = f.read().strip()
data = {
    'grant_type': 'password',
    'username': 'michaelovsky5',
    'password': pw
}
headers = {'User-Agent': 'MyAPI/0.0.1'}
res = requests.post('https://www.reddit.com/api/v1/access_token',
                    auth=auth, data=data, headers=headers)
res.json()