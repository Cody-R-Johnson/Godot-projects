extends Node2D

## Main.gd — Runs the procedural arena loop, pause UI, player resets, and projectiles.

@export var background_color: Color = Color(0.07, 0.07, 0.12)
@export_enum("easy", "normal", "hard") var difficulty: String = "normal"

const PLAYER_SPAWN := Vector2(96.0, 360.0)

var _projectile_scene: PackedScene = preload("res://scenes/Bullet.tscn")

@onready var level_label: Label = $CanvasLayer/HUD/TopBar/CenterPanel/Metrics/LevelLabel
@onready var wave_label: Label = $CanvasLayer/HUD/TopBar/CenterPanel/Metrics/WaveLabel
@onready var enemies_label: Label = $CanvasLayer/HUD/TopBar/CenterPanel/Metrics/EnemiesLabel
@onready var lives_label: Label = $CanvasLayer/HUD/TopBar/RightPanel/Stats/LivesLabel
@onready var run_time_label: Label = $CanvasLayer/HUD/TopBar/RightPanel/Stats/RunTimeLabel
@onready var fps_label: Label = $CanvasLayer/HUD/TopBar/RightPanel/Stats/FPSLabel
@onready var status_label: Label = $CanvasLayer/HUD/TopBar/LeftPanel/Info/StatusLabel
@onready var hint_label: Label = $CanvasLayer/HUD/BottomHint/HintLabel
@onready var intro_panel: PanelContainer = $CanvasLayer/HUD/CenterAnnouncement
@onready var intro_title_label: Label = $CanvasLayer/HUD/CenterAnnouncement/IntroVBox/IntroTitleLabel
@onready var intro_countdown_label: Label = $CanvasLayer/HUD/CenterAnnouncement/IntroVBox/IntroCountdownLabel
@onready var intro_recap_label: Label = $CanvasLayer/HUD/CenterAnnouncement/IntroVBox/IntroRecapLabel
@onready var hud_root: Control = $CanvasLayer/HUD
@onready var main_menu: Control = $CanvasLayer/MainMenu
@onready var start_game_btn: Button = $CanvasLayer/MainMenu/Panel/VBox/StartGameButton
@onready var difficulty_option: OptionButton = $CanvasLayer/MainMenu/Panel/VBox/DifficultyRow/DifficultyOption
@onready var menu_quit_btn: Button = $CanvasLayer/MainMenu/Panel/VBox/MenuQuitButton
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var resume_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/ResumeButton
@onready var restart_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/RestartButton
@onready var quit_btn: Button = $CanvasLayer/PauseMenu/Panel/VBox/QuitButton
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu
@onready var game_over_label: Label = $CanvasLayer/GameOverMenu/Panel/VBox/GameOverLabel
@onready var game_over_stats_label: Label = $CanvasLayer/GameOverMenu/Panel/VBox/StatsLabel
@onready var game_over_retry_btn: Button = $CanvasLayer/GameOverMenu/Panel/VBox/TryAgainButton
@onready var game_over_quit_btn: Button = $CanvasLayer/GameOverMenu/Panel/VBox/QuitButton
@onready var player: CharacterBody2D = $Player
@onready var spawner = $World/Spawner
@onready var wall_container: Node2D = $World/WallContainer
@onready var enemy_container: Node2D = $World/EnemyContainer
@onready var pickup_container: Node2D = $World/PickupContainer
@onready var bullet_container: Node2D = $World/BulletContainer

var _level: int = 1
var _alive_enemies: int = 0
var _is_boss_wave: bool = false
var _boss_health: int = 0
var _run_time_seconds: float = 0.0
var _transition_running: bool = false
var _wave_in_progress: bool = false
var _level_start_run_time: float = 0.0
var _level_enemy_total: int = 0
var _level_shots_fired: int = 0
var _level_hits_taken: int = 0
var _last_reported_hits: int = 0
var _previous_level_summary: String = "New run. Survive the opening wave."
var _last_alive_count: int = 0
var _run_shots_fired: int = 0
var _run_hits_taken: int = 0
var _run_pickups_collected: int = 0
var _run_enemies_defeated: int = 0
var _run_waves_cleared: int = 0
var _run_game_over: bool = false
var _run_started: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(background_color)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	spawner.setup(player, wall_container, enemy_container, pickup_container)
	spawner.set_difficulty(difficulty)
	_setup_difficulty_option()
	spawner.enemy_shot.connect(_on_enemy_shot)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_state_changed.connect(_on_wave_state_changed)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.powerup_collected.connect(_on_powerup_collected)

	player.bullet_fired.connect(_on_player_bullet_fired)
	player.hit_taken.connect(_on_player_hit_taken)
	player.died.connect(_on_player_died)

	resume_btn.pressed.connect(_resume)
	restart_btn.pressed.connect(_restart_run)
	quit_btn.pressed.connect(get_tree().quit)
	game_over_retry_btn.pressed.connect(_restart_run)
	game_over_quit_btn.pressed.connect(get_tree().quit)
	start_game_btn.pressed.connect(_on_start_game_pressed)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	menu_quit_btn.pressed.connect(get_tree().quit)

	_show_main_menu()
	print("✔ Procedural arena shooter ready — Godot %s" % Engine.get_version_info().string)


