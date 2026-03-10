extends Node2D

## Main.gd — Runs the procedural arena loop, pause UI, player resets, and projectiles.

@export var background_color: Color = Color(0.07, 0.07, 0.12)

const PLAYER_SPAWN := Vector2(96.0, 360.0)

var _projectile_scene: PackedScene = preload("res://scenes/Bullet.tscn")

@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var lives_label: Label = $CanvasLayer/HUD/LivesLabel
@onready var enemies_label: Label = $CanvasLayer/HUD/EnemiesLabel
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var fps_label: Label = $CanvasLayer/HUD/FPSLabel
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var resume_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/ResumeButton
@onready var restart_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/RestartButton
@onready var quit_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/QuitButton
@onready var player: CharacterBody2D = $Player
@onready var spawner = $World/Spawner
@onready var wall_container: Node2D = $World/WallContainer
@onready var enemy_container: Node2D = $World/EnemyContainer
@onready var bullet_container: Node2D = $World/BulletContainer

var _level: int = 1
var _alive_enemies: int = 0
var _is_boss_wave: bool = false
var _boss_health: int = 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(background_color)

	spawner.setup(player, wall_container, enemy_container)
	spawner.enemy_shot.connect(_on_enemy_shot)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_state_changed.connect(_on_wave_state_changed)
	spawner.wave_cleared.connect(_on_wave_cleared)

	player.bullet_fired.connect(_on_player_bullet_fired)
	player.hit_taken.connect(_on_player_hit_taken)
	player.died.connect(_on_player_died)

	resume_btn.pressed.connect(_resume)
	restart_btn.pressed.connect(_restart_run)
	quit_btn.pressed.connect(get_tree().quit)

	_restart_run()
	print("✔ Procedural arena shooter ready — Godot %s" % Engine.get_version_info().string)


func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		else:
			_pause()


func _restart_run() -> void:
	_level = 1
	_clear_projectiles()
	player.reset_state(PLAYER_SPAWN, true)
	_resume()
	status_label.text = "Fresh run. Use walls to break line-of-sight."
	spawner.generate_level(_level, PLAYER_SPAWN)
	_update_hud()


func _start_next_level() -> void:
	_clear_projectiles()
	player.reset_state(PLAYER_SPAWN, false)
	spawner.generate_level(_level, PLAYER_SPAWN)
	_update_hud()


func _spawn_projectile(pos: Vector2, dir: Vector2, team: String, speed: float, is_boss: bool = false) -> void:
	var projectile = _projectile_scene.instantiate()
	projectile.global_position = pos
	bullet_container.add_child(projectile)
	projectile.init(dir, team, speed, 1, is_boss)


func _clear_projectiles() -> void:
	for projectile in bullet_container.get_children():
		projectile.free()


func _update_hud() -> void:
	level_label.text = "Level: %d" % _level
	lives_label.text = "Hits Left: %d" % player.get_remaining_hits()
	if _is_boss_wave:
		enemies_label.text = "Boss HP: %d" % max(_boss_health, 0)
	else:
		enemies_label.text = "Enemies Left: %d" % _alive_enemies


func _pause() -> void:
	get_tree().paused = true
	pause_menu.visible = true


func _resume() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_player_bullet_fired(pos: Vector2, dir: Vector2) -> void:
	_spawn_projectile(pos, dir, "player", 760.0)


func _on_enemy_shot(pos: Vector2, dir: Vector2, speed: float, is_boss: bool) -> void:
	_spawn_projectile(pos, dir, "enemy", speed, is_boss)


func _on_player_hit_taken(remaining_hits: int) -> void:
	lives_label.text = "Hits Left: %d" % remaining_hits
	status_label.text = "You've been hit. Use the walls for cover."


func _on_player_died() -> void:
	status_label.text = "You were eliminated. Restarting from level 1."
	_restart_run()


func _on_wave_started(level: int, alive: int, is_boss_wave: bool, boss_health: int) -> void:
	_level = level
	_alive_enemies = alive
	_is_boss_wave = is_boss_wave
	_boss_health = boss_health
	if is_boss_wave:
		status_label.text = "Boss wave. Twenty hits to bring it down."
	else:
		status_label.text = "Clear every enemy to reach the next level."
	_update_hud()


func _on_wave_state_changed(alive: int, is_boss_wave: bool, boss_health: int) -> void:
	_alive_enemies = alive
	_is_boss_wave = is_boss_wave
	_boss_health = boss_health
	_update_hud()


func _on_wave_cleared() -> void:
	_level += 1
	status_label.text = "Wave cleared. Generating level %d..." % _level
	_start_next_level()
