# E2E Test Infra: DreezHub

## Test Philosophy
- Opaque-box, requirement-driven.
- Automated headless execution using Python 3.12 (`lupa` Lua 5.5 VM) + `tests/mock_roblox.lua`.
- Validates syntax, module loading, initialization, dependency graph acyclicity, functional preservation, and UI construction.
- Methodology: Category-Partition + Boundary Value Analysis + Pairwise Combinatorial Testing + Real-World Workload Testing.

## Feature Inventory Mapping
| # | Feature | Source | Tier 1 (Unit/Feature) | Tier 2 (Boundary) | Tier 3 (Cross-Feature) |
|---|---------|--------|:---------------------:|:-----------------:|:----------------------:|
| 1 | SharedState & Services | Survey Exp 1 | 5 | 5 | ✓ |
| 2 | Utils & Base64 | Survey Exp 1 | 5 | 5 | ✓ |
| 3 | TeamManager & Ally | Survey Exp 1 | 5 | 5 | ✓ |
| 4 | MouseUnlocker | Survey Exp 1 | 5 | 5 | ✓ |
| 5 | RespawnCore | Survey Exp 1 | 5 | 5 | ✓ |
| 6 | HitboxExpand | Survey Exp 1 | 5 | 5 | ✓ |
| 7 | FreeShiftLockCore | Survey Exp 1 | 5 | 5 | ✓ |
| 8 | AimbotCore | Survey Exp 1 | 5 | 5 | ✓ |
| 9 | KillAuraCore | Survey Exp 1 | 5 | 5 | ✓ |
| 10 | AutoShotCore | Survey Exp 1 | 5 | 5 | ✓ |
| 11 | AutoClickerCore | Survey Exp 1 | 5 | 5 | ✓ |
| 12 | ESPCore | Survey Exp 1 | 5 | 5 | ✓ |
| 13 | HighAlertCore | Survey Exp 1 | 5 | 5 | ✓ |
| 14 | MinimapCore | Survey Exp 1 | 5 | 5 | ✓ |
| 15 | ConfigManager | Survey Exp 2 | 5 | 5 | ✓ |
| 16 | VoidLib Framework | Survey Exp 2 | 5 | 5 | ✓ |
| 17 | WindowTabs Setup | Survey Exp 2 | 5 | 5 | ✓ |
| 18 | Universal Loader | Survey Exp 2 | 5 | 5 | ✓ |

## Test Architecture
- **Mock Engine**: `tests/mock_roblox.lua`
  Provides pure-Lua mocks for:
  `game`, `workspace`, `Players`, `LocalPlayer`, `Teams`, `RunService`, `UserInputService`, `TweenService`, `HttpService`, `CoreGui`, `StarterGui`, `Drawing`, `Vector2`, `Vector3`, `CFrame`, `Color3`, `Instance`, `getgenv`, `HttpGet`, `loadstring`, `mousemoverel`, `writefile`, `readfile`, `isfile`, `makefolder`.
- **Syntax Validator**: `tests/verify_syntax.py`
  Preprocesses Luau `continue` keyword and verifies AST integrity of every `.lua` file with `luaparser`.
- **Integration Test Runner**: `tests/test_hub.py`
  Executes headless tests across all tiers and asserts zero unhandled exceptions, correct state mutations, and proper component lifecycles.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Full Hub Bootstrap | Loader -> All 14 Modules -> VoidLib -> WindowTabs | High |
| 2 | Combat Session Simulation | Aimbot + AutoShot + KillAura + TeamManager with multiple enemies/allies | High |
| 3 | Visual ESP & Radar Session | ESPCore + HighAlertCore + MinimapCore rendering over simulated frames | High |
| 4 | Config Save, Mutate & Restore | ConfigManager saving 43 controls, mutating values, and loading cleanly | Medium |
| 5 | FPS Dynamic Toggle Stress | Repeatedly toggling features to verify connect/disconnect lifecycle | Medium |

## Coverage Thresholds
- **Tier 1**: ≥ 5 test cases per feature (18 features × 5 = 90 test cases)
- **Tier 2**: ≥ 5 boundary test cases per feature (90 test cases)
- **Tier 3**: Pairwise interaction tests between core modules and UI
- **Tier 4**: ≥ 5 real-world integration workloads
- **Tier 5**: Adversarial white-box edge case testing
