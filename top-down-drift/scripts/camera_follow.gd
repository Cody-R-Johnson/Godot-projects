extends Camera2D

## Smoothly follows a target node.  Assign [member target] in the Inspector
## or call [method set_target] at runtime.

@export var target: Node2D
@export var follow_speed: float = 6.0   # lerp weight – higher = tighter

# Optional: predictive offset so you see more road ahead
@export var look_ahead_distance: float = 80.0


func _ready() -> void:
	# If no target set in the Inspector, try the parent node
	if target == null and get_parent() is Node2D:
		target = get_parent() as Node2D


func _process(delta: float) -> void:
	if target == null:
		return

	var desired_pos := target.global_position

	# Shift the focus slightly in the direction the car is moving
	if target is CharacterBody2D:
		var vel: Vector2 = (target as CharacterBody2D).velocity
		if vel.length() > 10.0:
			desired_pos += vel.normalized() * look_ahead_distance

	global_position = global_position.lerp(desired_pos, follow_speed * delta)
