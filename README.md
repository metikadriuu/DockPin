# DockPin

A tiny macOS menu-bar app that pins your Dock to one specific monitor — even with **"Displays have separate Spaces"** enabled.

> No settings to fiddle with. No Dock restart. No private APIs. Just one job, done well.

---

## Why I built this

I run a multi-monitor setup, and macOS's default behavior drove me up the wall: with **"Displays have separate Spaces"** turned on, the Dock follows the cursor to whichever screen I'm on. I'd push my mouse to the bottom of a screen — even just casually — and the Dock would yank itself across to that monitor, breaking my muscle memory every time.

Apple's only "fix" is to **turn off "Displays have separate Spaces."** But that setting also changes how Spaces and full-screen apps behave across monitors, which I rely on. I just wanted the Dock to stay put on one screen and leave the rest of my setup alone.

There is no preference for this. No `defaults` key. No hidden toggle anywhere in System Settings. So I built one.

## What it does

DockPin lives in your menu bar as a small pin icon. You pick which display the Dock should stay on. From that moment, the Dock never jumps to another monitor — even when your cursor reaches the bottom edge of a different screen.

Or pick **Automatically Follow Main Display** and DockPin keeps the Dock on whichever display macOS currently uses as the Main Display — see [Automatic Main Display pinning](#automatic-main-display-pinning).

It does this without:
- ❌ Disabling "Displays have separate Spaces"
- ❌ Restarting the Dock (no flicker, ever)
- ❌ Modifying any system file
- ❌ Running a hidden background daemon
- ❌ Hacking Dock.app internals or using private APIs

## How it works

There is no public *or* undocumented API to lock the Dock to a specific display on modern macOS. When "Displays have separate Spaces" is on, `WindowServer` triggers the Dock to relocate the moment your cursor touches the bottom row of pixels of any display.

DockPin's trick: it installs a session-level `CGEventTap` that watches mouse-moved events. If the cursor is about to enter the "Dock trigger zone" of a display you haven't pinned, DockPin nudges the cursor 7 pixels back into the screen — **before `WindowServer` ever sees the trigger.** The Dock never gets the signal to relocate, so it stays exactly where you put it.

Hold **⌥ Option** while moving to bypass — useful when you actually do want to drag something across to the other screen.

The geometry pass excludes the part of an edge that's flush against another display, so cursor travel between stacked monitors still works normally.

## Features

- 📌 Pins the Dock to a chosen display
- 🖥️ Multi-monitor aware — switch the pinned display from the menu bar at any time
- 🧭 Optional automatic mode — follows the macOS Main Display, built-in or external
- ⌥ Option-hold bypass for one-off overrides
- 🔁 Auto-reconfigures on display reconnect, sleep/wake, and arrangement changes
- 🚀 Optional "Open at Login" using the modern `SMAppService` API
- 🪶 Universal binary (Apple Silicon + Intel), ~270 KB, near-zero CPU
- 🔐 Public APIs only — no SIMBL, no swizzling, no private symbols
- 🎯 Single purpose — does one thing and gets out of your way

## Requirements

- macOS 13 Ventura or later
- Accessibility permission (macOS will prompt on first launch)

## Install

### Option 1 — Build it yourself (recommended)

```sh
git clone https://github.com/metikadriu/DockPin.git
cd DockPin
./build.sh             # compiles DockPin.app (universal binary, ad-hoc signed)
./tools/install.sh     # copies to /Applications and launches it
```

Requires only the Xcode command-line tools (`xcode-select --install`). No Xcode IDE needed.

### Option 2 — Download a prebuilt release

Grab the latest `DockPin.app` from the [Releases](https://github.com/metikadriu/DockPin/releases) page and drag it into `/Applications`.

### First-launch permission

macOS will ask for **Accessibility** permission on first launch:
*System Settings → Privacy & Security → Accessibility → enable DockPin.*

This is required for the event-tap mechanism that makes the whole thing work. DockPin uses this permission **only** to nudge the cursor by a few pixels at the bottom edge of non-pinned displays. It reads no keystrokes and no data leaves your Mac.

## Use

Click the 📌 pin icon in your menu bar:

| Item | What it does |
|------|--------------|
| **Active** | Toggle DockPin on/off |
| **Lock Dock to ▶** | Pick which display the Dock stays on, or **Automatically Follow Main Display** |
| **Open at Login** | Auto-start on every login (uses `SMAppService`) |
| **Open Accessibility Settings…** | Shortcut to the permission pane |
| **Quit DockPin** | Exit |

That's the entire UI. **Hold ⌥ Option** any time you want to temporarily move the Dock to another monitor on purpose.

## Automatic Main Display pinning

**Lock Dock to ▶** holds two mutually exclusive ways of choosing the target, and exactly one entry in it is checked:

| | Manual mode (default) | Automatic mode |
|---|---|---|
| Select it with | any display in the list | **Automatically Follow Main Display** |
| Dock is pinned to | the display you picked, Main Display or not | whichever display is the macOS Main Display, built-in or external |
| Main Display changes | nothing happens | the target moves with it |
| Target is disconnected | *"⚠ Pinned display not connected"* until it is back or you pick another | macOS makes another display the Main Display and DockPin follows |
| Status line | *"Pinning Dock to ‹display›"* | *"Pinning Dock to ‹display› (automatic)"* |

The Main Display is the one set to **Use as: Main display** in *System Settings → Displays*. DockPin reads it with `CGMainDisplayID()` whenever the display configuration changes — a display is connected or disconnected, the Main Display is reassigned, the arrangement changes, the Mac wakes — so nothing needs reselecting or restarting. Automatic mode does not favour external displays: if the built-in display is the Main Display, that is where the Dock is pinned.

Manual mode stays the default, and switching modes never discards your manual choice: the display you last picked remains stored while automatic mode is on, and picking any display in the list returns to manual mode. Mode and manual choice both survive restarts and logins.

With only one display connected there is nothing to pin against in either mode, and DockPin idles.

### DockPin does not move the Dock

DockPin keeps the pointer out of the Dock trigger zone of every display except the target. That stops the Dock from *leaving* the target; it does not bring the Dock *to* it, and macOS has no public API for placing the Dock on a display. So when the target changes — you pick another display, or the Main Display changes in automatic mode — DockPin leaves the Dock wherever macOS is currently showing it. If that is not the target, move the pointer to the Dock edge of the target display and push against it once, as you would without DockPin; from then on the Dock stays.

That push needs a free stretch of edge. If another display sits flush against the target's whole Dock edge — directly below it, say, with the Dock at the bottom — the pointer simply crosses over and there is nothing to push against until the displays are rearranged.

## Troubleshooting

**The Dock still follows my cursor after install.**
Open the menu and look at the **status line** at the top — it'll tell you exactly what's wrong:

- *"⚠ Accessibility permission required"* — the most common cause. Click **Open Accessibility Settings to fix…** and toggle DockPin on.
- *"⚠ Pinned display not connected"* — the screen you previously pinned to is no longer attached. Click **Lock Dock to ▶** and pick a current display, or pick **Automatically Follow Main Display** to stop depending on one particular screen.
- *"Only one display connected"* — there's nothing to pin against; DockPin idles in this state.

**I changed the target (or the Main Display) and the Dock is still on the other screen.**
DockPin keeps the Dock from leaving the target; it doesn't carry it there. See [DockPin does not move the Dock](#dockpin-does-not-move-the-dock).

**I rebuilt / moved the app and now permission is "granted" but it doesn't work.**
This is a quirk of ad-hoc-signed apps + macOS's TCC database — the grant is tied to the binary's signature hash, and that hash changes on every rebuild. `tools/install.sh` resets the grant automatically on each reinstall so you'll get a fresh prompt. If you need to do it by hand:

```sh
tccutil reset Accessibility com.meti.dockpin
pkill -f DockPin
open /Applications/DockPin.app
```

…then grant permission again when prompted.

To make the grant survive rebuilds, sign with a stable Apple Developer ID certificate (free, doesn't require the paid program) instead of the ad-hoc signature used by `build.sh`.

**The menu-bar icon shows a pin with a slash through it.**
That's the visual cue that DockPin can't enforce its lock right now — check the status line for the reason.

## Why this should keep working on future macOS releases

DockPin uses only stable, public Apple APIs:

- `CGEventTap` (Quartz Event Services)
- `NSScreen`, `NSStatusItem` (AppKit)
- `CGMainDisplayID` (Quartz Display Services)
- `SMAppService` (Service Management — Apple's current login-item API)
- `AXIsProcessTrustedWithOptions` (Accessibility)

It doesn't depend on Dock.app internals or any private framework. As long as macOS continues to trigger Dock relocation from cursor proximity — which is the design pattern underpinning every Apple multi-monitor behavior — DockPin's interception strategy will continue to work.

## Project layout

```
DockPin/
├── src/                      Swift sources
│   ├── main.swift
│   ├── AppDelegate.swift     Menu bar UI
│   ├── DockPinner.swift      Event tap + geometry
│   └── DisplayUtils.swift    Display identity + pinning-target selection
├── tests/
│   └── DisplaySelectionTests.swift
├── resources/
│   ├── Info.plist
│   └── AppIcon.icns
├── tools/
│   ├── make_icon.swift       Generates the app icon from code
│   ├── make_icon.sh          Builds .icns from the master PNG
│   └── install.sh            Copies to /Applications + registers
├── build.sh                  Builds DockPin.app
├── test.sh                   Runs the tests
└── README.md
```

No Xcode project, no `Package.swift`, no dependencies. Just `swiftc` and Apple's frameworks.

`./test.sh` compiles and runs the tests for pinning-target selection in both modes. They cover the selection rule only; anything involving real monitors, the event tap, or sleep/wake has to be checked by hand.

## Acknowledgements

The cursor-nudge approach was discovered by reading [DockDoor](https://github.com/ejbills/DockDoor) — a much more comprehensive Dock-enhancement app that includes this feature among many others. **If you want hover previews, window switcher, and more, use DockDoor.** DockPin exists as a tiny standalone implementation for people who just want the pinning behavior with nothing else attached.

## License

[MIT](LICENSE)

---

Built by [Meti Kadriu](https://github.com/metikadriu) in Gjilan, Kosovo. PRs and issues welcome.
