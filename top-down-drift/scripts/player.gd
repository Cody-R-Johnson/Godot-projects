extends CharacterBody2D

## ━━ Engine ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var acceleration: float  = 850.0   ## px/s² forward thrust
@export var brake_force: float   = 1300.0  ## px/s² braking
@export var max_speed: float     = 600.0   ## top speed px/s
@export var rolling_drag: float  = 0.60    ## velocity decay per second (0–1)

## ━━ Steering ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var steer_speed: float      = 2.6  ## rad/s (normal)
@export var drift_steer_mult: float = 1.8  ## extra rotation multiplier while drifting
@export var front_wheel_max_angle_deg: float = 30.0
@export var front_wheel_turn_speed: float = 14.0

## ━━ Traction ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Lateral slip is damped each frame:  lat_vel *= (1 - traction * delta)
## High → snappy grip.  Low → car keeps sliding sideways (drift).
## At 60 fps:  normal_traction 9.0 → ~99% removed/sec  (instant snap)
##             drift_traction  0.5 → ~40% removed/sec  (long, visible slide)
@export var normal_traction: float = 9.0
@export var drift_traction: float  = 0.5   ## keep this LOW for satisfying drift
@export var drift_min_speed: float = 90.0  ## px/s needed to enter drift

## ━━ Skid mark settings ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const SKID_MIN_LAT   := 25.0   ## lateral speed threshold before marks appear
const SKID_POINT_GAP := 6.0    ## world-distance between consecutive points
const SKID_MAX_PTS   := 200    ## truncate segment after this many points
@export var skid_fade_delay: float = 3.0
@export var skid_fade_duration: float = 2.5

## Rear-wheel offsets in local car space
## (car faces Vector2.UP so local +Y = rear, local ±X = sides)
const WHEEL_REAR_DIST  := 16.0
const WHEEL_SIDE_DIST  := 10.0

## ━━ Runtime state ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var is_drifting: bool = false

@onready var _smoke_l: CPUParticles2D = $SmokeLeft
@onready var _smoke_r: CPUParticles2D = $SmokeRight
@onready var _wheel_fl: Node2D = $FrontWheelLeft
@onready var _wheel_fr: Node2D = $FrontWheelRight

var _skid_root: Node2D   ## SkidMarks Node2D sibling in Main scene
var _left_line:  Line2D
var _right_line: Line2D
var _prev_left:  Vector2
var _prev_right: Vector2


func _ready() -> void:
	velocity = Vector2.ZERO
	_skid_root = get_parent().get_node_or_null("SkidMarks") as Node2D
	_start_new_skid_segment()


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("brake", "throttle")          # -1 brake / +1 gas
	var steer    := Input.get_axis("steer_left", "steer_right")  # -1 left / +1 right
	var drift    := Input.is_action_pressed("drift")
	_update_wheel_visuals(steer, delta)

	# ── Drift gate ──────────────────────────────────────────────────────────
	var was_drifting := is_drifting
	is_drifting = drift and velocity.length() >= drift_min_speed
	if is_drifting != was_drifting:
		_start_new_skid_segment()

	# ── Smoke particles ─────────────────────────────────────────────────────
	if _smoke_l:
		_smoke_l.emitting = is_drifting
	if _smoke_r:
		_smoke_r.emitting = is_drifting

	# ── Steering ────────────────────────────────────────────────────────────
	if velocity.length() > 20.0:
		var s_mult := drift_steer_mult if is_drifting else 1.0
		rotation += steer * steer_speed * s_mult * delta

	# ── Local axes ──────────────────────────────────────────────────────────
	var fwd   := Vector2.UP.rotated(rotation)     # toward front bumper
	var right := Vector2.RIGHT.rotated(rotation)  # toward right side

	# ── Thrust / Brake (along forward axis only) ─────────────────────────────
	if throttle > 0.0:
		velocity += fwd * acceleration * throttle * delta
	elif throttle < 0.0:
		velocity += fwd * brake_force * throttle * delta

	# ── Traction: dampen lateral slip each frame ─────────────────────────────
	# This is the core of the drift model.  Low drift_traction = long slide.
	var lat_slip := velocity.dot(right)
	var traction := drift_traction if is_drifting else normal_traction
	velocity -= right * lat_slip * traction * delta

	# ── Speed cap ───────────────────────────────────────────────────────────
	velocity = velocity.limit_length(max_speed)

	# ── Rolling drag (less drag while drifting preserves momentum) ───────────
	var drag_coeff := 0.28 if is_drifting else rolling_drag
	velocity *= 1.0 - drag_coeff * delta

	# ── Halt micro-creep at standstill ──────────────────────────────────────
	if velocity.length() < 4.0 and absf(throttle) < 0.05:
		velocity = Vector2.ZERO

	move_and_slide()

	# ── Draw skid marks after movement is resolved ──────────────────────────
	_update_skid_marks()


func _update_wheel_visuals(steer_input: float, delta: float) -> void:
	var target := deg_to_rad(front_wheel_max_angle_deg) * steer_input
	if _wheel_fl:
		_wheel_fl.rotation = lerp_angle(_wheel_fl.rotation, target, front_wheel_turn_speed * delta)
	if _wheel_fr:
		_wheel_fr.rotation = lerp_angle(_wheel_fr.rotation, target, front_wheel_turn_speed * delta)


# ── Skid mark drawing ────────────────────────────────────────────────────────

func _update_skid_marks() -> void:
	if _skid_root == null:
		return

	var fwd   := Vector2.UP.rotated(rotation)
	var right := Vector2.RIGHT.rotated(rotation)

	# Rear axle world positions (car faces fwd, so rear is -fwd direction)
	var rear_world := global_position - fwd * WHEEL_REAR_DIST
	var wl := rear_world - right * WHEEL_SIDE_DIST
	var wr := rear_world + right * WHEEL_SIDE_DIST

	if is_drifting and absf(velocity.dot(right)) > SKID_MIN_LAT:
		var needs_point := (_left_line.get_point_count() == 0
				or wl.distance_to(_prev_left) >= SKID_POINT_GAP)
		if needs_point:
			_left_line.add_point(wl)
			_right_line.add_point(wr)
			_prev_left  = wl
			_prev_right = wr
			if _left_line.get_point_count() >= SKID_MAX_PTS:
				_start_new_skid_segment()
	else:
		if _left_line.get_point_count() > 0:
			_start_new_skid_segment()


func _start_new_skid_segment() -> void:
	if _skid_root == null:
		return
	if _left_line and _left_line.get_point_count() > 1:
		_fade_and_cleanup_line(_left_line)
	if _right_line and _right_line.get_point_count() > 1:
		_fade_and_cleanup_line(_right_line)
	_left_line  = _make_skid_line()
	_right_line = _make_skid_line()
	_skid_root.add_child(_left_line)
	_skid_root.add_child(_right_line)
	_prev_left  = Vector2.ZERO
	_prev_right = Vector2.ZERO


func _make_skid_line() -> Line2D:
	var line := Line2D.new()
	line.width          = 4.5
	line.default_color  = Color(0.06, 0.06, 0.06, 0.80)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	line.joint_mode     = Line2D.LINE_JOINT_ROUND
	return line


func _fade_and_cleanup_line(line: Line2D) -> void:
	if line == null or not is_instance_valid(line):
		return
	var tween := create_tween()
	tween.tween_interval(skid_fade_delay)
	tween.tween_property(line, "modulate:a", 0.0, skid_fade_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)
