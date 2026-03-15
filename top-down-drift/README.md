# Top Down Drift 🚗💨

A top-down arcade drifting game built in Godot 4. Drive a detailed little car around a track, throw it into corners with the handbrake, and leave satisfying skid marks everywhere.

---

## How to Play

Open the project folder in **Godot 4.6** and hit the Play button. No extra setup needed.

| Key | Action |
|---|---|
| **W** or **↑** | Throttle |
| **S** or **↓** | Brake |
| **A** or **←** | Steer left |
| **D** or **→** | Steer right |
| **Space** | Hold to drift |

---

## The Car

The car is a small blue top-down vehicle drawn entirely with coloured shapes — no external image files needed. Here's what it looks like from above:

- **Blue body** — the main chassis
- **Lighter blue roof** — shows the cabin
- **Tinted windshield and rear glass** — so you can tell front from back at a glance
- **Grey front bumper / dark rear bumper** — clear nose vs tail
- **Yellow-white headlights** (front) and **red tail lights** (rear)
- **Four black tyres** — the two front ones actually rotate left and right as you steer
- **Subtle drop shadow** underneath the whole car

---

## Drifting

Drifting is the star of the show. Here's how it works in plain terms:

- When you're going fast enough and hold **Space**, the rear of the car loses grip and slides sideways.
- While drifting, the front wheels steer more aggressively so you can swing the car around corners.
- The car keeps its momentum while sliding — it doesn't scrub speed instantly like in normal driving.
- Release Space and the tyres bite again, snapping you back on track.

### Visual feedback

- **Grey smoke** puffs out from both rear wheels while you're drifting. The smoke billows and fades naturally.
- **Black skid marks** are drawn on the road under the rear wheels during a slide.
- Skid marks **fade away** after a few seconds so the track doesn't get too cluttered.
- A bright orange **"DRIFT!"** label flashes on screen while you're actively sliding.

---

## The Track

The arena is a large open space (3000 × 3000 px) enclosed by grey concrete walls. Inside there are several obstacles to drift around:

| Obstacle | Description |
|---|---|
| **Outer walls** | Heavy concrete boundary — you'll bounce off these |
| **Central island** | Large square block in the middle of the arena |
| **Corner pillars** | Four big square pillars near each corner |
| **Chicane barriers** | Two pairs of red barriers offset across the track, forcing S-bends — great for chaining drifts |
| **Side alcove blockers** | Narrow pillars on the left and right mid-sides |
| **Slalom cones** | Two rows of orange cones through the top and bottom corridors |

All obstacles are built at runtime from code, so they're easy to tweak.

---

## The HUD

The heads-up display keeps things minimal:

- **Speed** (bottom-right corner) — updates live in game km/h
- **"DRIFT!"** label (centre screen) — appears in bold orange whenever you're in a drift

---

## Project Structure

```
top-down-drift/
├── project.godot        ← Godot project settings and input map
├── scenes/
│   ├── Main.tscn        ← The game world (track, player, HUD)
│   └── Player.tscn      ← The car with all its visual parts
├── scripts/
│   ├── player.gd        ← Car movement, drifting, skid marks, smoke
│   ├── track.gd         ← Builds all walls, pillars, and cones at startup
│   └── main.gd          ← Updates the HUD labels each frame
└── assets/
    ├── sprites/         ← (empty — car is drawn in code)
    ├── sounds/          ← (ready for engine/tyre sounds)
    └── fonts/           ← (ready for custom fonts)
```

---

## Things You Can Tweak

All the fun dials are exposed as properties on the car node in the Godot Inspector:

| Property | What it does |
|---|---|
| `acceleration` | How quickly the car gets up to speed |
| `max_speed` | Top speed cap |
| `drift_traction` | **Lower = longer, floatier drift.** Keep this below 1.0 |
| `normal_traction` | How grippy normal driving feels |
| `drift_min_speed` | Minimum speed before you can enter a drift |
| `steer_speed` | How fast the car turns |
| `drift_steer_mult` | Extra rotation you get during a drift |
| `skid_fade_delay` | How long skid marks stay before fading |
| `skid_fade_duration` | How long the fade-out takes |

---

## What's Next (Ideas)

- Engine and tyre screech sounds
- A lap timer or drift score counter
- Different car colours / skins
- A proper circuit layout with a start/finish line
- AI opponent cars
