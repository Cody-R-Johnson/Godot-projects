extends CharacterBody2D

signal section_started()
signal section_finished(score: int, elapsed: float, best_combo: int)
signal score_changed(total_score: int, section_score: int, combo: int)
signal surface_changed(surface_name: String)

## ━━ Engine ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var acceleration: float = 850.0
@export var brake_force: float = 1300.0
@export var max_speed: float = 600.0
@export var rolling_drag: float = 0.60

## ━━ Steering ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var steer_speed: float = 2.6
@export var drift_steer_mult: float = 1.8
@export var front_wheel_max_angle_deg: float = 30.0
@export var front_wheel_turn_speed: float = 14.0

## ━━ Traction ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var normal_traction: float = 9.0
@export var drift_traction: float = 0.5
@export var drift_min_speed: float = 90.0

## ━━ Scoring ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
@export var score_min_speed: float = 110.0
@export var score_min_lateral_slip: float = 28.0
@export var score_rate: float = 12.0
@export var combo_grace_time: float = 0.55

## ━━ Skid mark settings ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const SKID_MIN_LAT := 25.0
const SKID_POINT_GAP := 6.0
const SKID_MAX_PTS := 200
@export var skid_fade_delay: float = 3.0
@export var skid_fade_duration: float = 2.5

## Rear wheel offsets in local car space
const WHEEL_REAR_DIST := 16.0
const WHEEL_SIDE_DIST := 10.0

const AUDIO_MIX_RATE := 22050.0
const SURFACE_PRIORITY := ["oil", "paint", "dirt", "asphalt", "grass"]
const SURFACE_PRESETS := {
	"asphalt": {
		"accel_mult": 1.0,
		"speed_mult": 1.0,
		"normal_traction_mult": 1.0,
		"drift_traction_mult": 1.0,
		"drag_mult": 1.0,
		"skid": true,
		"squeal_mult": 1.0,
		"smoke_color": Color(0.86, 0.86, 0.86, 0.52)
	},
	"paint": {
		"accel_mult": 1.0,
		"speed_mult": 1.0,
		"normal_traction_mult": 0.88,
		"drift_traction_mult": 0.80,
		"drag_mult": 0.95,
		"skid": true,
		"squeal_mult": 1.15,
		"smoke_color": Color(0.90, 0.90, 0.95, 0.46)
	},
	"dirt": {
		"accel_mult": 0.82,
		"speed_mult": 0.82,
		"normal_traction_mult": 0.74,
		"drift_traction_mult": 0.92,
		"drag_mult": 1.25,
		"skid": false,
		"squeal_mult": 0.25,
		"smoke_color": Color(0.67, 0.52, 0.36, 0.58)
	},
	"grass": {
		"accel_mult": 0.60,
		"speed_mult": 0.58,
		"normal_traction_mult": 0.58,
		"drift_traction_mult": 1.10,
		"drag_mult": 1.95,
		"skid": false,
		"squeal_mult": 0.08,
		"smoke_color": Color(0.57, 0.71, 0.45, 0.45)
	},
	"oil": {
		"accel_mult": 1.0,
		"speed_mult": 1.06,
		"normal_traction_mult": 0.35,
		"drift_traction_mult": 0.32,
		"drag_mult": 0.72,
		"skid": true,
		"squeal_mult": 0.65,
		"smoke_color": Color(0.45, 0.45, 0.50, 0.35)
	}
}

var is_drifting: bool = false
var section_active: bool = false
var current_surface_name: String = "asphalt"
var total_score: int = 0
var section_score: int = 0
var section_elapsed: float = 0.0
var combo: int = 1
var best_combo_this_run: int = 1

@onready var _smoke_l: CPUParticles2D = $SmokeLeft
@onready var _smoke_r: CPUParticles2D = $SmokeRight
@onready var _wheel_fl: Node2D = $FrontWheelLeft
@onready var _wheel_fr: Node2D = $FrontWheelRight
@onready var _engine_audio: AudioStreamPlayer = $EngineAudio
@onready var _tire_audio: AudioStreamPlayer = $TireAudio
@onready var _impact_audio: AudioStreamPlayer = $ImpactAudio

