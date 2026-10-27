; ============================================================
; WATERSHED THEME - Pine Mist Night (locked Round 7 -> build)
; World: The Watershed - forest source | wave crest | deep
; Skeleton zones are per-monitor percentages of 1920x1080.
; All values pure ASCII on purpose (encoding-safe).
; ============================================================

[Variables]
; --- Palette: PINE MIST - NIGHT (locked winner) ---
Accent=95,158,138
Accent2=119,148,166
Accent3=163,147,94
Base=10,16,14
Panel=24,35,31
TextC=226,235,229
DimC=140,159,152
LineC=47,68,60

GlassTop=28,40,35
GlassBottom=16,25,21
GlassAlpha=186
; NOTE: gradient defs must be meter-local options (GlassFace=) in each
; panel meter - a global variable definition is not accepted as a
; LinearGradient source in this Rainmeter build.

; --- Fonts (kept from the suite) ---
HeaderFont=Rajdhani
DataFont=Chakra Petch

; --- Programs (locked: PRIMARY Bionic, SECONDARY Brave) ---
PrimaryLabel=BIONIC
PrimaryPath=C:\Users\might\.local\Bionic\Bionic.exe
SecondaryLabel=BRAVE
SecondaryPath=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe
; Round 14: Store version uninstalled; official desktop client now at
; the standard %APPDATA% location (spotify: protocol may still resolve
; to the removed Store app, so launch the exe directly)
SpotifyPath=C:\Users\might\AppData\Roaming\Spotify\Spotify.exe
ProtonVPNPath=C:\Program Files\Proton\VPN\ProtonVPN.Launcher.exe

; --- Skeleton: monitor 1 = the source (forest / work) ---
PrimX=(#Monitor1X#+538)
PrimY=(#Monitor1Y#+259)
PrimW=499
; Round 13: dock dropped - border tightened to the stats row
PrimH=464
AgendaX=(#Monitor1X#+77)
AgendaY=(#Monitor1Y#+821)
AgendaW=1840
AgendaH=200
SysX=(#Monitor1X#+977)
SysY=(#Monitor1Y#+821)
SysW=460
SysH=290
; Core-Ember slot = NETWORK orb, Core-Glem slot = PROTON VPN orb
; (folder/config names kept for position + Lumen broadcast compat)
EmberCX=(#Monitor1X#+221)
EmberCY=(#Monitor1Y#+146)
; orb geometry (shared by both status orbs) - Round 13: back down from the
; Round 12 rescale AND recentered: the halo ring reaches OrbCX-(OrbR+23),
; and Rainmeter CLIPS anything left/top of the skin window's 0 edge, so
; CX/CY must stay >= OrbR+24 or the perimeter circles get cut off.
OrbCX=92
OrbCY=92
OrbR=64

; --- Skeleton: monitor 2 = the depth (secondary / art / memos) ---
SecX=(#Monitor2X#+1152)
SecY=(#Monitor2Y#+259)
; Round 13: grid dropped - Brave panel back to a sleek ring card
SecW=420
SecH=324
ArtX=(#Monitor2X#+1632)
ArtY=(#Monitor2Y#+65)
; Round 13: enlarged to host the canvas/video stage (Spicetify bridge)
; stage = 308x548 (9:16) at (16,8) + title/artist/transport/progress below
ArtW=340
ArtH=666
MemoX=(#Monitor2X#+1037)
MemoY=(#Monitor2Y#+575)
MemoW=660
MemoH=250
GlemCX=(#Monitor2X#+1430)
GlemCY=(#Monitor2Y#+124)

; --- Wave: full-width realtime audio waveform (user-drawn line) ---
WaveX=(#Monitor1X#)
WaveY=(#Monitor1Y#+800)
WaveW=3840
WaveH=180

; --- Live layer bands (spanned 3840x1080 canvas) ---
FireflyX1=80
FireflyX2=1900
FireflyY1=140
FireflyY2=880
StreakX1=2050
StreakX2=2950
StreakY1=620
StreakY2=990
PlanktonX1=3050
PlanktonX2=3820
PlanktonY1=80
PlanktonY2=1010
PulseX1=260
PulseX2=3620
PulseY=560

; --- LUMEN = LOAD (defaults; the Load hub overrides these live) ---
Lumen=0.15
LoadPct=15
GlowA=48
GlowA2=14

; --- Shared styles ---
[WText]
FontFace=#DataFont#
FontSize=12
FontColor=#TextC#
AntiAlias=1

[WHeader]
FontFace=#HeaderFont#
FontSize=16
FontColor=#TextC#
AntiAlias=1
InlineSetting=Case | Upper
InlinePattern=.*
InlineSetting2=Weight | 600
InlinePattern2=.*

[WDim]
FontFace=#DataFont#
FontSize=9
FontColor=#DimC#,205
AntiAlias=1
InlineSetting=Case | Upper
InlinePattern=.*

[WValue]
FontFace=#DataFont#
FontSize=13
FontColor=#Accent#,235
AntiAlias=1
InlineSetting=Weight | 700
InlinePattern=.*
