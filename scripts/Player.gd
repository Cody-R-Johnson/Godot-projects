extends CharacterBody2D

## Player.gd — WASD movement, shooting, and a three-hit life system.

signal bullet_fired(pos: Vector2, dir: Vector2)
signal hit_taken(remaining_hits: int)
signal died

@export var speed: float = 280.0
@export var gun_cooldown_sec: float = 0.18
@export var max_hits: int = 3
@export var invulnerability_sec: float = 0.7

var _facing: Vector2 = Vector2.RIGHT
var _can_shoot: bool = true
var _shoot_timer: float = 0.0
var _remaining_hits: int = max_hits
var _invulnerability_timer: float = 0.0
var _power_gun_timer: float = 0.0
var _controls_enabled: bool = true


func _ready() -> void:
	add_to_group("player")
	_remaining_hits = max_hits


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if _controls_enabled:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_facing_to_mouse()

	if dir != Vector2.ZERO:
		velocity = dir.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 8.0 * delta)

	move_and_slide()

	var vp := get_viewport_rect().size
	position.x = clamp(position.x, 18.0, vp.x - 18.0)
	position.y = clamp(position.y, 18.0, vp.y - 18.0)

	if not _can_shoot:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_can_shoot = true

	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta
		modulate.a = 0.45 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0

	if _power_gun_timer > 0.0:
		_power_gun_timer -= delta

	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _controls_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _can_shoot:
		_fire()
	elif event.is_action_pressed("shoot") and _can_shoot:
		_fire()


func _update_facing_to_mouse() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length_squared() > 0.001:
		_facing = to_mouse.normalized()


func _fire() -> void:
	var cooldown := gun_cooldown_sec
	if _power_gun_timer > 0.0:
		cooldown *= 0.55

	_can_shoot = false
	_shoot_timer = cooldown

	var muzzle := global_position + _facing * 26.0
	if _power_gun_timer > 0.0:
		for angle in [-0.16, 0.0, 0.16]:
			bullet_fired.emit(muzzle, _facing.rotated(angle))
	else:
		bullet_fired.emit(muzzle, _facing)


func reset_state(spawn_position: Vector2, restore_hits: bool = true) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_can_shoot = true
	_shoot_timer = 0.0
	_invulnerability_timer = 0.0
	_power_gun_timer = 0.0
	modulate = Color.WHITE
	if restore_hits:
		_remaining_hits = max_hits
	hit_taken.emit(_remaining_hits)


func take_damage(amount: int = 1) -> void:
	if _invulnerability_timer > 0.0:
		return

	_remaining_hits = max(_remaining_hits - amount, 0)
	_invulnerability_timer = invulnerability_sec
	hit_taken.emit(_remaining_hits)

	if _remaining_hits <= 0:
		died.emit()


func get_remaining_hits() -> int:
	return _remaining_hits


func restore_full_health() -> void:
	_remaining_hits = max_hits
	hit_taken.emit(_remaining_hits)


func grant_invincibility(duration_sec: float) -> void:
	_invulnerability_timer = max(_invulnerability_timer, duration_sec)


func grant_power_gun(duration_sec: float) -> void:
	_power_gun_timer = max(_power_gun_timer, duration_sec)


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not _controls_enabled:
		velocity = Vector2.ZERO


func _draw() -> void:
	draw_circle(Vector2(3, 4), 16, Color(0, 0, 0, 0.26))
	draw_circle(Vector2.ZERO, 16, Color("#2ecc71"))
	draw_circle(Vector2.ZERO, 10, Color("#27ae60"))
	draw_circle(Vector2(-5, -5), 4, Color(1, 1, 1, 0.42))
	var tip := _facing * 26.0
	draw_line(Vector2.ZERO, tip, Color("#bdc3c7"), 6.0, false)
	draw_circle(tip, 4.5, Color("#95a5a6"))
	if not _can_shoot and _shoot_timer > gun_cooldown_sec * 0.6:
		draw_circle(tip, 7.0, Color(1.0, 0.9, 0.3, 0.7))