var _surface_counts: Dictionary = {}
var _skid_root: Node2D
var _left_line: Line2D
var _right_line: Line2D
var _prev_left: Vector2
var _prev_right: Vector2
var _score_bank: float = 0.0
var _combo_grace_left: float = 0.0
var _last_speed: float = 0.0
var _last_throttle: float = 0.0
var _last_steer: float = 0.0
var _last_lateral_slip: float = 0.0
var _impact_pulse: float = 0.0

var _engine_playback: AudioStreamGeneratorPlayback
var _tire_playback: AudioStreamGeneratorPlayback
var _impact_playback: AudioStreamGeneratorPlayback
var _engine_phase_1: float = 0.0
var _engine_phase_2: float = 0.0
var _engine_phase_3: float = 0.0
var _tire_phase_1: float = 0.0
var _tire_phase_2: float = 0.0
var _tire_grain_state: float = 0.0
var _tire_lowpass_state: float = 0.0


func _ready() -> void:
	velocity = Vector2.ZERO
	add_to_group("player")
	_skid_root = get_parent().get_node_or_null("SkidMarks") as Node2D
	_start_new_skid_segment()
	_setup_audio()
	_apply_surface_visuals()


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("brake", "throttle")
	var steer := Input.get_axis("steer_left", "steer_right")
	var drift := Input.is_action_pressed("drift")
	var surface := SURFACE_PRESETS[current_surface_name] as Dictionary
	var accel_mult := float(surface["accel_mult"])
	var speed_mult := float(surface["speed_mult"])
	var normal_traction_mult := float(surface["normal_traction_mult"])
	var drift_traction_mult := float(surface["drift_traction_mult"])
	var drag_mult := float(surface["drag_mult"])

	_last_throttle = throttle
	_last_steer = steer
	if section_active:
		section_elapsed += delta

	_update_wheel_visuals(steer, delta)

	var was_drifting := is_drifting
	is_drifting = drift and velocity.length() >= drift_min_speed
	if is_drifting != was_drifting:
		_start_new_skid_segment()

	if _smoke_l:
		_smoke_l.emitting = is_drifting
	if _smoke_r:
		_smoke_r.emitting = is_drifting

	if velocity.length() > 20.0:
		var steering_mult := drift_steer_mult if is_drifting else 1.0
		rotation += steer * steer_speed * steering_mult * delta

	var fwd := Vector2.UP.rotated(rotation)
	var right := Vector2.RIGHT.rotated(rotation)

	if throttle > 0.0:
		velocity += fwd * acceleration * accel_mult * throttle * delta
	elif throttle < 0.0:
		velocity += fwd * brake_force * throttle * delta

	var lateral_slip := velocity.dot(right)
	_last_lateral_slip = absf(lateral_slip)
	var traction := drift_traction * drift_traction_mult if is_drifting else normal_traction * normal_traction_mult
	velocity -= right * lateral_slip * traction * delta

	velocity = velocity.limit_length(max_speed * speed_mult)

	var drag_coeff := (0.28 if is_drifting else rolling_drag) * drag_mult
	velocity *= 1.0 - drag_coeff * delta

	if velocity.length() < 4.0 and absf(throttle) < 0.05:
		velocity = Vector2.ZERO

	var pre_move_speed := velocity.length()
	move_and_slide()
	_handle_collisions(pre_move_speed)

	_last_speed = velocity.length()
	_update_scoring(delta)
	_update_skid_marks()


func _process(_delta: float) -> void:
	_fill_audio_buffers()


func start_challenge_section() -> void:
	section_active = true
	section_score = 0
	section_elapsed = 0.0
	combo = 1
	best_combo_this_run = 1
	_score_bank = 0.0
	_combo_grace_left = combo_grace_time
	score_changed.emit(total_score, section_score, combo)
	section_started.emit()


func finish_challenge_section() -> void:
	if not section_active:
		return
	section_active = false
	section_finished.emit(section_score, section_elapsed, best_combo_this_run)
	_break_combo(false)


