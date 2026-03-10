# Procedural Arena Shooter (Godot 4) 

Playable top-down arena shooter with procedural waves, enemy AI, and boss encounters.

## Why This Is a Good Portfolio Piece

This repo demonstrates practical gameplay engineering in Godot:

- Procedural content generation
- Modular scene/script architecture
- AI behavior and combat loop design
- Event-driven communication with signals
- Real-time debugging and compatibility fixes across Godot versions

## Current Status

- ✅ Player movement, aiming direction, shooting, hit/invulnerability system
- ✅ Procedural wall generation each level
- ✅ Enemy spawning and AI (regular + boss behavior)
- ✅ Shared projectile system (player and enemy bullets)
- ✅ Wave progression and boss wave every 5 levels
- ✅ HUD + pause menu (resume/restart/quit)
- ✅ Procedural power-up pickups (full heal, temporary invincibility, temporary gun upgrade)
- ✅ Center-screen level intro countdown + previous-wave recap stats
- ✅ UI polish pass (structured top bar, bottom hint bar, animated wave transitions)
- ✅ Pickup VFX polish (animated rings, distinct item shapes, collection burst)
- ✅ Main menu with start flow, difficulty selection (Easy/Normal/Hard), and power-up guide
- ✅ Runs on Godot 4.6.x (project originally created on 4.3)

## Project Structure

```
godot/
├── project.godot
├── scenes/
│   ├── Main.tscn
│   ├── Enemy.tscn
│   ├── Bullet.tscn
│   └── Pickup.tscn
└── scripts/
    ├── Main.gd      # game loop, HUD, pause, level flow
    ├── Player.gd    # movement, shooting, damage/invuln
    ├── Enemy.gd     # enemy + boss AI and shooting
    ├── Bullet.gd    # projectile movement/collision/draw
    ├── Pickup.gd    # collectible power-up behavior
    └── Spawner.gd   # procedural walls, enemy waves, and pickups
```

## Gameplay (Current)

- Move with **WASD**
- Aim with the **mouse cursor**
- Shoot with **Left Click** or **Space**
- Pause/Resume with **Esc**
- Choose **Easy / Normal / Hard** from the main menu before starting a run
- Player has **3 hits** per run
- Enemies scale with level
- Every **5th level** is a **boss wave**
- Some levels include collectible power-ups:
    - **Full Heal** (restores hits to max)
    - **Invincibility** (short temporary shield)
    - **Gun Upgrade** (temporary triple-shot + faster fire)
- Between waves, a center-screen intro appears:
    - **LEVEL X**
    - **Starting in 3..2..1..GO**
    - **Previous level recap** (clear time, enemy count, shots fired, hits taken)

## Technical Notes

- Uses script-driven drawing (`_draw`) for player/enemy/bullet visuals (no sprite art required)
- Uses script-driven UI animation (`Tween`) for level intro transitions and countdown pulses
- Uses script-driven pickup VFX (animated rings, icon geometry, burst on collection)
- Uses collision layers for player, enemies, walls, and bullets
- Uses signals for decoupled communication between main loop, spawner, enemies, and player

## Godot Version Notes

- You may see that the project was originally created in 4.3; this is expected.
- It is intended to run in **Godot 4.6.1**.
- If your GPU/driver shows Vulkan render pipeline errors, switch renderer to **Compatibility** in Project Settings and restart.

## How to Run

1. Download Godot 4.6.x
2. Import this folder and open `project.godot`
3. Press **F5**

## Next Planned Improvements

- Start menu and run summary screen
- Basic audio pass (SFX + music)
- Optional score persistence/high-score table
