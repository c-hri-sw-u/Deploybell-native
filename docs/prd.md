Deploybell — PRD

A lightweight macOS menubar app that monitors Vercel deployments in real-time, with sound notifications and visual status indicators.


1. Problem
When you git push and Vercel auto-deploys, you have no passive way to know whether the deployment succeeded or failed — unless you keep the Vercel dashboard open or manually check. This is especially painful when juggling multiple projects: you push, context-switch, and forget to verify.
2. Solution
Deploybell is a macOS menubar app that:

Lives quietly in your menu bar (no dock icon, no main window)
Monitors deployments for your selected Vercel projects
Plays distinct sound effects on deploy success ✅ or failure ❌
Shows a compact dashboard of project statuses via a popover panel

3. Target User
Developers who deploy to Vercel frequently and work on multiple projects simultaneously. They want ambient awareness of deployment status without actively watching a dashboard.
4. Tech Stack
LayerChoiceRationaleFrameworkTauri 2Lightweight (~5MB), native feel, no Electron bloatFrontendReact + TypeScriptFamiliar stack, fast iterationStylingTailwind CSSRapid UI developmentBackend/APIVercel REST API (polling)Zero server dependency, no webhook infra neededAuthPersonal Access TokenSimplest flow for developer usersStorageLocal filesystem (JSON)Token, selected projects, preferencesSoundWeb Audio APIPlays embedded sound effects
5. User Flow
5.1 First Launch (Onboarding)
App starts → Tray icon appears in menu bar
         → Click icon → Popover opens with Setup view
         → "Paste your Vercel Access Token" input field
         → "Get Token →" link opens https://vercel.com/account/tokens
         → User pastes token → App validates via GET /v9/projects
         → Success: Show project list with checkboxes
         → User selects projects to monitor → "Start Monitoring"
         → Transitions to Dashboard view, polling begins
5.2 Steady State (Daily Use)
App runs in background → Polls Vercel API every 5 seconds
  → New deployment detected:
      Status = BUILDING  → Project row shows 🟡 yellow
      Status = READY     → Project row shows 🟢 green + success sound 🔔
      Status = ERROR     → Project row shows 🔴 red + error sound 🔔
      Status = CANCELED  → Project row shows ⚪ gray
  → Tray icon also reflects overall status:
      All green    → Normal icon
      Any building → Pulsing/animated icon
      Any error    → Red-dot badge icon
5.3 Interaction
Click tray icon     → Toggle popover (Dashboard view)
Right-click icon    → Context menu: Settings / Quit
Click project row   → Open deployment URL in browser
Settings            → Change token, add/remove projects, toggle sound, adjust poll interval
6. Core Features
6.1 Deployment Monitoring

Poll GET https://api.vercel.com/v6/deployments?projectId={id}&limit=1 per selected project
Track the latest deployment's state field: BUILDING, READY, ERROR, CANCELED, QUEUED
Detect state transitions (not just current state) to trigger notifications only once per deployment
Store last-seen deployment ID per project to avoid duplicate alerts

6.2 Sound Notifications

Success sound: Short, pleasant chime when deployment reaches READY
Error sound: Distinct alert tone when deployment reaches ERROR
Sounds are embedded in the app bundle (no external dependencies)
User can mute/unmute via Settings or quick-toggle in the dashboard header
Volume respects system volume

6.3 Dashboard UI (Popover Panel)
Compact popover, approximately 320px wide × dynamic height.
┌─────────────────────────────────┐
│  Deploybell     🔇  ⚙️     │  ← Header: app name, mute toggle, settings
├─────────────────────────────────┤
│  🟢  my-portfolio    2m ago     │  ← Green: deployed successfully
│      main · abc1234             │     Branch + short commit hash
│─────────────────────────────────│
│  🟡  client-app      building   │  ← Yellow: currently deploying
│      feat/auth · def5678        │
│─────────────────────────────────│
│  🔴  api-server      5m ago     │  ← Red: deploy failed
│      main · ghi9012             │
└─────────────────────────────────┘
Each row shows:

Status indicator (colored dot)
Project name
Relative time since last deploy (or "building" / "queued")
Git branch + short commit SHA
Entire row is clickable → opens deployment URL in default browser

6.4 Tray Icon States
StateIconAll deployments OKDefault icon (monochrome)Any project buildingIcon with subtle activity indicatorAny project erroredIcon with red badge/dotNo token configuredIcon with setup indicator
Icon should follow macOS template image conventions (monochrome, adapts to light/dark menu bar).
6.5 Settings

