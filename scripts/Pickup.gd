extends Area2D

## Pickup.gd — Collectible power-up item used by level spawner.

signal picked(kind: String, pickup: Area2D)

@export_enum("heal", "invincible", "power_gun") var pickup_kind: String = "heal"

var _time_alive: float = 0.0
var _collecting: bool = false
var _collect_timer: float = 0.0


func _ready() -> void:
	visible = true
	scale = Vector2.ONE
	modulate = Color.WHITE
	z_index = 30
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_time_alive += delta
	if _collecting:
		_collect_timer += delta
		if _collect_timer >= 0.3:
			queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _collecting:
		_collecting = true
		_collect_timer = 0.0
		monitoring = false
		collision_mask = 0
		picked.emit(pickup_kind, self)

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.18)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.28)


func _draw() -> void:
	if _collecting:
		_draw_collect_burst()
		return

	var bob := sin(_time_alive * 4.0) * 2.0
	var center := Vector2(0.0, bob)
	var glow := Color(1, 1, 1, 0.25)
	var main_color := Color("#2ecc71")
	var accent := Color("#a3f7bf")
	var shape_color := Color.WHITE
	var spin := _time_alive * 2.4

	match pickup_kind:
		"heal":
			main_color = Color("#2ecc71")
			accent = Color("#a3f7bf")
			shape_color = Color("#f2fff6")
		"invincible":
			main_color = Color("#f1c40f")
			accent = Color("#fff4a8")
			shape_color = Color("#fff8ce")
		"power_gun":
			main_color = Color("#3498db")
			accent = Color("#b8e3ff")
			shape_color = Color("#eaf6ff")

	draw_arc(center, 18.0, spin, spin + TAU * 0.8, 22, Color(main_color.r, main_color.g, main_color.b, 0.55), 2.2)
	draw_arc(center, 22.0, -spin * 0.85, -spin * 0.85 + TAU * 0.65, 22, Color(accent.r, accent.g, accent.b, 0.45), 1.8)
	draw_circle(center, 16.0, glow)
	draw_circle(center, 11.0, main_color)
	draw_circle(center, 6.0, accent)
	draw_circle(center + Vector2(-3.0, -4.0), 2.5, Color(1, 1, 1, 0.5))

	match pickup_kind:
		"heal":
			draw_rect(Rect2(center + Vector2(-1.5, -6.0), Vector2(3.0, 12.0)), shape_color)
			draw_rect(Rect2(center + Vector2(-6.0, -1.5), Vector2(12.0, 3.0)), shape_color)
		"invincible":
			var shield := PackedVector2Array()
			for point in [Vector2(0, -7), Vector2(6, -3), Vector2(4, 5), Vector2(0, 8), Vector2(-4, 5), Vector2(-6, -3)]:
				shield.append(center + point.rotated(spin * 0.25))
			draw_colored_polygon(shield, shape_color)
		"power_gun":
			var tri := PackedVector2Array()
			for point in [Vector2(-5, -4), Vector2(7, 0), Vector2(-5, 4)]:
				tri.append(center + point.rotated(spin * 0.45))
			draw_colored_polygon(tri, shape_color)


func _draw_collect_burst() -> void:
	var t: float = clampf(_collect_timer / 0.3, 0.0, 1.0)
	var burst_radius: float = lerpf(6.0, 34.0, t)
	var alpha: float = 1.0 - t
	var base: Color = Color("#2ecc71")

	match pickup_kind:
		"invincible":
			base = Color("#f1c40f")
		"power_gun":
			base = Color("#3498db")

	draw_circle(Vector2.ZERO, burst_radius * 0.45, Color(base.r, base.g, base.b, 0.28 * alpha))
	draw_arc(Vector2.ZERO, burst_radius, 0.0, TAU, 40, Color(base.r, base.g, base.b, 0.95 * alpha), 2.6)

	for idx in range(10):
		var ang: float = TAU * float(idx) / 10.0 + _time_alive * 6.0
		var p1: Vector2 = Vector2(cos(ang), sin(ang)) * (burst_radius - 7.0)
		var p2: Vector2 = Vector2(cos(ang), sin(ang)) * (burst_radius + 5.0)
		draw_line(p1, p2, Color(1, 1, 1, 0.75 * alpha), 1.8)
