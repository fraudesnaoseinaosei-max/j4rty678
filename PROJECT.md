# Project: DreezHub Modularization & Refactoring

## Architecture
DreezHub is refactored from a 6,891-line monolithic Lua file (`RespawnHUD.lua`) into a high-performance, modular exploit script hub for Roblox.
The architecture consists of:
1. **Universal Loader** (`RespawnHUD.lua`, <150 lines): Fetches modules from GitHub repository `fraudesnaoseinaosei-max/j4rty678` (branch `main`) using `loadstring(game:HttpGet(url .. "?v=" .. tick()))()`.
2. **Shared State** (`modules/SharedState.lua`): Centralized namespace on `getgenv().DreezHub` containing service caches, friendship cache (`FriendCache`), module registry, configuration tables, and execution guards.
3. **Core Functional Modules** (`modules/*.lua`): Self-contained domain modules communicating through `getgenv().DreezHub`.
4. **UI Layer** (`modules/ConfigManager.lua`, `ui/VoidLib.lua`, `ui/WindowTabs.lua`): Reusable UI component library, configuration persistence, and window/tabs setup preserving 100% Brazilian Portuguese labels and tooltips.
5. **Headless Test & Verification Suite** (`tests/*.lua`, `tests/*.py`): Offline mock environment and automated test suite verifying syntax, module loading, and end-to-end integration without requiring a live game client.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Execution Guard & Global Init | Execution guard via `getgenv().DreeZyHubLoaded`, service caching, default configs | M2 | Survey Explorer 1 |
| 2 | Shared State Registry | Centralized `getgenv().DreezHub` table with module registry and FriendCache | M2 | Survey Explorer 1 |
| 3 | Utilities & Theme Colors | Notification helper, folder creation, pure-Lua Base64 encode/decode, themes | M2 | Survey Explorer 1 |
| 4 | TeamManager | Dynamic team detection, FFA mode resolution, ally check, player color mapping | M2 | Survey Explorer 1 |
| 5 | MouseUnlocker | Modal TextButton trick for unlocking cursor in-game | M2 | Survey Explorer 1 |
| 6 | RespawnCore | Records death CFrame and repositions character upon respawn | M2 | Survey Explorer 1 |
| 7 | HitboxExpand | Part size manipulation with debounced equality check (FPS optimized) | M2 | Survey Explorer 1 |
| 8 | FreeShiftLockCore | Body unlock for shift-lock camera, custom offset, crosshair GUI | M2 | Survey Explorer 1 |
| 9 | AimbotCore | FOV Drawing circle, legit mode, bone switching, pre-raycast 2D FOV check, dynamic connection | M2 | Survey Explorer 1 |
| 10 | KillAuraCore | Melee attack aura with position offsets, noclip, friend caching, dynamic connection | M2 | Survey Explorer 1 |
| 11 | AutoShotCore | Triggerbot with friend/team filters, spam click, friend caching, dynamic connection | M2 | Survey Explorer 1 |
| 12 | AutoClickerCore | Multi-button auto-clicker with dual-layer keybind and dynamic connection | M2 | Survey Explorer 1 |
| 13 | ESPCore | Drawing API bounding boxes, names, health bars, tracers, Blox Fruits Haki V2 inventory, dynamic connection | M2 | Survey Explorer 1 |
| 14 | HighAlertCore | COD Warzone threat indicator, 4 edge borders, 10 chevron arrows, dynamic connection | M2 | Survey Explorer 1 |
| 15 | MinimapCore | Radar HUD, elevation arrows, chunk-based terrain scan, dynamic connection | M2 | Survey Explorer 1 |
| 16 | ConfigManager | JSON save/load system registering 43 controls with Base64 fallback | M3 | Survey Explorer 2 |
| 17 | VoidLib UI Framework | Window creation, themes, mobile support, draggable handling, favorites HUD, context menu, sub-windows | M3 | Survey Explorer 2 |
| 18 | Window & Tabs Setup | 5 tabs (Combate, User, Visual, Local, Configs) with all 43 controls in PT-BR | M3 | Survey Explorer 2 |
| 19 | UI FPS Optimizations | Fix snow frame leak, debounce draggable InputChanged, remove 5s player polling | M3 | Survey Explorer 2 |
| 20 | Legacy Files Deletion | Delete 8 prototype files and 1 video file | M1 | Survey Explorer 3 |
| 21 | Test Mock Environment | Headless Roblox environment mock (`tests/mock_roblox.lua`) | M1 | Survey Explorer 3 |
| 22 | Automated Syntax Checker | Script to validate Lua syntax across all modules (`tests/verify_syntax.py`) | M1 | Survey Explorer 3 |
| 23 | Universal Loader Script | Root `RespawnHUD.lua` (<150 lines) with anti-cache `?v=" .. tick()` | M4 | Survey Explorer 2 |
| 24 | Auto-Reconnect Update | Update server reload string with anti-cache loader URL | M4 | Survey Explorer 3 |
| 25 | Readme Update | Update README.md with anti-cache loadstring pattern and new architecture | M4 | Survey Explorer 3 |
| 26 | E2E Headless Test Suite | Complete 4-tier test suite verifying hub loading, initialization, and UI wiring | M5 | Survey Explorer 3 |
| 27 | Git Commit & Push | Stage, commit, and push to `fraudesnaoseinaosei-max/j4rty678` main branch | M6 | ORIGINAL_REQUEST |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Legacy Cleanup & Test Harness | Delete 9 legacy files; build headless Roblox mock and syntax test suite | none | IN_PROGRESS |
| M2 | Core Modules & FPS Optimization | Extract 14 core modules to `modules/` with dynamic connections and friend caching | M1 | PLANNED |
| M3 | UI Modularization & PT-BR Tabs | Extract `modules/ConfigManager.lua`, `ui/VoidLib.lua`, `ui/WindowTabs.lua` | M2 | PLANNED |
| M4 | Universal Loader & Readme | Create `<150` lines `RespawnHUD.lua` loader and update `README.md` | M3 | PLANNED |
| M5 | E2E Testing & Adversarial Hardening | Run 100% of test suite across Tiers 1-5; verify zero errors | M4 | PLANNED |
| M6 | Git Push & Final Verification | Commit and push to GitHub `origin main`; run final audit | M5 | PLANNED |

