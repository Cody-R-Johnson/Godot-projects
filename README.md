# Procedural Arena Shooter (Godot 4) 🎮

This project has been upgraded from the original orb demo into a playable top-down arena shooter with procedural waves.

## Suggested GitHub Repo Name

- `godot-procedural-arena-shooter`

Alternative options:
- `godot-wave-survival-prototype`
- `godot-gameplay-systems-demo`

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
- ✅ Runs on Godot 4.6.x (project originally created on 4.3)

## Project Structure

```
godot/
├── project.godot
├── scenes/
│   ├── Main.tscn
│   ├── Enemy.tscn
│   └── Bullet.tscn
└── scripts/
    ├── Main.gd      # game loop, HUD, pause, level flow
    ├── Player.gd    # movement, shooting, damage/invuln
    ├── Enemy.gd     # enemy + boss AI and shooting
    ├── Bullet.gd    # projectile movement/collision/draw
    └── Spawner.gd   # procedural walls and enemy waves
```

## Gameplay (Current)

- Move with **WASD**
- Shoot with **Space**
- Pause/Resume with **Esc**
- Player has **3 hits** per run
- Enemies scale with level
- Every **5th level** is a **boss wave**

## Technical Notes

- Uses script-driven drawing (`_draw`) for player/enemy/bullet visuals (no sprite art required)
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
- Power-ups and weapon variations
- Basic audio pass (SFX + music)
- Optional score persistence/high-score table
