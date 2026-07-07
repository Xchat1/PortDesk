---
name: PortDeck
description: >
  A lightweight native macOS developer tool for monitoring and gracefully
  shutting down local development services (localhost ports), with trash
  management. Designed for Apple Silicon, targeting macOS 14+.
platform: macOS
framework: SwiftUI

colors:
  primary: "#0A84FF"
  primary-hover: "#0071E3"
  surface: "#1C1C1E"
  surface-variant: "#2C2C2E"
  on-surface: "#F2F2F7"
  on-surface-secondary: "#AEAEB2"
  background: "#000000"
  border: "#38383A"
  safe: "#30D158"
  warning: "#FF9F0A"
  danger: "#FF453A"
  on-danger: "#FFFFFF"
  card-background: "#1C1C1E"

typography:
  headline:
    fontFamily: "SF Pro Display"
    fontSize: "22px"
    fontWeight: 700
    letterSpacing: "-0.02em"
  title:
    fontFamily: "SF Pro Text"
    fontSize: "17px"
    fontWeight: 600
    letterSpacing: "-0.01em"
  section:
    fontFamily: "SF Pro Text"
    fontSize: "15px"
    fontWeight: 600
  body:
    fontFamily: "SF Pro Text"
    fontSize: "13px"
    fontWeight: 400
  caption:
    fontFamily: "SF Pro Text"
    fontSize: "11px"
    fontWeight: 400
    color: "#AEAEB2"
  mono:
    fontFamily: "SF Mono"
    fontSize: "12px"
    fontWeight: 400

spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"

rounded:
  sm: "6px"
  md: "10px"
  lg: "14px"
  xl: "20px"

elevation:
  card: "0 1px 3px rgba(0,0,0,0.4)"
  modal: "0 8px 32px rgba(0,0,0,0.6)"
  drawer: "inset -1px 0 0 rgba(255,255,255,0.06)"

layout:
  sidebar-width: "220px"
  detail-drawer-width: "380px"
  min-window-width: "900px"
  min-window-height: "600px"
  content-padding: "24px"
---

## Overview

PortDeck is a **native macOS developer utility** built with SwiftUI for Apple Silicon.
Its visual language is inspired by macOS system apps (Activity Monitor, Console) — clean,
dark, information-dense — not a consumer app. The aesthetic goal is "invisible infrastructure":
the tool should feel like it belongs in the OS, not stand out.

Target users: macOS developers who run local dev servers, databases, and AI runtimes.

Key design principles:
1. **Calm, not alarming** — Show data clearly without unnecessary visual noise.
2. **Trust through transparency** — Always show PID, port, and process origin before any destructive action.
3. **Native feel** — Use macOS system colors (`NSColor`) and SF fonts. Never import web-era design patterns.

---

## Colors

### Semantic Color System

- **Primary** (`#0A84FF`): Interactive elements, links, active states, progress indicators. This is macOS system blue — do not substitute.
- **Surface** (`#1C1C1E`): Card backgrounds, panel fills. Matches macOS dark sidebar fill.
- **Surface Variant** (`#2C2C2E`): Input backgrounds, hover states on cards.
- **On-Surface** (`#F2F2F7`): Primary text on dark backgrounds.
- **On-Surface Secondary** (`#AEAEB2`): Labels, placeholder text, secondary metadata.
- **Border** (`#38383A`): Dividers, card strokes. Use at 0.8–1px width only.
- **Safe** (`#30D158`): Success states, local-only service badges, healthy indicators.
- **Warning** (`#FF9F0A`): LAN-exposed services, degraded state badges.
- **Danger** (`#FF453A`): Destructive action buttons (Force Kill), error states.

### Color Usage Rules

- Never use `primary` as a background fill — it is for interactive affordances only.
- Status badges (`safe`, `warning`, `danger`) must always appear at **15% opacity background** with full-saturation text/icon.
- Background (`#000000`) is only used for the root window background, never for cards or panels.

---

## Typography

PortDeck uses Apple's native SF font stack exclusively. No web fonts.

| Role | Font | Size | Weight | Usage |
|------|------|------|--------|-------|
| Headline | SF Pro Display | 22px | 700 | Section titles, view headers |
| Title | SF Pro Text | 17px | 600 | Card titles, list row primaries |
| Section | SF Pro Text | 15px | 600 | Group labels, sidebar item text |
| Body | SF Pro Text | 13px | 400 | Descriptive text, detail values |
| Caption | SF Pro Text | 11px | 400 | Timestamps, metadata, labels |
| Mono | SF Mono | 12px | 400 | Port numbers, PIDs, commands, paths |

### Typography Rules