## Interface Contracts
### Global Namespace: `getgenv().DreezHub`
- `DreezHub.Loaded`: boolean (prevents duplicate execution)
- `DreezHub.Services`: table of cached Roblox services (Players, RunService, UserInputService, TweenService, HttpService, Workspace, CoreGui, StarterGui, Teams)
- `DreezHub.LocalPlayer`: cached `Players.LocalPlayer`
- `DreezHub.Camera`: cached `Workspace.CurrentCamera`
- `DreezHub.FriendCache`: map `{ [userId: number] = boolean }`
- `DreezHub.Modules`: map `{ [moduleName: string] = moduleTable }`
- `DreezHub.Config`: map `{ [key: string] = any }`
- `DreezHub.Connections`: table of active RBXScriptConnections for clean shutdown

### Module Contract
Each module returns a table and registers into `DreezHub.Modules`:
```lua
local Module = {}
Module.Init = function(DreezHub) ... end
Module.SetEnabled = function(enabled: boolean) ... end -- connects/disconnects per-frame hooks dynamically
return Module
```

## Code Layout
```
DreezHub/
├── RespawnHUD.lua              # Universal Loader (<150 lines)
├── README.md                   # Documentation with anti-cache loadstring
├── modules/
│   ├── SharedState.lua         # getgenv().DreezHub initialization
│   ├── Utils.lua               # Base64, Notify, Themes, Folder helpers
│   ├── TeamManager.lua         # Team, FFA, Ally checks, Colors
│   ├── MouseUnlocker.lua       # Modal mouse unlocker
│   ├── RespawnCore.lua         # Death CFrame tracking & repositioning
│   ├── HitboxExpand.lua        # Hitbox expander with debounce
│   ├── FreeShiftLockCore.lua   # Free shift lock with crosshair
│   ├── AimbotCore.lua          # Aimbot with FOV, bone switch, pre-FOV filter
│   ├── KillAuraCore.lua        # Melee kill aura with noclip & offsets
│   ├── AutoShotCore.lua        # Triggerbot with spam click & filters
│   ├── AutoClickerCore.lua     # Dual-layer auto-clicker
│   ├── ESPCore.lua             # Drawing API ESP, names, health, tracers
│   ├── HighAlertCore.lua       # Threat pulse borders and arrow chevrons
│   ├── MinimapCore.lua         # Radar HUD and elevation indicators
│   └── ConfigManager.lua       # Save/Load settings manager
├── ui/
│   ├── VoidLib.lua             # UI library component framework
│   └── WindowTabs.lua          # 5 Tabs setup with PT-BR labels
└── tests/
    ├── mock_roblox.lua         # Headless Roblox API environment mock
    ├── verify_syntax.py        # Static Lua syntax validator
    ├── test_hub.py             # Headless execution and integration test runner
    └── test_cases.lua          # Tier 1-4 test suites
```
