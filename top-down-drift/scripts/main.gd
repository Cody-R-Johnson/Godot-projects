extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _speed_label: Label      = $HUD/SpeedLabel
@onready var _drift_label: Label      = $HUD/DriftLabel


func _process(_delta: float) -> void:
	# Rough px/s → "game km/h" conversion (tweak to taste)
	var kmh := int(_player.velocity.length() * 0.12)
	_speed_label.text = "%d km/h" % kmh

	# Drift indicator
	_drift_label.visible = _player.is_drifting
