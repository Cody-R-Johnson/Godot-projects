extends Node2D

## Spawner.gd — Procedural level director for walls, enemies, and boss waves.

signal enemy_shot(pos: Vector2, dir: Vector2, speed: float, is_boss: bool, damage: int, shot_style: String)
signal wave_started(level: int, alive: int, is_boss_wave: bool, boss_health: int)
signal wave_state_changed(alive: int, is_boss_wave: bool, boss_health: int)
signal wave_cleared
signal powerup_collected(kind: String)

const ARENA_SIZE := Vector2(1280.0, 720.0)
const WALL_LAYER := 8
const DIFFICULTY_PROFILES := {
	"easy": {
		"enemy_count_mult": 0.75,
		"health_mult": 0.8,
		"boss_health_mult": 0.8,
		"speed_mult": 0.9,
		"fire_interval_mult": 1.2,
	},
	"normal": {
		"enemy_count_mult": 1.0,
		"health_mult": 1.0,
		"boss_health_mult": 1.0,
		"speed_mult": 1.0,
		"fire_interval_mult": 1.0,
	},
	"hard": {
		"enemy_count_mult": 1.25,
		"health_mult": 1.25,
		"boss_health_mult": 1.35,
		"speed_mult": 1.12,
		"fire_interval_mult": 0.82,
	},
}

var _enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var _pickup_scene: PackedScene = preload("res://scenes/Pickup.tscn")
var _rng := RandomNumberGenerator.new()

var _player: CharacterBody2D
var _wall_container: Node2D
var _enemy_container: Node2D
var _pickup_container: Node2D
var _wall_rects: Array[Rect2] = []
var _alive_enemies: int = 0
var _boss_health: int = 0
var _is_boss_wave: bool = false
var _difficulty: String = "normal"


func _ready() -> void:
	_rng.randomize()


func setup(player: CharacterBody2D, wall_container: Node2D, enemy_container: Node2D, pickup_container: Node2D) -> void:
	_player = player
	_wall_container = wall_container
	_enemy_container = enemy_container
	_pickup_container = pickup_container


func set_difficulty(mode: String) -> void:
	if DIFFICULTY_PROFILES.has(mode):
		_difficulty = mode
	else:
		_difficulty = "normal"


func clear_level() -> void:
	for enemy in _enemy_container.get_children():
		enemy.free()
	for pickup in _pickup_container.get_children():
		pickup.free()
	for wall in _wall_container.get_children():
		wall.free()
	_wall_rects.clear()
	_alive_enemies = 0
	_boss_health = 0


func generate_level(level: int, player_spawn: Vector2) -> void:
	clear_level()
	_is_boss_wave = level % 5 == 0
	_generate_walls(level, player_spawn)

	if _is_boss_wave:
		_spawn_enemy(_find_spawn_point(player_spawn, 260.0), level, true)
	else:
		var base_enemy_count: int = mini(2 + level, 9)
		var enemy_count_mult: float = _get_difficulty_profile().get("enemy_count_mult", 1.0)
		var enemy_count: int = maxi(1, int(round(base_enemy_count * enemy_count_mult)))
		for index in range(enemy_count):
			var enemy_type := _roll_enemy_type(level, index, enemy_count)
			_spawn_enemy(_find_spawn_point(player_spawn, 220.0), level, false, enemy_type)

	_spawn_pickups(level, player_spawn)

	_emit_wave_started(level)


func _emit_wave_started(level: int) -> void:
	if _is_boss_wave and _alive_enemies > 0:
		var boss = _enemy_container.get_child(0)
		_boss_health = boss.get_health()
	wave_started.emit(level, _alive_enemies, _is_boss_wave, _boss_health)
	wave_state_changed.emit(_alive_enemies, _is_boss_wave, _boss_health)


func _spawn_enemy(spawn_point: Vector2, level: int, is_boss: bool, enemy_type: String = "standard") -> void:
	var enemy = _enemy_scene.instantiate()
	enemy.global_position = spawn_point
	_enemy_container.add_child(enemy)
	enemy.setup(_player, is_boss, level, _get_difficulty_profile(), enemy_type)
	enemy.shoot_requested.connect(_on_enemy_shoot_requested)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.defeated.connect(_on_enemy_defeated)
	_alive_enemies += 1
	if is_boss:
		_boss_health = enemy.get_health()