func set_surface_type(surface_name: String) -> void:
	_surface_counts[surface_name] = int(_surface_counts.get(surface_name, 0)) + 1
	_refresh_surface_type()


func clear_surface_type(surface_name: String) -> void:
	if not _surface_counts.has(surface_name):
		return
	_surface_counts[surface_name] = maxi(int(_surface_counts[surface_name]) - 1, 0)
	if int(_surface_counts[surface_name]) == 0:
		_surface_counts.erase(surface_name)
	_refresh_surface_type()


func _refresh_surface_type() -> void:
	var new_surface := "asphalt"
	for surface_name in SURFACE_PRIORITY:
		if int(_surface_counts.get(surface_name, 0)) > 0:
			new_surface = surface_name
			break
	if new_surface == current_surface_name:
		return
	current_surface_name = new_surface
	_apply_surface_visuals()
	surface_changed.emit(current_surface_name)


func _apply_surface_visuals() -> void:
	var surface := SURFACE_PRESETS[current_surface_name] as Dictionary
	var smoke_color := surface["smoke_color"] as Color
	if _smoke_l:
		_smoke_l.color = smoke_color
	if _smoke_r:
		_smoke_r.color = smoke_color


func _update_scoring(delta: float) -> void:
	if not section_active:
		return

	var valid_drift := is_drifting \
		and absf(_last_steer) >= 0.2 \
		and _last_speed >= score_min_speed \
		and _last_lateral_slip >= score_min_lateral_slip
	if valid_drift:
		_combo_grace_left = combo_grace_time
		combo = mini(8, 1 + int(section_elapsed * 0.35) + int(_last_lateral_slip / 60.0))
		best_combo_this_run = maxi(best_combo_this_run, combo)
		var gain := ((_last_speed / 65.0) + (_last_lateral_slip / 20.0)) * float(combo) * score_rate * delta
		_score_bank += gain
		var whole_points := int(_score_bank)
		if whole_points > 0:
			_score_bank -= float(whole_points)
			section_score += whole_points
			total_score += whole_points
			score_changed.emit(total_score, section_score, combo)
	else:
		_score_bank = 0.0
		_combo_grace_left -= delta
		if _combo_grace_left <= 0.0:
			_break_combo(true)


func _break_combo(emit_update: bool = true) -> void:
	combo = 1
	_combo_grace_left = 0.0
	if emit_update:
		score_changed.emit(total_score, section_score, combo)


func _handle_collisions(pre_move_speed: float) -> void:
	if get_slide_collision_count() == 0:
		return
	if pre_move_speed < 140.0:
		return
	_break_combo(true)
	_impact_pulse = maxf(_impact_pulse, clampf(pre_move_speed / 500.0, 0.0, 1.0))


func _update_wheel_visuals(steer_input: float, delta: float) -> void:
	var target := deg_to_rad(front_wheel_max_angle_deg) * steer_input
	if _wheel_fl:
		_wheel_fl.rotation = lerp_angle(_wheel_fl.rotation, target, front_wheel_turn_speed * delta)
	if _wheel_fr:
		_wheel_fr.rotation = lerp_angle(_wheel_fr.rotation, target, front_wheel_turn_speed * delta)


func _update_skid_marks() -> void:
	if _skid_root == null:
		return
	var surface := SURFACE_PRESETS[current_surface_name] as Dictionary
	if not bool(surface["skid"]):
		if _left_line and _left_line.get_point_count() > 0:
			_start_new_skid_segment()
		return

	var fwd := Vector2.UP.rotated(rotation)
	var right := Vector2.RIGHT.rotated(rotation)
	var rear_world := global_position - fwd * WHEEL_REAR_DIST
	var wl := rear_world - right * WHEEL_SIDE_DIST
	var wr := rear_world + right * WHEEL_SIDE_DIST

	if is_drifting and absf(velocity.dot(right)) > SKID_MIN_LAT:
		var needs_point := _left_line.get_point_count() == 0 or wl.distance_to(_prev_left) >= SKID_POINT_GAP
		if needs_point:
			_left_line.add_point(wl)
			_right_line.add_point(wr)
			_prev_left = wl
			_prev_right = wr
			if _left_line.get_point_count() >= SKID_MAX_PTS:
				_start_new_skid_segment()
	elif _left_line.get_point_count() > 0:
		_start_new_skid_segment()


