extends Control

## PowerupIcon.gd — Small menu icon matching in-game pickup visuals.

@export_enum("heal", "invincible", "power_gun") var icon_kind: String = "heal"


func _ready() -> void:
	custom_minimum_size = Vector2(26.0, 26.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var main_color := Color("#2ecc71")
	var accent := Color("#a3f7bf")
	var shape_color := Color("#f2fff6")

	match icon_kind:
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

	draw_circle(center, 11.0, Color(main_color.r, main_color.g, main_color.b, 0.26))
	draw_circle(center, 8.5, main_color)
	draw_circle(center, 4.8, accent)

	match icon_kind:
		"heal":
			draw_rect(Rect2(center + Vector2(-1.3, -4.2), Vector2(2.6, 8.4)), shape_color)
			draw_rect(Rect2(center + Vector2(-4.2, -1.3), Vector2(8.4, 2.6)), shape_color)
		"invincible":
			var shield := PackedVector2Array([
				center + Vector2(0, -5),
				center + Vector2(4, -2),
				center + Vector2(3, 4),
				center + Vector2(0, 6),
				center + Vector2(-3, 4),
				center + Vector2(-4, -2),
			])
			draw_colored_polygon(shield, shape_color)
		"power_gun":
			var tri := PackedVector2Array([
				center + Vector2(-4, -3),
				center + Vector2(5, 0),
				center + Vector2(-4, 3),
			])
			draw_colored_polygon(tri, shape_color)