func _on_enemy_shoot_requested(pos: Vector2, dir: Vector2, speed: float, is_boss: bool, damage: int, shot_style: String) -> void:
	enemy_shot.emit(pos, dir, speed, is_boss, damage, shot_style)


func _on_enemy_health_changed(current_health: int, _max_health: int, is_boss: bool) -> void:
	if is_boss:
		_boss_health = current_health
	wave_state_changed.emit(_alive_enemies, _is_boss_wave, _boss_health)


func _on_enemy_defeated(enemy: CharacterBody2D) -> void:
	_alive_enemies = max(_alive_enemies - 1, 0)
	if enemy.is_boss():
		_boss_health = 0
	wave_state_changed.emit(_alive_enemies, _is_boss_wave, _boss_health)
	if _alive_enemies == 0:
		wave_cleared.emit()


func _spawn_pickups(level: int, player_spawn: Vector2) -> void:
	var pickup_count := 1
	if level % 4 == 0:
		pickup_count = 2
	if _is_boss_wave:
		pickup_count = 1

	var placed_points: Array[Vector2] = []

	# Always place one guaranteed pickup in a safe, visible position near the player.
	var guaranteed_pickup = _pickup_scene.instantiate()
	var guaranteed_point := _find_guaranteed_pickup_point(player_spawn)
	placed_points.append(guaranteed_point)
	guaranteed_pickup.global_position = guaranteed_point
	guaranteed_pickup.pickup_kind = _roll_pickup_type()
	guaranteed_pickup.picked.connect(_on_pickup_picked)
	_pickup_container.add_child(guaranteed_pickup)

	for _index in range(max(pickup_count - 1, 0)):
		var pickup = _pickup_scene.instantiate()
		var spawn_point := _find_pickup_spawn_point(player_spawn, placed_points)
		placed_points.append(spawn_point)
		pickup.global_position = spawn_point
		pickup.pickup_kind = _roll_pickup_type()
		pickup.picked.connect(_on_pickup_picked)
		_pickup_container.add_child(pickup)


func _roll_pickup_type() -> String:
	if _player.get_remaining_hits() <= 1 and _rng.randf() < 0.6:
		return "heal"

	var roll := _rng.randf()
	if roll < 0.38:
		return "heal"
	if roll < 0.7:
		return "invincible"
	return "power_gun"


func _on_pickup_picked(kind: String, _pickup: Area2D) -> void:
	match kind:
		"heal":
			_player.restore_full_health()
		"invincible":
			_player.grant_invincibility(4.5)
		"power_gun":
			_player.grant_power_gun(8.0)
	powerup_collected.emit(kind)


func _get_difficulty_profile() -> Dictionary:
	if DIFFICULTY_PROFILES.has(_difficulty):
		return DIFFICULTY_PROFILES[_difficulty]
	return DIFFICULTY_PROFILES["normal"]


func _roll_enemy_type(level: int, index: int, enemy_count: int) -> String:
	if level >= 7 and index == enemy_count - 1:
		if _rng.randf() < 0.5:
			return "rpg"
		return "sniper"

	var roll := _rng.randf()
	if level >= 5 and roll < 0.2:
		return "rpg"
	if level >= 3 and roll < 0.48:
		return "sniper"
	return "standard"


