# 🏀 Basketball Timing Game – Roblox

A Roblox basketball game where you must time your shot on an oscillating **timing meter** to score. Hit the green zone for a **PERFECT!** shot, land in yellow for **SLIGHTLY EARLY/LATE**, miss the zone entirely and the ball flies wide!

---

## Features

| Feature | Details |
|---------|---------|
| **Timing Meter** | An oscillating needle sweeps back and forth across colour-coded zones |
| **Zone feedback** | **PERFECT!** · **SLIGHTLY EARLY** · **SLIGHTLY LATE** · **EARLY!** · **LATE!** · **MISS** |
| **Shot physics** | Server-side launch with proper arc toward the hoop; missed timings add random side-spin |
| **Score tracker** | Score displayed at top-centre; pulses on every basket |
| **Proximity pick-up** | Walk near the ball and press **E** to grab it |
| **Auto-built court** | Court, backboard, rim, net, and ball are built programmatically – no model imports needed |

---

## Controls

| Key | Action |
|-----|--------|
| **E** | Pick up ball (when within range) |
| **F** (hold) | Enter aim mode — timing meter appears |
| **F** (release) | Release shot — timing is read at the moment of release |

---

## Setup in Roblox Studio

1. Open **Roblox Studio** and create a **Baseplate** place.
2. In the **Explorer**, place each script in the correct service:

| File | Destination in Studio |
|------|-----------------------|
| `src/ReplicatedStorage/TimingModule.lua` | `ReplicatedStorage` → new **ModuleScript** |
| `src/ServerScriptService/CourtBuilder.server.lua` | `ServerScriptService` → new **Script** |
| `src/ServerScriptService/GameManager.server.lua` | `ServerScriptService` → new **Script** |
| `src/StarterGui/BasketballGui.lua` | `StarterGui` → new **LocalScript** |
| `src/StarterPlayerScripts/ShootingController.client.lua` | `StarterPlayerScripts` → new **LocalScript** |

3. Copy the contents of each `.lua` file into the corresponding script in Studio.
4. Press **Play** (F5) to test. The court, hoop, and ball will be built automatically.

> **Tip:** Delete the default Baseplate if you want a fully custom court, or keep it as the floor.

---

## Script Overview

```
src/
├── ReplicatedStorage/
│   └── TimingModule.lua             – shared timing-meter state & BindableEvents
├── ServerScriptService/
│   ├── CourtBuilder.server.lua      – builds court, hoop, net, ball in workspace
│   └── GameManager.server.lua       – scoring, basket detection, RemoteEvents
├── StarterGui/
│   └── BasketballGui.lua            – timing-meter UI, score display, shot feedback
└── StarterPlayerScripts/
    └── ShootingController.client.lua – input (E/F), aiming, fires shot to server
```

---

## Timing Zone Guide

```
|  MISS  |  EARLY!  |  SL.EARLY  |  ●PERFECT●  |  SL.LATE  |  LATE!  |  MISS  |
   red      red        yellow          green        yellow      red       red
   10%      20%          15%            10%           15%        20%      10%
```

- The needle moves left ↔ right continuously.
- Release **[F]** when the needle is over the **green** zone for a guaranteed make.
- The feedback text appears on-screen instantly so you always know if you were early or late.
