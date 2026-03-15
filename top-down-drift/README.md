# Top Down Drift

Top Down Drift is a small Godot 4 arcade drifting project built around a simple rectangular circuit. You drive a shape-drawn blue car, initiate drifts with the handbrake, and try to chain clean slides through a scored drift section.

## How to Play

Open the project in Godot 4.6 and run the main scene.

| Key | Action |
|---|---|
| `W` or `Up` | Throttle |
| `S` or `Down` | Brake / reverse |
| `A` or `Left` | Steer left |
| `D` or `Right` | Steer right |
| `Space` | Hold to drift |

## Current Gameplay

- The car uses arcade handling with separate normal and drift traction values.
- Holding `Space` at enough speed puts the car into a drift state with looser rear grip and stronger steering response.
- Rear-wheel smoke and skid marks appear while drifting on asphalt.
- The course uses a green start gate and red finish gate to define a scored challenge section.
- Points only count during an actual drift, not while simply driving around the section.

## Scoring Rules

- Cross the green gate to start a run.
- Cross the red gate to finish the run.
- Score builds only while all drift conditions are met: drift state, minimum speed, enough lateral slip, and active steering input.
- Combos build during a sustained drift and reset after the grace window expires or after a hard impact.

## Track Layout

The current track is generated at runtime in code.

- A 3000 x 3000 grass field forms the background.
- Concrete outer walls enclose the play area.
- A rectangular asphalt circuit sits inside the arena.
- White edge lines and yellow dashed center lines mark the straights.
- Square corner joins connect the straight wall sections.
- Surface zones switch the car between asphalt and grass behavior.

## HUD

The HUD shows the current state of a run in real time.

- Speed in mph
- Drift indicator
- Run status text
- Section timer or best time
- Section score, total score, and best section score
- Current combo multiplier
- Current surface name
- Short result messages when a run starts or ends

## Project Structure

```text
top-down-drift/
├── project.godot
├── scenes/
│   ├── Main.tscn
│   └── Player.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   ├── track.gd
│   └── camera_follow.gd
└── assets/
    ├── fonts/
    ├── sounds/
    └── sprites/
```

## Main Scripts

- `scripts/player.gd`: car physics, drifting, skid marks, smoke, surface handling, scoring, and procedural audio.
- `scripts/track.gd`: builds the rectangular circuit, walls, gates, road markings, and surface zones at startup.
- `scripts/main.gd`: updates the HUD, best-run stats, and result text.

## Tuning Notes

Useful inspector values on the player include:

| Property | Purpose |
|---|---|
| `acceleration` | Forward thrust |
| `brake_force` | Braking strength |
| `max_speed` | Speed cap |
| `normal_traction` | Grip while not drifting |
| `drift_traction` | Sideways grip while drifting |
| `drift_min_speed` | Speed required to enter drift |
| `steer_speed` | Base turn speed |
| `drift_steer_mult` | Steering boost while drifting |
| `score_min_speed` | Minimum speed before scoring starts |
| `score_min_lateral_slip` | Minimum sideways slip before scoring starts |
| `score_rate` | How quickly points are earned |
| `combo_grace_time` | Time before combo drops after a slide ends |
| `skid_fade_delay` | Delay before skid marks fade |
| `skid_fade_duration` | Skid mark fade duration |

## Notes

- The car visuals are built from Godot shapes rather than imported sprites.
- The track is also generated from code rather than hand-drawn tiles.
- The current circuit uses square corners. If you want a more natural driving line, the next improvement is to convert those corners to proper curved geometry and matching paint.
