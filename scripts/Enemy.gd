extends CharacterBody2D

## Enemy.gd — Regular enemies and boss behavior with wall-aware movement and shooting.

signal shoot_requested(pos: Vector2, dir: Vector2, speed: float, is_boss: bool, damage: int, shot_style: String)
signal health_changed(current_health: int, max_health: int, is_boss: bool)
signal defeated(enemy: CharacterBody2D)

@export var move_speed: float = 120.0
@export var fire_interval: float = 1.25
@export var desired_distance: float = 260.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _target: CharacterBody2D
var _is_boss: bool = false
var _max_health: int = 3
var _health: int = 3
var _shoot_timer: float = 0.0
var _strafe_sign: float = 1.0
var _time_alive: float = 0.0
var _facing: Vector2 = Vector2.LEFT
var _radius: float = 16.0
var _enemy_type: String = "standard"
var _projectile_speed: float = 320.0
var _shot_damage: int = 1
var _shot_style: String = "enemy_normal"


func _ready() -> void:
	add_to_group("enemy")


func setup(target: CharacterBody2D, boss_mode: bool, level: int, difficulty_profile: Dictionary = {}, enemy_type: String = "standard") -> void:
	_target = target
	_is_boss = boss_mode
	_enemy_type = enemy_type
	_strafe_sign = -1.0 if randi() % 2 == 0 else 1.0

	var health_mult: float = difficulty_profile.get("health_mult", 1.0)
	var boss_health_mult: float = difficulty_profile.get("boss_health_mult", 1.0)
	var speed_mult: float = difficulty_profile.get("speed_mult", 1.0)
	var fire_interval_mult: float = difficulty_profile.get("fire_interval_mult", 1.0)

	if _is_boss:
		_max_health = maxi(8, int(round(20.0 * boss_health_mult)))
		_health = _max_health
		move_speed = (92.0 + level * 1.6) * speed_mult
		fire_interval = 0.65 * fire_interval_mult
		desired_distance = 320.0
		_radius = 30.0
		_projectile_speed = 440.0
		_shot_damage = 1
		_shot_style = "enemy_boss"
	else:
		match _enemy_type:
			"sniper":
				_max_health = maxi(1, int(round((1 + int(level / 4)) * health_mult)))
				_health = _max_health
				move_speed = (82.0 + level * 2.3) * speed_mult
				fire_interval = max(0.7, (2.25 - level * 0.04) * fire_interval_mult)
				desired_distance = 410.0
				_radius = 15.0
				_projectile_speed = 690.0
				_shot_damage = 1
				_shot_style = "enemy_sniper"
			"rpg":
				_max_health = maxi(1, int(round((3 + int(level / 4)) * health_mult)))
				_health = _max_health
				move_speed = (78.0 + level * 2.0) * speed_mult
				fire_interval = max(1.0, (2.6 - level * 0.05) * fire_interval_mult)
				desired_distance = 300.0
				_radius = 19.0
				_projectile_speed = 250.0
				_shot_damage = 2
				_shot_style = "enemy_rpg"
			_:
				var base_health: int = 2 + int(level / 3)
				_max_health = maxi(1, int(round(base_health * health_mult)))
				_health = _max_health
				move_speed = (105.0 + level * 4.0) * speed_mult
				fire_interval = max(0.52, (1.5 - level * 0.05) * fire_interval_mult)
				desired_distance = 220.0 + float(level % 3) * 18.0
				_radius = 16.0
				_projectile_speed = 320.0
				_shot_damage = 1
				_shot_style = "enemy_normal"

	var circle := CircleShape2D.new()
	circle.radius = _radius
	collision_shape.shape = circle
	_shoot_timer = randf_range(0.15, fire_interval)
	health_changed.emit(_health, _max_health, _is_boss)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_time_alive += delta
	var to_target := _target.global_position - global_position
	if to_target.length_squared() > 0.001:
		_facing = to_target.normalized()

	var move_dir := Vector2.ZERO
	var distance := to_target.length()
	if distance > desired_distance + 40.0:
		move_dir += _facing
	elif distance < desired_distance - 50.0:
		move_dir -= _facing

	var tangent := Vector2(-_facing.y, _facing.x)
	var strafe_speed := 1.1 if _is_boss else 1.7
	var strafe_weight := 1.0 if _is_boss else 0.7
	move_dir += tangent * sin(_time_alive * strafe_speed) * _strafe_sign * strafe_weight

	if move_dir != Vector2.ZERO:
		velocity = move_dir.normalized() * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)

	move_and_slide()

	var vp := get_viewport_rect().size
	position.x = clamp(position.x, _radius + 2.0, vp.x - (_radius + 2.0))
	position.y = clamp(position.y, _radius + 2.0, vp.y - (_radius + 2.0))

	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and _has_line_of_sight():
		_shoot()
		_shoot_timer = fire_interval

	queue_redraw()


