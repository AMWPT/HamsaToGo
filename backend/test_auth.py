import urllib.request, json

base = "http://localhost:8000"

# Test register
print("=== REGISTER ===")
data = json.dumps({"email": "testuser@hamsa.com", "password": "test1234", "full_name": "Test User"}).encode()
req = urllib.request.Request(f"{base}/auth/register", data=data, headers={"Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req) as r:
        resp = json.loads(r.read())
        print("SUCCESS:", json.dumps(resp, indent=2, default=str))
except urllib.error.HTTPError as e:
    print("ERROR:", e.code, e.read().decode())

# Test login
print("\n=== LOGIN ===")
data = json.dumps({"email": "testuser@hamsa.com", "password": "test1234"}).encode()
req = urllib.request.Request(f"{base}/auth/login", data=data, headers={"Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req) as r:
        resp = json.loads(r.read())
        print("SUCCESS:", json.dumps(resp, indent=2, default=str))
except urllib.error.HTTPError as e:
    print("ERROR:", e.code, e.read().decode())
