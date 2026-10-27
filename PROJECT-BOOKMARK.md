# LUMOSEA — PROJECT BOOKMARK
Hand this file to a fresh session. It contains the current state; nothing else needs re-explaining.

## WHAT THIS IS
Rainmeter desktop suite at `C:\Users\might\Documents\Rainmeter\Skins\TwinCores`.
World: **Lumosea** ("a sea of light"). One 3840×1080 scene spans both monitors —
dusk forest (source) → wave crest (transition) → deep water (depth). One light level,
**LUMEN = LOAD**, drives the glow of the whole system: idle = candle, load = bonfire.
Branding says Lumosea; internal folders keep the legacy `Watershed/` name for
Rainmeter config-path stability.

## CURRENT STATE
- **Theme**: Pine Mist · Night — palette lives in `@Resources\Watershed.inc`
  (Accent/Accent2/Accent3/Base/Panel/Glass*/TextC/DimC/LineC). Hot-switchable
  alternates via the `lumosea-theme-factory` skill; run `@Resources\Scripts\tint-icons.py`
  after ANY palette switch.
- **Suite** (`Watershed\<Name>\<Name>.ini`, one skin per folder): Primary (Bionic
  launcher + load ring + stats), Secondary (Brave ring card), Art (Spotify big art +
  transport + Canvas video stage), Agenda (Sapline strand, click-and-type, dates,
  right-click delete), Memos (3 tabs, click-and-type), System (3 dial gauges),
  Core-Ember (NETWORK orb) / Core-Glem (Proton VPN orb), Live (ambient layer:
  fireflies/flow streaks/plankton/pulse), Wave (128-band audio strip), Load
  (hidden LUMEN hub broadcasting to all skins each second).
- **Comms** (`Comms\Comms.ini`, active sibling): mail/drive/folder rows + YouTube/
  GitHub buttons; styles come from `@Resources\common.inc`, JSON via
  `@Resources\Scripts\Json.lua` (both restored 2026-10-27 after the repo restructure
  had archived them out from under the include).
- **CyberKoi: never touch it** (user-locked).
- Widget positions are user-dragged and persist in Rainmeter.ini — never re-force
  skeleton coordinates.
- **Spotify Canvas pipeline is LIVE**: Spicetify extension (`canvas-bridge.js`) →
  local bridge (`canvas-bridge.py`, 127.0.0.1:8795, launched detached via
  `canvas-bridge-launch.py`) → WebView2 stage (`@Resources\Canvas\stage.html`) in
  the Art widget; `CanvasWatch.lua` toggles video/cover fallback. Telemetry:
  `@Resources\Data\canvas-log.txt` + `canvaswatch-debug.txt`.
- **Repo**: github.com/0d0sys/TwinCores (private, branch `main`, `gh` CLI authed as
  0d0sys). Commit changes; push only when the user asks. `.gitignore` excludes
  `@Resources/Data/*` runtime state; `.gitattributes` is `* -text` to protect encodings.