func _process(delta: float) -> void:
	if _run_started and not get_tree().paused:
		_run_time_seconds += delta
		_update_run_time_label()
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if main_menu.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _transition_running:
			return
		if _run_game_over:
			return
		if get_tree().paused:
			_resume()
		else:
			_pause()


func _restart_run() -> void:
	_run_started = true
	_level = 1
	_run_time_seconds = 0.0
	_run_shots_fired = 0
	_run_hits_taken = 0
	_run_pickups_collected = 0
	_run_enemies_defeated = 0
	_run_waves_cleared = 0
	_last_alive_count = 0
	_run_game_over = false
	_previous_level_summary = "New run. Survive the opening wave."
	_clear_projectiles()
	player.reset_state(PLAYER_SPAWN, true)
	_resume()
	game_over_menu.visible = false
	main_menu.visible = false
	hud_root.visible = true
	status_label.text = "Fresh run. Use walls to break line-of-sight."
	hint_label.text = "Difficulty: %s   •   WASD Move   •   Mouse Aim   •   LMB / Space Shoot   •   Esc Pause" % difficulty.capitalize()
	intro_panel.visible = false
	spawner.clear_level()
	_begin_level_transition(true)
	_update_hud()


func _show_main_menu() -> void:
	_run_started = false
	main_menu.visible = true
	hud_root.visible = false
	pause_menu.visible = false
	game_over_menu.visible = false
	intro_panel.visible = false
	spawner.clear_level()
	_clear_projectiles()
	player.set_controls_enabled(false)
	get_tree().paused = false


func _setup_difficulty_option() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Hard")
	var selected := 1
	match difficulty:
		"easy":
			selected = 0
		"hard":
			selected = 2
	difficulty_option.select(selected)


func _on_start_game_pressed() -> void:
	_restart_run()


func _on_difficulty_selected(index: int) -> void:
	match index:
		0:
			difficulty = "easy"
		1:
			difficulty = "normal"
		2:
			difficulty = "hard"
		_:
			difficulty = "normal"
	spawner.set_difficulty(difficulty)


func _start_next_level() -> void:
	_begin_level_transition(false)


func _begin_level_transition(restore_hits: bool) -> void:
	if _transition_running:
		return

	_transition_running = true
	_wave_in_progress = false
	_clear_projectiles()
	spawner.clear_level()
	player.reset_state(PLAYER_SPAWN, restore_hits)
	player.set_controls_enabled(false)
	_update_hud()
	await _play_level_intro_sequence()

	spawner.generate_level(_level, PLAYER_SPAWN)
	player.set_controls_enabled(true)
	_transition_running = false


func _play_level_intro_sequence() -> void:
	intro_panel.visible = true
	intro_panel.scale = Vector2(0.9, 0.9)
	intro_panel.modulate.a = 0.0
	intro_title_label.text = "LEVEL %d" % _level
	intro_recap_label.text = _previous_level_summary
	await _animate_intro_open()

	for count in [3, 2, 1]:
		intro_countdown_label.text = "Starting in %d..." % count
		await _animate_countdown_pulse()
		await get_tree().create_timer(0.75).timeout

	intro_countdown_label.text = "GO!"
	await _animate_countdown_pulse(1.18)
	await get_tree().create_timer(0.35).timeout
	await _animate_intro_close()
	intro_panel.visible = false


func _animate_intro_open() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(intro_panel, "modulate:a", 1.0, 0.26)
	tween.parallel().tween_property(intro_panel, "scale", Vector2.ONE, 0.26)
	await tween.finished


