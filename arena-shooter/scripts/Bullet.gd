extends Area2D

## Bullet.gd — Shared projectile for player shots and enemy shots.

@export var lifetime: float = 1.5

var _dir: Vector2 = Vector2.RIGHT
var _age: float = 0.0
var _speed: float = 680.0
var _damage: int = 1
var _team: String = "player"
var _is_boss_shot: bool = false
var _shot_style: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func init(dir: Vector2, team: String, speed: float = 680.0, damage: int = 1, is_boss_shot: bool = false, shot_style: String = "") -> void:
	_dir = dir.normalized()
	_team = team
	_speed = speed
	_damage = damage
	_is_boss_shot = is_boss_shot
	_shot_style = shot_style

	if _team == "player":
		collision_layer = 4
		collision_mask = 2 | 8
	else:
		collision_layer = 16
		collision_mask = 1 | 8


func _process(delta: float) -> void:
	position += _dir * _speed * delta
	_age += delta

	if _age >= lifetime:
		queue_free()
		return

	modulate.a = clamp(1.0 - (_age / lifetime - 0.66) * 3.0, 0.2, 1.0)
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		queue_free()
		return

	if _team == "player" and body.is_in_group("enemy"):
		body.take_damage(_damage)
		queue_free()
		return

	if _team == "enemy" and body.is_in_group("player"):
		body.take_damage(_damage)
		queue_free()


func _draw() -> void:
	var glow := Color(1.0, 0.55, 0.05, 0.30)
	var shell := Color("#f39c12")
	var core := Color("#fffaf0")
	var radius := 4.5

	if _team == "enemy":
		glow = Color(1.0, 0.18, 0.2, 0.35)
		shell = Color("#ff5c5c")
		core = Color("#ffd0d0")
	if _is_boss_shot:
		glow = Color(0.7, 0.25, 1.0, 0.42)
		shell = Color("#c56cf0")
		core = Color("#f8e7ff")
		radius = 6.0
	elif _shot_style == "enemy_sniper":
		glow = Color(0.2, 0.85, 1.0, 0.35)
		shell = Color("#39d4f5")
		core = Color("#e8fcff")
		radius = 4.0
	elif _shot_style == "enemy_rpg":
		glow = Color(1.0, 0.56, 0.12, 0.45)
		shell = Color("#ff8f1f")
		core = Color("#fff2d6")
		radius = 7.2

	draw_circle(Vector2.ZERO, radius * 1.2, glow)
	draw_circle(Vector2.ZERO, radius, shell)
	draw_circle(Vector2.ZERO, radius * 0.4, core)

	draw_circle(Vector2.ZERO, radius + 3.0, glow)
	draw_circle(Vector2.ZERO, radius, shell)
	draw_circle(Vector2.ZERO, radius * 0.45, core)