## PENDING USER TESTS
- Inline typing on Agenda/Memos needs a real human click test (focus can't be automated).
- LUMEN=LOAD idle-vs-load feel; drag by holding CTRL over the video stage; click video = play/pause.
- If gauge needles lag/jump: check the log for TransformationMatrix errors first.

## HARD-WON TECHNICAL FACTS (do not rediscover)
1. Typing: this build bundles the MODERN InputText plugin — activation =
   `[!CommandMeasure <Measure> "ExecuteBatch 1"]`, typed text arrives as `$UserInput$`
   in Command1; `FocusDismiss=1` (click-outside dismisses and DISCARDS the line —
   Enter commits). Editable skins must run at normal z-order (0), never On-Desktop pins.
2. Encodings: INI/Lua are UTF-16 LE BOM or UTF-8 BOM — check with `file` before
   editing and preserve. Python: decode with `'utf-16'` (`'utf-16-le'` keeps the BOM
   char and double-BOM kills Lua). `iconv -f UTF-16LE` (never `-t UTF-16`, it emits BE).
   `/tmp` does not persist between shell calls — decode/modify/encode in ONE call.
3. Two monitors, 1920×1080 each, Monitor2 at x=1920 (`@Resources\variables.inc`).
4. ONE active skin per config folder in this build (Rainmeter 4.5.28) — one folder per skin.
5. Rainmeter auto-deactivates meterless skins with a popup — hidden hub skins need a
   1×1 invisible anchor meter.
6. NEVER pass a .ini path to Rainmeter.exe (treated as a theme file — corrupts configs).
   Use `!ActivateConfig` / `!Refresh` / `!RefreshApp` with config paths only.
7. LinearGradient definitions must be METER-LOCAL options, not global variables.
8. Calc formulas reference measures by name directly (`Formula=MeasureX/1024`).
9. `StringAlign=Center`: X is the CENTER point — use half-width, not 0.
10. PhysicalMemory: `Total=1` measure + Calc ratio (Percentual=1 unreliable).
11. WebNowPlaying (keifufu Redux): `Measure=Plugin` + `Plugin=WebNowPlaying`. State
    0/1/2 = stopped/playing/paused; Status 0/1 = no/yes connection; Progress 0..100;
    PlayPause/Next/Previous via `!CommandMeasure` on ANY WNP measure.
12. Rainmeter.log spans days (truncates only on restart) — read the raw tail, don't
    filter by time-of-day.
13. Command-line bangs get quote-mangled via Git Bash direct exec or PowerShell —
    write a `.cmd` batch file with the bangs as bare args (or use the skill's
    `rainbang.ps1`).
14. Z-order: -2 = On Desktop, -1 = Bottom, 0 = Normal. Widgets 0, Live -1,
    Wave/Load -2. `!LoadOrder` is INVALID in this build.
15. Bar meters scale by the MEASURE's MaxValue — plugin measures need an explicit
    meter MaxValue override; Calc defaults MaxValue=1.
16. Rainmeter's Lua sandbox has NO io.popen/os.execute — shell via the RunCommand
    plugin (Parameter=command, State=Hide, OutputType=ANSI, Timeout, FinishAction →
    `!CommandMeasure Logic`; measure string value = STDOUT).
17. Lua measure methods are `GetValue()` / `GetStringValue()` — GetNumberValue does
    NOT exist (Update() fails and meters silently go stale).
18. Refresh can kill a running RunCommand poll before FinishAction fires — always
    staleness-timeout the pending flag.
19. Screenshots: `snap-widget.ps1` (lift topmost with SWP_NOACTIVATE, capture the
    exact rect, drop back to HWND_NOTOPMOST). Never SW_RESTORE (focus steal); never
    PrintWindow for WebView2 content (captures black).
20. Synthetic clicks can't test input focus — real human clicks only.
21. `netsh interface show interface` is the one-call adapter status source
    (Ethernet/Wi-Fi/ProTUN in one; parse 'Connected|Disconnected' + trailing name).
22. WebView2 plugin uses VISUAL hosting — there are NEVER child windows; probe the
    page with `!CommandMeasure MeasureWebView "Execute <path\to\js>"`. The user-data
    folder follows the TEMP env of the Rainmeter PROCESS (launched from Git Bash it
    lands somewhere odd); a corrupted UDP = transparent/blank render while the page
    is perfectly alive — fix: quit Rainmeter, delete the UDP folder, restart.
23. Shape meters: no Polygon; triangles = named path option inside the meter
    (`TriName=x,y | LineTo ... | LineTo ...`, then `ShapeN=Path TriName`); Path
    segments support only LineTo/ArcTo.
24. Spicetify: the Microsoft Store Spotify canNOT be patched — desktop client only.
    Config at `%APPDATA%\spicetify\config-xpui.ini`; this client unpacks apps as
    FOLDERS (`%APPDATA%\Spotify\Apps\xpui\`). After editing `canvas-bridge.js`: copy
    to `%LOCALAPPDATA%\spicetify\Extensions` AND run `spicetify apply` (it restarts
    Spotify itself). Spotify client updates can drop the patch — re-run `spicetify apply`.
25. Canvaz API returning `canvases=[]` + ttl (3-byte response: 10,90,1c) is an
    authoritative "no canvas" for that track — cover fallback is correct, not a bug.
26. 2026-client token path: `Spicetify.Platform.AuthorizationAPI._state.token`
    (string), fallback = TokenProvider prototype `getToken()`. `Spicetify.getAccessToken`
    no longer exists.
27. Inline PowerShell from Git Bash mangles `$vars`/parens every time — write a
    `.ps1` to the scratchpad and run it with `-File`.
28. Detached background processes: `cmd /c start` fails silently and wscript/VBS is
    disabled on this Win11 build — use the python Popen DETACHED_PROCESS launcher
    pattern (`canvas-bridge-launch.py`).
29. ffmpeg is installed portable at `C:\Users\might\ffmpeg\ffmpeg-9.0.2-essentials_build\bin`
    (banner/GIF tooling).

## SKILLS
- `lumosea-theme-factory` (global): palette contract, theme-template.inc,
  tint-icons.py step, snap-widget.ps1, rainbang.ps1, full gotcha list.
- `desktop-hud-design` (companion): design-board craft — read before building mockups.

## ARCHIVE
Retired first-generation skins, docs, and scripts live under `archive/pre-watershed/`
(kept for reference only). Design boards: `Design/`.
