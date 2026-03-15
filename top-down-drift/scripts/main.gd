extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _speed_label: Label = $HUD/SpeedLabel
@onready var _drift_label: Label = $HUD/DriftLabel
@onready var _section_status_label: Label = $HUD/SectionStatusLabel
@onready var _timer_label: Label = $HUD/TimerLabel
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _combo_label: Label = $HUD/ComboLabel
@onready var _surface_label: Label = $HUD/SurfaceLabel
@onready var _result_label: Label = $HUD/ResultLabel

var _best_section_score: int = 0
var _best_section_time: float = 0.0
var _last_result_message: String = ""
var _result_flash_time: float = 0.0


func _ready() -> void:
	_player.section_started.connect(_on_section_started)
	_player.section_finished.connect(_on_section_finished)
	_player.surface_changed.connect(_on_surface_changed)


func _process(delta: float) -> void:
	var mph := int(_player.velocity.length() * 0.0372)
	_speed_label.text = "%d mph" % mph
	_drift_label.visible = _player.is_drifting

	if _player.section_active:
		_section_status_label.text = "Drift zone active"
		_timer_label.text = "Time %.2fs" % _player.section_elapsed
	else:
		_section_status_label.text = "Cross the green gate to start a scored run"
		_timer_label.text = "Best time %s" % (_format_time(_best_section_time) if _best_section_time > 0.0 else "--")

	_score_label.text = "Section %d   Total %d   Best %d" % [_player.section_score, _player.total_score, _best_section_score]
	_combo_label.text = "Combo x%d" % _player.combo
	_combo_label.visible = _player.combo > 1 or _player.section_active
	_surface_label.text = "Surface: %s" % _player.current_surface_name.capitalize()

	if _result_flash_time > 0.0:
		_result_flash_time -= delta
		_result_label.visible = true
		_result_label.text = _last_result_message
	else:
		_result_label.visible = false


func _on_section_started() -> void:
	_last_result_message = "Run started"
	_result_flash_time = 1.2


func _on_section_finished(score: int, elapsed: float, best_combo: int) -> void:
	var new_best_score := score > _best_section_score
	var new_best_time := _best_section_time <= 0.0 or elapsed < _best_section_time
	if new_best_score:
		_best_section_score = score
	if new_best_time:
		_best_section_time = elapsed
	var best_bits: Array[String] = []
	if new_best_score:
		best_bits.append("new best score")
	if new_best_time:
		best_bits.append("new best time")
	var suffix := ""
	if not best_bits.is_empty():
		suffix = " | %s" % ", ".join(best_bits)
	_last_result_message = "Run %d pts in %s | combo x%d%s" % [score, _format_time(elapsed), best_combo, suffix]
	_result_flash_time = 4.0


func _on_surface_changed(_surface_name: String) -> void:
	_result_flash_time = maxf(_result_flash_time, 0.5)


func _format_time(value: float) -> String:
	if value <= 0.0:
		return "--"
	return "%.2fs" % value
