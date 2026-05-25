# Launcher Daemon API

The daemon listens on a Unix domain socket (local only, no network exposure).  
Default path: `$XDG_RUNTIME_DIR/app-launcher/socket` (typically `/run/user/1000/app-launcher/socket`).

All messages are JSON. Send a request, receive a response. One request per connection is fine; the server also supports streaming multiple requests on a single connection.

---

## Protocol

**Request format:**

```json
{
  "id": "<any string, echoed back>",
  "method": "<method name>",
  "params": { ... }
}
```

**Response format:**

```json
{
  "id": "<same id>",
  "result": { ... },
  "error": null
}
```

On error, `result` is null and `error` has `code` and `message`.

---

## Methods

### 1. `query` — Search / calculate / run command / switch windows

The central method. The daemon inspects the query prefix and routes automatically:

| Query prefix | Routed to | Result type |
|---|---|---|
| `=...` | Calculator | `"calc"` |
| `>...` | Shell command | `"shell"` |
| contains `.` or `/` | Hyprland window switcher | `"windows"` |
| anything else | App search | `"apps"` |

**Params:**

```json
{
  "query": "=2+2",
  "limit": 20
}
```

`limit` is optional (default 20) and only applies to app search.

**Responses by type:**

#### `"apps"` — Application search

```json
{
  "type": "apps",
  "apps": [
    {
      "entry": {
        "id": "abc12345",
        "name": "Chromium",
        "generic_name": "Web Browser",
        "exec": "/usr/bin/chromium %U",
        "icon": "chromium",
        "categories": ["Network", "WebBrowser"],
        "keywords": ["browser", "internet", "chrome"],
        "path": "/usr/share/applications/chromium.desktop"
      },
      "score": 1.52,
      "weight": 1.0
    }
  ]
}
```

- `weight`: field match quality — 1.0 (Name), 0.8 (Keywords), 0.6 (Categories), 0.4 (Exec)
- `score`: final ranking = `weight * (1 + frecency)`. Higher = more relevant.
- Results are sorted by score descending.

#### `"calc"` — Calculator result

```json
{
  "type": "calc",
  "calc": {
    "expression": "2+2",
    "value": 4.0,
    "formatted": "4"
  }
}
```

Supports: `+`, `-`, `*`, `/`, `%`, `^` (power), parentheses, floats, hex (`0xFF`), `pi`, `e`.

#### `"shell"` — Shell command result

```json
{
  "type": "shell",
  "shell": {
    "command": "echo hello",
    "output": "hello",
    "exit_code": 0
  }
}
```

- Output is capped at 2000 chars.
- Commands time out after 5s by default (configurable).
- `exit_code` is 0 for success, non-zero for failure, -1 for timeout.

#### `"windows"` — Hyprland window list

```json
{
  "type": "windows",
  "windows": {
    "windows": [
      {
        "address": "0x555a1c4e3b80",
        "class": "kitty",
        "title": "~/projects — kitty",
        "workspace_id": 1
      }
    ],
    "match": "kitty"
  }
}
```

- Matched by substring on `class + title`.
- Sorted by workspace, then class name.
- Only works when Hyprland is the compositor and `HYPRLAND_INSTANCE_SIGNATURE` is set.

---

### 2. `launch` — Launch an application

Records the launch for frecency tracking and spawns the process detached.

**Params:**

```json
{
  "entry_id": "abc12345",
  "exec": "chromium"
}
```

- `entry_id`: the app's `id` from a previous `query` response (for tracking)
- `exec`: shell command to run (can contain `%U` style args or be a plain binary name)

**Response:**

```json
{ "ok": true }
```

---

### 3. `focus_window` — Switch to a Hyprland window

**Params:**

```json
{
  "address": "0x555a1c4e3b80"
}
```

**Response:**

```json
{ "ok": true }
```

---

### 4. `ping` — Health check

**Params:** none

```json
{}
```

**Response:**

```json
"pong"
```

---

### 5. `status` — Daemon status

**Params:** none

**Response:**

```json
{
  "app_count": 42,
  "uptime": "1h23m45s"
}
```

---

### 6. `reindex` — Force application reindex

**Params:** none

**Response:**

```json
true
```

---

## Client examples

### Shell (nc)

```bash
# Ping
echo '{"id":"1","method":"ping"}' | nc -U /run/user/1000/app-launcher/socket

# Search apps
echo '{"id":"1","method":"query","params":{"query":"chrome"}}' | nc -U /run/user/1000/app-launcher/socket

# Calculator
echo '{"id":"1","method":"query","params":{"query":"=pi*2"}}' | nc -U /run/user/1000/app-launcher/socket

# Shell command
echo '{"id":"1","method":"query","params":{"query":">uptime"}}' | nc -U /run/user/1000/app-launcher/socket

# Launch an app
echo '{"id":"1","method":"launch","params":{"entry_id":"abc12345","exec":"chromium"}}' | nc -U /run/user/1000/app-launcher/socket
```

### Python

```python
import json, socket

SOCK = "/run/user/1000/app-launcher/socket"

def rpc(method, params=None):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCK)
    req = json.dumps({"id": "1", "method": method, "params": params or {}})
    sock.sendall(req.encode())
    data = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        data += chunk
    sock.close()
    return json.loads(data)

# Usage
print(rpc("ping"))
print(rpc("query", {"query": "chrome", "limit": 5}))
print(rpc("query", {"query": "=2+2"}))
print(rpc("query", {"query": ">ls"}))
print(rpc("launch", {"entry_id": "abc123", "exec": "chromium"}))
```

### Go

```go
import (
    "encoding/json"
    "net"
)

func rpc(socketPath, method string, params any) (map[string]any, error) {
    conn, _ := net.Dial("unix", socketPath)
    defer conn.Close()

    req, _ := json.Marshal(map[string]any{
        "id": "1", "method": method, "params": params,
    })
    conn.Write(req)

    var resp map[string]any
    json.NewDecoder(conn).Decode(&resp)
    return resp, nil
}
```

---

## Security

**The daemon does not expose any network port.** It listens exclusively on a Unix domain socket with filesystem permissions `0660` (user + group only). This means:

- Only processes running as the same user (or in the same group) can connect.
- Remote access is impossible — no TCP, no HTTP, no network stack involved.
- The socket lives under `$XDG_RUNTIME_DIR` which is typically a `tmpfs` only accessible to the owning user.

**Optional auth token:** Set `auth_token` in config to require a shared secret on every request:

```yaml
# ~/.config/app-launcher/config.yaml
ipc:
  auth_token: "my-secret-token"
```

Then every request must include `"auth"` at the top level:

```json
{
  "id": "1",
  "auth": "my-secret-token",
  "method": "query",
  "params": { "query": "chrome" }
}
```

Requests with a missing or wrong token get `{"error":{"code":-99,"message":"unauthorized"}}`.

If you need to expose it to a different user on the same machine, place the socket in a shared directory and widen permissions. Do **not** wrap it in a TCP proxy unless you add TLS and authentication.

---

## Feature toggles

All query routing features can be disabled per-mode in `~/.config/app-launcher/config.yaml`:

```yaml
features:
  calculator:
    enabled: true
  shell:
    enabled: true
    timeout: "5s"
  window_switcher:
    enabled: true
```

When a feature is disabled, its prefix is treated as a regular app search query.
