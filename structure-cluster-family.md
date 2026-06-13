# Cluster Family Architecture

## Overview

The Cluster Family is a suite of Android apps sharing the same signing key (`cluster_family.jks`) that can communicate with each other to provide an integrated privileged environment. The central controller is **cl-andro** (a Termux fork), which runs a Debian proot container with **OpenCode** (AI coding agent) inside it. OpenCode controls all other Cluster Family apps through a local HTTP bridge.

```
┌─────────────────────────────────────────────────────────┐
│                     Android Device                       │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  cl-andro (com.zk.clandro)                       │   │
│  │  ┌─────────────────────────────────────────┐    │   │
│  │  │  Debian Proot Container                  │    │   │
│  │  │  ┌──────────────────────────────────┐   │    │   │
│  │  │  │  OpenCode AI Agent                │   │    │   │
│  │  │  │  (coding agent CLI)               │   │    │   │
│  │  │  │                                   │   │    │   │
│  │  │  │  clusterctl <command>             │   │    │   │
│  │  │  │    ↓ curl                           │   │    │   │
│  │  │  └──────────┬───────────────────────┘   │    │   │
│  │  │             │ HTTP (127.0.0.1)          │    │   │
│  │  └─────────────┼───────────────────────────┘    │   │
│  │                │                                 │   │
│  │  ┌─────────────┴───────────────────────────┐    │   │
│  │  │  ClusterBridgeService                    │    │   │
│  │  │  (HTTP REST server)                     │    │   │
│  │  │                                          │    │   │
│  │  │  Endpoints:                              │    │   │
│  │  │  GET  /api/v1/status                     │    │   │
│  │  │  POST /api/v1/exec     → Run command    │    │   │
│  │  │  POST /api/v1/intent   → Fire intent    │    │   │
│  │  │  POST /api/v1/terminal → Start terminal │    │   │
│  │  │  POST /api/v1/install  → Install APK    │    │   │
│  │  │  POST /api/v1/input    → Input inject   │    │   │
│  │  └──────────┬──────────────────────────────┘    │   │
│  │             │ Binder IPC                         │   │
│  └─────────────┼────────────────────────────────────┘   │
│                │                                         │
│  ┌─────────────┴────────────────────────────────────┐   │
│  │  cluster-auto: Shizuku Daemon (shell UID)        │   │
│  │  (com.zk.clAuto)                                 │   │
│  │                                                   │   │
│  │  IShizukuService AIDL Interface:                  │   │
│  │  • newProcess()  - Execute command                │   │
│  │  • getUid()      - Get daemon UID                 │   │
│  │  • getVersion()  - API version                    │   │
│  │  • exit()        - Stop daemon                    │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  cluster-browser (com.zk.clusterBrowser)          │   │
│  │  ┌──────────────────────────────────────────┐    │   │
│  │  │  ContentProvider for app control          │    │   │
│  │  │  (exposed at signature level)             │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  cluster-auth (com.zk.cluster.auth.debug)         │   │
│  │  ┌──────────────────────────────────────────┐    │   │
│  │  │  Authentication service                   │    │   │
│  └──────────────────────────────────────────────┘   │   │
└─────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Signing & Permissions
- **Keystore**: `cluster_family.jks` — shared by all Cluster Family apps
- **Key alias**: `cluster_alias`
- **Password**: `clusterfamilypass`
- **Effect**: Apps signed with this key can:
  - Use signature-level permissions (`protectionLevel="signature"`)
  - Access each other's exported components
  - Share UIDs (if `sharedUserId` is declared)
  - Communicate via Binder, ContentProvider, and intents

### 2. cl-andro (com.zk.clandro)
- **Purpose**: Termux-based terminal environment with proot support
- **Key features**:
  - Runs a Debian proot container with full package manager
  - `ClusterTerminalService` — AIDL-based remote terminal control
  - `RunCommandService` — Execute commands via intents
  - `TerminalWebSocketServer` — WebSocket terminal sharing
  - Java-WebSocket library already bundled
  - `sharedUserId=com.zk.clandro` — allows same-UID sharing with other apps
- **Bootstrap**: Offline from `assets/bootstrap-aarch64.zip`

### 3. cluster-auto (Shizuku Fork)
- **Purpose**: Privileged daemon running at `shell` UID (UID 2000)
- **Key features**:
  - `shizuku_server` — forks via `app_process`, hosts `IShizukuService`
  - `IShizukuService.newProcess()` — execute commands at shell privilege
  - `IShizukuService.getUid()` — returns 2000 (shell) or 0 (root)
  - Provides Binder IPC for all Cluster Family apps
  - Supports `am`, `pm`, `input`, and all shell-level commands
- **Build**: Android project with Kotlin, AIDL, native C++ starter

### 4. cluster-browser (com.zk.clusterBrowser)
- **Purpose**: Web browser with cluster integration
- Exports components for remote control (intents, ContentProviders)

### 5. cluster-auth (com.zk.cluster.auth.debug)
- **Purpose**: Authentication service for the family
- Exported components for remote auth control

## Communication Flow

### Command Execution (OpenCode → Android)
```
OpenCode → clusterctl exec "am force-stop com.example.app"
  ↓ curl POST /api/v1/exec