func take_damage(amount: int = 1) -> void:
	_health = max(_health - amount, 0)
	health_changed.emit(_health, _max_health, _is_boss)
	if _health <= 0:
		defeated.emit(self)
		queue_free()
	else:
		var tween := create_tween()
		modulate = Color(1.4, 1.4, 1.4, 1.0)
		tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func get_health() -> int:
	return _health


func is_boss() -> bool:
	return _is_boss


func _shoot() -> void:
	var muzzle := global_position + _facing * (_radius + 10.0)
	if _is_boss:
		for angle in [-0.24, 0.0, 0.24]:
			shoot_requested.emit(muzzle, _facing.rotated(angle), _projectile_speed, true, _shot_damage, _shot_style)
	elif _enemy_type == "rpg":
		shoot_requested.emit(muzzle, _facing, _projectile_speed, false, _shot_damage, _shot_style)
	else:
		shoot_requested.emit(muzzle, _facing, _projectile_speed, false, _shot_damage, _shot_style)


func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, _target.global_position)
	query.exclude = [self]
	query.collision_mask = 1 | 8
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result.collider == _target


func _draw() -> void:
	var body_color := Color("#e74c3c")
	var core_color := Color("#c0392b")
	if _is_boss:
		body_color = Color("#8e44ad")
		core_color = Color("#5e3370")
	elif _enemy_type == "sniper":
		body_color = Color("#00bcd4")
		core_color = Color("#0c7d8a")
	elif _enemy_type == "rpg":
		body_color = Color("#f39c12")
		core_color = Color("#a96507")

	draw_circle(Vector2(4, 5), _radius, Color(0, 0, 0, 0.24))
	draw_circle(Vector2.ZERO, _radius, body_color)
	draw_circle(Vector2.ZERO, _radius * 0.62, core_color)
	draw_circle(Vector2(-_radius * 0.28, -_radius * 0.3), _radius * 0.18, Color(1, 1, 1, 0.35))
	var tip := _facing * (_radius + 12.0)
	draw_line(Vector2.ZERO, tip, Color("#ecf0f1"), 5.0 if _is_boss else (5.0 if _enemy_type == "rpg" else 4.0), false)
	draw_circle(tip, 4.0 if _is_boss else 3.0, Color("#bdc3c7"))

	if _enemy_type == "sniper" and not _is_boss:
		draw_line(Vector2.ZERO, tip * 0.9, Color(0.7, 0.95, 1.0, 0.45), 1.5, false)
	if _enemy_type == "rpg" and not _is_boss:
		draw_circle(tip * 0.88, 4.8, Color("#ffcf6a"))

	if _is_boss:
		var bar_width := 68.0
		var ratio := float(_health) / float(max(_max_health, 1))
		draw_rect(Rect2(Vector2(-bar_width * 0.5, -_radius - 18.0), Vector2(bar_width, 6.0)), Color(0.18, 0.12, 0.2, 0.9))
		draw_rect(Rect2(Vector2(-bar_width * 0.5, -_radius - 18.0), Vector2(bar_width * ratio, 6.0)), Color("#f39c12"))