func _find_pickup_spawn_point(player_spawn: Vector2, existing_points: Array[Vector2]) -> Vector2:
	for _attempt in range(90):
		var point := Vector2(
			_rng.randf_range(170.0, ARENA_SIZE.x - 130.0),
			_rng.randf_range(80.0, ARENA_SIZE.y - 80.0)
		)
		if point.distance_to(player_spawn) < 170.0:
			continue
		if _point_inside_wall(point, 42.0):
			continue

		var too_close := false
		for existing in existing_points:
			if point.distance_to(existing) < 54.0:
				too_close = true
				break
		if too_close:
			continue

		return point

	for gx in range(8):
		for gy in range(4):
			var grid_point := Vector2(170.0 + gx * 130.0, 90.0 + gy * 140.0)
			if grid_point.distance_to(player_spawn) < 160.0:
				continue
			if _point_inside_wall(grid_point, 40.0):
				continue
			var blocked := false
			for existing in existing_points:
				if grid_point.distance_to(existing) < 54.0:
					blocked = true
					break
			if not blocked:
				return grid_point

	for angle_deg in range(0, 360, 30):
		var fallback := player_spawn + Vector2(230.0, 0.0).rotated(deg_to_rad(float(angle_deg)))
		fallback.x = clamp(fallback.x, 170.0, ARENA_SIZE.x - 130.0)
		fallback.y = clamp(fallback.y, 80.0, ARENA_SIZE.y - 80.0)
		if not _point_inside_wall(fallback, 38.0):
			return fallback

	return Vector2(ARENA_SIZE.x * 0.5, ARENA_SIZE.y * 0.5)


func _find_guaranteed_pickup_point(player_spawn: Vector2) -> Vector2:
	var candidate_offsets: Array[Vector2] = [
		Vector2(220.0, 0.0),
		Vector2(180.0, -120.0),
		Vector2(180.0, 120.0),
		Vector2(260.0, -40.0),
		Vector2(260.0, 40.0),
	]

	for offset: Vector2 in candidate_offsets:
		var point: Vector2 = player_spawn + offset
		point.x = clamp(point.x, 170.0, ARENA_SIZE.x - 130.0)
		point.y = clamp(point.y, 80.0, ARENA_SIZE.y - 80.0)
		if not _point_inside_wall(point, 40.0):
			return point

	return _find_pickup_spawn_point(player_spawn, [])


func _generate_walls(level: int, player_spawn: Vector2) -> void:
	var wall_count: int = mini(3 + level, 8)
	for _index in range(wall_count):
		var attempt := 0
		while attempt < 20:
			var size := Vector2(_rng.randf_range(110.0, 210.0), _rng.randf_range(26.0, 48.0))
			if _rng.randf() < 0.35:
				size = Vector2(_rng.randf_range(28.0, 48.0), _rng.randf_range(120.0, 240.0))
			var center := Vector2(
				_rng.randf_range(170.0, ARENA_SIZE.x - 170.0),
				_rng.randf_range(110.0, ARENA_SIZE.y - 110.0)
			)
			var rect := Rect2(center - size * 0.5, size)
			if _rect_overlaps_reserved(rect, player_spawn):
				attempt += 1
				continue
			_create_wall(rect)
			break


func _rect_overlaps_reserved(rect: Rect2, player_spawn: Vector2) -> bool:
	var player_safe_zone := Rect2(player_spawn - Vector2(90.0, 90.0), Vector2(180.0, 180.0))
	var arena_center := Rect2(Vector2(ARENA_SIZE.x * 0.5 - 90.0, ARENA_SIZE.y * 0.5 - 90.0), Vector2(180.0, 180.0))
	if rect.intersects(player_safe_zone) or rect.intersects(arena_center):
		return true
	for existing in _wall_rects:
		if rect.grow(24.0).intersects(existing):
			return true
	return false


func _create_wall(rect: Rect2) -> void:
	_wall_rects.append(rect)

	var wall := StaticBody2D.new()
	wall.position = rect.get_center()
	wall.collision_layer = WALL_LAYER
	wall.add_to_group("wall")

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	wall.add_child(shape)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
	])
	visual.color = Color("#34495e")
	wall.add_child(visual)

	_wall_container.add_child(wall)


func _find_spawn_point(player_spawn: Vector2, min_distance: float) -> Vector2:
	for _attempt in range(40):
		var point := Vector2(
			_rng.randf_range(180.0, ARENA_SIZE.x - 120.0),
			_rng.randf_range(70.0, ARENA_SIZE.y - 70.0)
		)
		if point.distance_to(player_spawn) < min_distance:
			continue
		if _point_inside_wall(point, 30.0):
			continue
		return point
	return Vector2(ARENA_SIZE.x - 120.0, ARENA_SIZE.y * 0.5)


func _point_inside_wall(point: Vector2, padding: float) -> bool:
	for rect in _wall_rects:
		if rect.grow(padding).has_point(point):
			return true
	return false