func _animate_intro_close() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(intro_panel, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(intro_panel, "scale", Vector2(1.05, 1.05), 0.18)
	await tween.finished


func _animate_countdown_pulse(scale_strength: float = 1.1) -> void:
	intro_countdown_label.scale = Vector2(0.88, 0.88)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(intro_countdown_label, "scale", Vector2(scale_strength, scale_strength), 0.15)
	tween.tween_property(intro_countdown_label, "scale", Vector2.ONE, 0.12)
	await tween.finished


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
	wave_label.text = "Wave Type: %s" % ("Boss" if _is_boss_wave else "Standard")
	lives_label.text = "Hits Left: %d" % player.get_remaining_hits()
	if _is_boss_wave:
		enemies_label.text = "Boss HP: %d" % max(_boss_health, 0)
	else:
		enemies_label.text = "Enemies Left: %d" % _alive_enemies
	_update_run_time_label()


func _update_run_time_label() -> void:
	var total_seconds := int(_run_time_seconds)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	run_time_label.text = "Run Time: %02d:%02d" % [minutes, seconds]


func _pause() -> void:
	if _run_game_over:
		return
	get_tree().paused = true
	pause_menu.visible = true


func _resume() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_player_bullet_fired(pos: Vector2, dir: Vector2) -> void:
	if _wave_in_progress:
		_level_shots_fired += 1
		_run_shots_fired += 1
	_spawn_projectile(pos, dir, "player", 760.0)


func _on_enemy_shot(pos: Vector2, dir: Vector2, speed: float, is_boss: bool) -> void:
	_spawn_projectile(pos, dir, "enemy", speed, is_boss)


func _on_player_hit_taken(remaining_hits: int) -> void:
	if _wave_in_progress and remaining_hits < _last_reported_hits:
		var lost := _last_reported_hits - remaining_hits
		_level_hits_taken += lost
		_run_hits_taken += lost
	_last_reported_hits = remaining_hits
	lives_label.text = "Hits Left: %d" % remaining_hits
	status_label.text = "You've been hit. Use the walls for cover."


func _on_player_died() -> void:
	_wave_in_progress = false
	_run_game_over = true
	player.set_controls_enabled(false)
	spawner.clear_level()
	_clear_projectiles()
	status_label.text = "You were eliminated."
	hint_label.text = "Review your run stats and choose Try Again or Quit."
	_show_game_over()


func _on_wave_started(level: int, alive: int, is_boss_wave: bool, boss_health: int) -> void:
	_level = level
	_alive_enemies = alive
	_level_enemy_total = alive
	_is_boss_wave = is_boss_wave
	_boss_health = boss_health
	_wave_in_progress = true
	_level_start_run_time = _run_time_seconds
	_level_shots_fired = 0
	_level_hits_taken = 0
	_last_reported_hits = player.get_remaining_hits()
	_last_alive_count = alive
	if is_boss_wave:
		status_label.text = "Boss wave. Twenty hits to bring it down."
	else:
		status_label.text = "Clear every enemy to reach the next level."
	_update_hud()


func _on_wave_state_changed(alive: int, is_boss_wave: bool, boss_health: int) -> void:
	if _wave_in_progress and alive < _last_alive_count:
		_run_enemies_defeated += (_last_alive_count - alive)
	_last_alive_count = alive
	_alive_enemies = alive
	_is_boss_wave = is_boss_wave
	_boss_health = boss_health
	_update_hud()


func _on_wave_cleared() -> void:
	_capture_previous_level_stats()
	_run_waves_cleared += 1
	_wave_in_progress = false
	_level += 1
	status_label.text = "Wave cleared. Generating level %d..." % _level
	_start_next_level()


func _on_powerup_collected(kind: String) -> void:
	match kind:
		"heal":
			status_label.text = "Full repair collected. Hits fully restored."
		"invincible":
			status_label.text = "Shield pickup active. You're invincible for a short time."
		"power_gun":
			status_label.text = "Weapon upgrade active. Triple-shot enabled."
		_:
			status_label.text = "Power-up collected."
	_run_pickups_collected += 1
	_update_hud()


func _capture_previous_level_stats() -> void:
	var duration_text := _format_seconds(max(_run_time_seconds - _level_start_run_time, 0.0))
	var wave_type := "Boss" if _is_boss_wave else "Standard"
	_previous_level_summary = "Previous Level %d (%s)\nTime: %s   •   Enemies: %d\nShots: %d   •   Hits Taken: %d" % [
		_level,
		wave_type,
		duration_text,
		_level_enemy_total,
		_level_shots_fired,
		_level_hits_taken,
	]


func _format_seconds(total_seconds: float) -> String:
	var total := int(total_seconds)
	var minutes := total / 60
	var seconds := total % 60
	return "%02d:%02d" % [minutes, seconds]


func _show_game_over() -> void:
	game_over_label.text = "GAME OVER"
	game_over_stats_label.text = "Time Survived: %s\nLevels Cleared: %d\nEnemies Defeated: %d\nShots Fired: %d\nHits Taken: %d\nPower-ups Collected: %d" % [
		_format_seconds(_run_time_seconds),
		_run_waves_cleared,
		_run_enemies_defeated,
		_run_shots_fired,
		_run_hits_taken,
		_run_pickups_collected,
	]
	game_over_menu.visible = true
	get_tree().paused = true