ClusterBridgeService
  ↓ Binder transact
Shizuku Daemon (shell UID)
  ↓ Runtime.exec()
Shell command executed
  ↓ stdout/stderr returned
Response → clusterctl → OpenCode
```

### App Launch (OpenCode → cluster-browser)
```
OpenCode → clusterctl start com.zk.clusterBrowser "https://example.com"
  ↓ curl POST /api/v1/intent
ClusterBridgeService
  ↓ context.startActivity()
Browser opens
```

### Permission Granting
```
OpenCode → clusterctl pm grant com.zk.clandro android.permission.WRITE_SECURE_SETTINGS
  ↓ curl POST /api/v1/exec
ClusterBridgeService → Shizuku → pm grant ...
```

## REST API Endpoints

| Method | Path | Description | Request Body |
|--------|------|-------------|--------------|
| `GET` | `/api/v1/status` | Bridge status, daemon UID, API version | — |
| `POST` | `/api/v1/exec` | Execute command at shell UID | `{"command":["cmd","arg1","arg2"],"timeout":30}` |
| `POST` | `/api/v1/exec/stream` | Execute with streaming output | Same as exec, SSE response |
| `POST` | `/api/v1/intent` | Fire Android intent | `{"action":"...","package":"...","data":"..."}` |
| `POST` | `/api/v1/intent/activity` | Start activity | Intent spec |
| `POST` | `/api/v1/intent/service` | Start/bind service | Intent spec |
| `POST` | `/api/v1/intent/broadcast` | Send broadcast | Intent spec |
| `POST` | `/api/v1/terminal` | Start terminal session | `{"shell":"/bin/bash","cwd":"/root"}` |
| `POST` | `/api/v1/input` | Inject input events | `{"type":"tap","x":500,"y":800}` or `{"type":"text","text":"hello"}` |
| `POST` | `/api/v1/install` | Install APK | APK file as multipart |
| `POST` | `/api/v1/settings` | Read/write system settings | `{"namespace":"global","key":"..."}` or `{"action":"put","namespace":"secure","key":"...","value":"..."}` |

## clusterctl CLI

A shell script installed in proot's `/usr/local/bin/clusterctl`. Examples:

```bash
# Get bridge status
clusterctl status

# Execute shell commands at shell UID
clusterctl exec am force-stop com.zk.clusterBrowser
clusterctl exec pm grant com.zk.clandro android.permission.WRITE_SECURE_SETTINGS
clusterctl exec input tap 500 800

# Start apps
clusterctl start com.zk.clusterBrowser "https://example.com"
clusterctl start com.zk.clAuto

# Install APKs
clusterctl install /path/to/app.apk

# Settings
clusterctl settings get global airplane_mode_on
clusterctl settings put secure wifi_on 1
```

## Build Order

### Phase 1: Foundation (this session)
1. Add `ShizukuProvider` to cl-andro-app (receives Binder from Shizuku daemon)
2. Build `ClusterBridgeService` HTTP server in cl-andro-app
3. Wire bridge to Shizuku `newProcess()` for privileged execution
4. Create `clusterctl` CLI script

### Phase 2: Advanced
5. Add WebSocket endpoint for real-time terminal I/O
6. Add broadcast receiver for Shizuku state changes
7. Build manager UI for the bridge (toggle, port config, logs)
8. Integration tests

### Phase 3: Automation
9. OpenCode tool definitions for Android control
10. Script library for common tasks (backup, install, configure)
11. Scheduled tasks / workflows

## File Structure Additions

```
cl-andro-app/app/src/main/java/com/zk/clandro/app/
├── ClusterBridgeService.java           ← New: HTTP bridge server
├── ClusterTerminalService.java         ← Existing: AIDL terminal
├── RunCommandService.java              ← Existing: intent command
└── bridge/
    ├── BridgeServer.java               ← HTTP server implementation
    ├── BridgeRequestHandler.java       ← Request router
    ├── ShizukuClient.java              ← Shizuku Binder wrapper
    └── models/
        ├── ExecRequest.java
        ├── IntentRequest.java
        └── BridgeResponse.java

cl-andro-app/app/src/main/java/com/zk/clandro/app/bridge/provider/
└── ClusterShizukuProvider.java         ← ShizukuProvider for binder delivery

clandro-pkg/rootfs/usr/local/bin/
└── clusterctl                         ← CLI script for proot
```

## Dependencies

### cl-andro-app additions:
- `rikka.shizuku.api` (from cluster-auto) — Shizuku client API
- No new external dependencies — uses `com.sun.net.httpserver` (built into Android)

### cluster-auto (already built):
- Shizuku daemon — already running on device as `shizuku_server`

## Testing

```bash
# From build machine via ADB
adb shell "curl -s http://127.0.0.1:8080/api/v1/status"

# From inside proot
curl -s http://127.0.0.1:8080/api/v1/exec \
  -H "Content-Type: application/json" \
  -d '{"command":["id"]}'

# Expected: uid=2000(shell) gid=2000(shell) groups=2000(shell),...
```