func _start_new_skid_segment() -> void:
	if _skid_root == null:
		return
	if _left_line and _left_line.get_point_count() > 1:
		_fade_and_cleanup_line(_left_line)
	if _right_line and _right_line.get_point_count() > 1:
		_fade_and_cleanup_line(_right_line)
	_left_line = _make_skid_line()
	_right_line = _make_skid_line()
	_skid_root.add_child(_left_line)
	_skid_root.add_child(_right_line)
	_prev_left = Vector2.ZERO
	_prev_right = Vector2.ZERO


func _make_skid_line() -> Line2D:
	var line := Line2D.new()
	line.width = 4.5
	line.default_color = Color(0.06, 0.06, 0.06, 0.80)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
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


func _setup_audio() -> void:
	_engine_playback = _configure_audio_player(_engine_audio)
	_tire_playback = _configure_audio_player(_tire_audio)
	_impact_playback = _configure_audio_player(_impact_audio)


func _configure_audio_player(player: AudioStreamPlayer) -> AudioStreamGeneratorPlayback:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = AUDIO_MIX_RATE
	stream.buffer_length = 0.12
	player.stream = stream
	player.play()
	return player.get_stream_playback() as AudioStreamGeneratorPlayback


func _fill_audio_buffers() -> void:
	_fill_engine_audio()
	_fill_tire_audio()
	_fill_impact_audio()


func _fill_engine_audio() -> void:
	if _engine_playback == null:
		return
	var load := clampf((_last_speed / max_speed) * 0.75 + maxf(_last_throttle, 0.0) * 0.45, 0.0, 1.0)
	var target_freq := 28.0 + (_last_speed * 0.12) + maxf(_last_throttle, 0.0) * 18.0
	var loudness := clampf(0.07 + load * 0.34, 0.05, 0.42)
	_engine_audio.volume_db = linear_to_db(maxf(0.01, loudness)) - 13.0
	var frames := _engine_playback.get_frames_available()
	for _i in range(frames):
		_engine_phase_1 = wrapf(_engine_phase_1 + TAU * target_freq / AUDIO_MIX_RATE, 0.0, TAU)
		_engine_phase_2 = wrapf(_engine_phase_2 + TAU * target_freq * 1.02 / AUDIO_MIX_RATE, 0.0, TAU)
		_engine_phase_3 = wrapf(_engine_phase_3 + TAU * target_freq * 2.01 / AUDIO_MIX_RATE, 0.0, TAU)
		var fundamental := sin(_engine_phase_1)
		var pulse := signf(sin(_engine_phase_2)) * 0.11
		var upper := sin(_engine_phase_3) * 0.045
		var sample := fundamental * 0.15 + pulse + upper
		sample *= 0.8 + 0.2 * sin(_engine_phase_1 * 0.25)
		_engine_playback.push_frame(Vector2(sample, sample))


func _fill_tire_audio() -> void:
	if _tire_playback == null:
		return
	_tire_audio.volume_db = -80.0
	var frames := _tire_playback.get_frames_available()
	for _i in range(frames):
		_tire_playback.push_frame(Vector2.ZERO)


func _fill_impact_audio() -> void:
	if _impact_playback == null:
		return
	var frames := _impact_playback.get_frames_available()
	for _i in range(frames):
		var sample := 0.0
		if _impact_pulse > 0.001:
			sample = (randf() * 2.0 - 1.0) * _impact_pulse * 0.35
			_impact_pulse = maxf(0.0, _impact_pulse - 0.0025)
		_impact_playback.push_frame(Vector2(sample, sample))
	_impact_audio.volume_db = linear_to_db(maxf(0.01, _impact_pulse + 0.01)) - 6.0 if _impact_pulse > 0.01 else -80.0