- Port numbers, PIDs, process paths, and command lines **must** use `SF Mono`. Non-negotiable.
- Never scale body text below 11px (caption minimum).
- Line height for body: 1.5. For mono: 1.4.
- Truncate long paths with `.lineLimit(1)` + `truncationMode(.middle)` — never wrap mono text.

---

## Layout

PortDeck uses a **NavigationSplitView** layout (macOS native three-pane):

```
┌─────────────────────────────────────────────────────┐
│  Sidebar (220px) │  Main Content  │  Detail Drawer  │
│                  │  (flex)        │  (380px, opt.)  │
└─────────────────────────────────────────────────────┘
```

- **Sidebar**: Navigation tabs only. PortDeck branding as nav title.
- **Main Content**: Context-sensitive. Fills remaining space.
- **Detail Drawer**: Slides in from the right (`.move(edge: .trailing)`) when a port row is selected.

### Spacing Rules

- Content padding inside panels: `24px` on all sides.
- Card internal padding: `16px`.
- Row vertical padding in lists: `10px`.
- Minimum gap between interactive elements: `8px`.

---

## Elevation & Depth

macOS dark mode relies on subtle border treatment, not heavy shadows.

- **Cards**: `border: 1px solid border-color at 0.12 opacity` + `background: surface`.
- **Drawers**: Left-side `inset -1px 0 rgba(255,255,255,0.06)` separator — never a full shadow.
- **Modals / Alerts**: System-native `NSAlert` or `.alert()` modifier — do not create custom alert overlays.
- Avoid `drop-shadow` on inline elements. Reserve elevation for floating layers.

---

## Shapes

- Buttons (primary action): `cornerRadius: 8px`.
- Cards / containers: `cornerRadius: 14px`.
- Status badges / pills: `cornerRadius: 6px`.
- Input fields: `cornerRadius: 8px` with 1px border.
- Do **not** mix sharp and rounded corners in the same visual grouping.

---

## Components

### Port Row (List Item)

Each port service row displays:
- **Process name** (title weight) + `@hostname:port` (mono, secondary)
- **Status badge** (safe/warning) right-aligned
- Row tap → opens Detail Drawer

### Status Badges

```
┌─────────────────────────────────────┐
│  [icon]  Label text                 │
└─────────────────────────────────────┘
```
- Background: semantic color at 15% opacity.
- Foreground: semantic color at 100%.
- Corner radius: `6px`.
- Font: 10px, SF Pro Text, Bold.
- Icon: SF Symbol, 10px.

### Detail Drawer

- Width: fixed `380px`.
- Header: process name (title) + close button.
- Body: scrollable property list (`PropertyRow` components).
- Footer: action buttons (Stop / Force Kill), stacked vertically.
- Danger button (`Force Kill`) must require a secondary confirmation step — never fire directly.

### Dashboard Cards

Three stat cards in a horizontal row:
- Active Services count
- LAN-Exposed count
- Trash size

Each card: `14px` corner radius, `surface` background, `16px` padding.
Numbers use `headline` font. Labels use `caption`.

### Action Buttons

| Type | Background | Text | Usage |
|------|-----------|------|-------|
| Primary | `primary` (#0A84FF) | White | Navigate, Refresh |
| Destructive | `danger` (#FF453A) | White | Force Kill, Empty Trash |
| Secondary | Transparent + border | `on-surface` | Cancel, secondary actions |

Buttons must have `.cornerRadius(8)` and `.padding(.vertical, 10)`.
Minimum touch/click target: `44×44pt`.

---

## Do's and Don'ts

### Do
- ✅ Use `SF Mono` for all technical data (ports, PIDs, paths, commands).
- ✅ Show process origin (Apple-signed / System / User) before any stop action.
- ✅ Use `safe` color for local-only (`127.0.0.1`) services — they're low risk.
- ✅ Require confirmation (`.alert()`) before **every** destructive action.
- ✅ Log all destructive actions (SIGTERM, SIGKILL, Empty Trash) in `ActionLogService`.
- ✅ Animate list changes with `.animation(.spring())` for smooth data refreshes.
- ✅ Disable refresh button while `isScanning == true`.
- ✅ Support both Chinese and English via `Localization.shared.t()`.

### Don't
- ❌ Never terminate Apple-signed or system processes silently — warn the user first.
- ❌ Never use `sudo` or request admin privileges — PortDeck runs as current user only.
- ❌ Never show raw shell output in the main UI — parse and format it.
- ❌ Never use web fonts (Inter, Roboto, etc.) — this is a native macOS app.
- ❌ Never exceed 80MB idle memory or show any CPU usage at idle.
- ❌ Don't add animations that run on a background thread — all UI updates on `MainActor`.
- ❌ Don't allow color saturation or brightness outside the macOS HIG palette.
- ❌ Don't hardcode English strings — always use `loc.t("key")` from `Localization.swift`.