Token management: View masked token, replace, or remove
Project selection: Add/remove monitored projects from full project list
Poll interval: 5s (default) / 10s / 15s / 30s / 60s
Adaptive throttling: If projects × (60 / interval) exceeds 80 req/min, show warning and suggest longer interval
Sound: Enable/disable, separate toggles for success/error sounds
Launch at login: Toggle auto-start (macOS launch agent)
Team support: If token has team access, allow selecting team scope

6.6 Local Storage
All config stored in ~/.vercel-sentinel/config.json:
json{
  "token": "encrypted-or-keychain-ref",
  "teamId": null,
  "projects": [
    { "id": "prj_xxx", "name": "my-portfolio" },
    { "id": "prj_yyy", "name": "client-app" }
  ],
  "pollInterval": 5,
  "sound": {
    "enabled": true,
    "success": true,
    "error": true
  },
  "launchAtLogin": false
}
Token should ideally be stored in macOS Keychain via Tauri's secure storage APIs.
7. Vercel API Reference
Authentication
Authorization: Bearer <PERSONAL_ACCESS_TOKEN>
Key Endpoints
EndpointPurposeGET /v9/projectsList all projects (onboarding, project picker)GET /v6/deployments?projectId={id}&limit=1Latest deployment per project (polling)GET /v13/deployments/{id}Deployment detail (optional, for error messages)
Deployment States
StateMeaningQUEUEDWaiting to buildBUILDINGBuild in progressREADYSuccessfully deployedERRORBuild or deployment failedCANCELEDDeployment was canceled
Rate Limits

Vercel API rate limit: ~100 requests per 60 seconds
With 5 projects at 5s intervals, that's ~60 requests/minute — within limits
Adaptive throttling: App calculates projects × (60 / interval) and warns if approaching 80 req/min
Max safe: ~8 projects at 5s, ~15 projects at 10s

8. Project Structure
vercel-sentinel/
├── src/                          # React frontend
│   ├── App.tsx                   # Router: Setup vs Dashboard
│   ├── components/
│   │   ├── ProjectRow.tsx        # Single project status row
│   │   ├── StatusDot.tsx         # Colored status indicator
│   │   └── Header.tsx            # App header with controls
│   ├── pages/
│   │   ├── Setup.tsx             # Token input + project selection
│   │   ├── Dashboard.tsx         # Main monitoring view
│   │   └── Settings.tsx          # Configuration panel
│   ├── hooks/
│   │   ├── useDeployments.ts     # Polling logic + state management
│   │   └── useSound.ts           # Sound effect playback
│   ├── lib/
│   │   ├── vercel-api.ts         # Vercel API client
│   │   ├── config.ts             # Read/write local config
│   │   └── sounds.ts             # Sound file references
│   └── assets/
│       ├── success.mp3
│       └── error.mp3
├── src-tauri/
│   ├── src/
│   │   └── lib.rs                # Tray icon + popover window management
│   ├── icons/                    # Tray icons (template images)
│   │   ├── icon-default.png
│   │   ├── icon-building.png
│   │   └── icon-error.png
│   ├── Cargo.toml
│   └── tauri.conf.json
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── vite.config.ts
9. Non-Goals (V1)

❌ Webhook-based real-time updates (requires server infrastructure)
❌ Deployment logs viewer (use Vercel dashboard for that)
❌ Trigger re-deploys from the app
❌ Windows/Linux support (macOS only for V1, Tauri makes cross-platform possible later)
❌ OAuth integration (token-based is sufficient for developer audience)
❌ Notification Center integration (sound-first approach; can add later)

10. Future Considerations (V2+)

macOS native notifications with action buttons (open deployment, retry)
Webhook mode via a lightweight relay server for instant notifications
Deploy log preview in the popover for quick error diagnosis
Keyboard shortcut to toggle the popover (e.g., ⌘⇧V)
Multiple accounts/teams support
Cross-platform support (Windows/Linux tray)
Sparkle / auto-update framework for seamless updates

## 11. Open Questions
1. **Poll vs. SSE**: Vercel doesn't offer SSE for deployments currently. If they add it, we should switch to reduce latency and API usage.

Solved:
1. **Token security**: Use macOS Keychain (via `tauri-plugin-stronghold`) or encrypted local file? Keychain is more secure but adds dependency complexity.
先用本地json，v2再考虑用keychain
2. **Distribution**: Direct `.dmg` download + Homebrew cask
3. **App name**: "Deploybell" is a working title.