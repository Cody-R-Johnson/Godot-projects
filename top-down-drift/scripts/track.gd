extends Node2D

const TRACK_HALF_SIZE := 1500.0
const ROAD_WIDTH := 240.0
const WALL_THICKNESS := 26.0
const WALL_OFFSET := ROAD_WIDTH * 0.5 + WALL_THICKNESS * 0.5
const END_MARGIN := ROAD_WIDTH * 0.5 - 8.0

const ROAD_COLOR := Color(0.22, 0.22, 0.23, 1.0)
const WALL_COLOR := Color(0.62, 0.64, 0.68, 1.0)
const EDGE_COLOR := Color(0.96, 0.96, 0.90, 1.0)
const CENTER_COLOR := Color(0.97, 0.84, 0.22, 1.0)
const GRASS_COLOR := Color(0.16, 0.34, 0.16, 1.0)

const Z_BG := -2
const Z_ROAD := 0
const Z_MARK := 1
const Z_WALL := 2


func _ready() -> void:
	_build()


func _build() -> void:
	_build_background()
	_build_boundaries()
	_build_offtrack_physics()
	_build_simple_circuit()


func _build_background() -> void:
	_rect_poly(Vector2.ZERO, Vector2(3000, 3000), GRASS_COLOR, Z_BG)


func _build_boundaries() -> void:
	_wall(Vector2(-TRACK_HALF_SIZE, 0), Vector2(24, TRACK_HALF_SIZE * 2.0))
	_wall(Vector2(TRACK_HALF_SIZE, 0), Vector2(24, TRACK_HALF_SIZE * 2.0))
	_wall(Vector2(0, -TRACK_HALF_SIZE), Vector2(TRACK_HALF_SIZE * 2.0, 24))
	_wall(Vector2(0, TRACK_HALF_SIZE), Vector2(TRACK_HALF_SIZE * 2.0, 24))


func _build_offtrack_physics() -> void:
	_physics_zone("grass", Vector2.ZERO, Vector2(3000, 3000))


func _build_simple_circuit() -> void:
	var segments := [
		[Vector2(0, 900), Vector2(1800, ROAD_WIDTH), true],
		[Vector2(900, 0), Vector2(ROAD_WIDTH, 1800), false],
		[Vector2(0, -900), Vector2(1800, ROAD_WIDTH), true],
		[Vector2(-900, 0), Vector2(ROAD_WIDTH, 1800), false],
	]
	for segment in segments:
		_track_segment(segment[0], segment[1], segment[2])

	_corner(Vector2(900, 900), 0, 1)
	_corner(Vector2(900, -900), 1, 2)
	_corner(Vector2(-900, -900), 2, 3)
	_corner(Vector2(-900, 900), 3, 0)

	_gate(Vector2(-700, 900), Vector2(32, ROAD_WIDTH - 20.0), Color(0.12, 0.88, 0.38, 0.85), true)
	_gate(Vector2(700, 900), Vector2(32, ROAD_WIDTH - 20.0), Color(1.0, 0.36, 0.18, 0.85), false)


func _track_segment(pos: Vector2, size: Vector2, horizontal: bool) -> void:
	_road_rect(pos, size)
	_physics_zone("asphalt", pos, size)
	_add_track_markings(pos, size, horizontal)
	if horizontal:
		var wall_length := maxf(40.0, size.x - END_MARGIN * 2.0)
		_wall(pos + Vector2(0, -WALL_OFFSET), Vector2(wall_length, WALL_THICKNESS))
		_wall(pos + Vector2(0, WALL_OFFSET), Vector2(wall_length, WALL_THICKNESS))
	else:
		var wall_height := maxf(40.0, size.y - END_MARGIN * 2.0)
		_wall(pos + Vector2(-WALL_OFFSET, 0), Vector2(WALL_THICKNESS, wall_height))
		_wall(pos + Vector2(WALL_OFFSET, 0), Vector2(WALL_THICKNESS, wall_height))


func _corner(center: Vector2, from_dir: int, to_dir: int) -> void:
	var dir_vecs: Array[Vector2] = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
	var arrive: Vector2 = dir_vecs[from_dir]
	var depart: Vector2 = dir_vecs[to_dir]
	var pivot: Vector2 = center
	var outer_r := ROAD_WIDTH * 0.5
	var a_start: float = (-depart).angle() - PI * 0.5
	var a_end: float = (-arrive).angle() - PI * 0.5
	var sweep: float = fmod(a_end - a_start + TAU, TAU)
	if sweep > PI:
		sweep -= TAU

	var road_arc: PackedVector2Array = PackedVector2Array()
	var wall_inner_arc: PackedVector2Array = PackedVector2Array()
	var wall_outer_arc: PackedVector2Array = PackedVector2Array()
	var edge_arc: PackedVector2Array = PackedVector2Array()
	var center_arc: PackedVector2Array = PackedVector2Array()
	var arc_steps := 14
	for i in range(arc_steps + 1):
		var t := float(i) / float(arc_steps)
		var a := a_start + sweep * t
		var dir := Vector2(cos(a), sin(a))
		road_arc.append(pivot + dir * outer_r)
		wall_inner_arc.append(pivot + dir * outer_r)
		wall_outer_arc.append(pivot + dir * (outer_r + WALL_THICKNESS))
		edge_arc.append(pivot + dir * (outer_r - 10.0))
		center_arc.append(pivot + dir * (outer_r * 0.5))

	var road_poly := Polygon2D.new()
	var road_points := PackedVector2Array([pivot])
	road_points.append_array(road_arc)
	road_poly.polygon = road_points
	road_poly.color = ROAD_COLOR
	road_poly.z_index = Z_ROAD
	add_child(road_poly)

	var edge_line := Line2D.new()
	edge_line.width = 6.0
	edge_line.default_color = EDGE_COLOR
	edge_line.z_index = Z_MARK
	edge_line.points = edge_arc
	add_child(edge_line)

	var center_line := Line2D.new()
	center_line.width = 5.0
	center_line.default_color = CENTER_COLOR
	center_line.z_index = Z_MARK
	center_line.points = center_arc
	add_child(center_line)

	var wall_points := PackedVector2Array()
	wall_points.append_array(wall_outer_arc)
	for i in range(wall_inner_arc.size() - 1, -1, -1):
		wall_points.append(wall_inner_arc[i])

	var wall_body := StaticBody2D.new()
	wall_body.collision_layer = 2
	wall_body.collision_mask = 0
	wall_body.z_index = Z_WALL
	add_child(wall_body)

	var wall_shadow := Polygon2D.new()
	var shadow_points := PackedVector2Array()
	for p in wall_points:
		shadow_points.append(p + Vector2(8, 8))
	wall_shadow.polygon = shadow_points
	wall_shadow.color = Color(0.02, 0.02, 0.02, 0.34)
	wall_shadow.z_index = -1
	wall_body.add_child(wall_shadow)

	var wall_col := CollisionPolygon2D.new()
	wall_col.polygon = wall_points
	wall_body.add_child(wall_col)

	var wall_vis := Polygon2D.new()
	wall_vis.polygon = wall_points
	wall_vis.color = WALL_COLOR
	wall_body.add_child(wall_vis)

	_physics_zone("asphalt", center, Vector2(ROAD_WIDTH, ROAD_WIDTH))


func _add_track_markings(pos: Vector2, size: Vector2, horizontal: bool) -> void:
	if horizontal:
		_strip(pos + Vector2(0, -size.y * 0.5 + 10.0), Vector2(size.x, 6.0), EDGE_COLOR)
		_strip(pos + Vector2(0, size.y * 0.5 - 10.0), Vector2(size.x, 6.0), EDGE_COLOR)
		_dashed_center_line(pos, size.x - 80.0, true)
	else:
		_strip(pos + Vector2(-size.x * 0.5 + 10.0, 0), Vector2(6.0, size.y), EDGE_COLOR)
		_strip(pos + Vector2(size.x * 0.5 - 10.0, 0), Vector2(6.0, size.y), EDGE_COLOR)
		_dashed_center_line(pos, size.y - 80.0, false)


func _dashed_center_line(pos: Vector2, length: float, horizontal: bool) -> void:
	var dash := 70.0
	var gap := 40.0
	var offset := -length * 0.5
	while offset < length * 0.5:
		var segment_length := minf(dash, length * 0.5 - offset)
		if horizontal:
			_strip(pos + Vector2(offset + segment_length * 0.5, 0), Vector2(segment_length, 5.0), CENTER_COLOR)
		else:
			_strip(pos + Vector2(0, offset + segment_length * 0.5), Vector2(5.0, segment_length), CENTER_COLOR)
		offset += dash + gap


func _road_rect(pos: Vector2, size: Vector2) -> void:
	_rect_poly(pos, size, ROAD_COLOR, Z_ROAD)


func _strip(pos: Vector2, size: Vector2, color: Color) -> void:
	_rect_poly(pos, size, color, Z_MARK)


func _wall(pos: Vector2, size: Vector2, rot: float = 0.0) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = pos
	body.rotation = rot
	body.z_index = Z_WALL
	add_child(body)

	var shadow := _rect_poly_local(size + Vector2(12, 12), Color(0.02, 0.02, 0.02, 0.34), -1)
	shadow.position = Vector2(8, 8)
	body.add_child(shadow)

	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	shape_node.shape = rect_shape
	body.add_child(shape_node)

	body.add_child(_rect_poly_local(size, WALL_COLOR, 0))

	var highlight_size := Vector2(size.x, minf(size.y, 7.0))
	var highlight := _rect_poly_local(highlight_size, WALL_COLOR.lightened(0.22), 1)
	highlight.position = Vector2(0, -size.y * 0.5 + highlight_size.y * 0.5)
	body.add_child(highlight)


func _physics_zone(surface_name: String, pos: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.name = "%sZone" % surface_name.capitalize()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true
	add_child(area)

	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	shape_node.shape = rect_shape
	area.add_child(shape_node)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("set_surface_type"):
			body.set_surface_type(surface_name)
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body.has_method("clear_surface_type"):
			body.clear_surface_type(surface_name)
	)


func _gate(pos: Vector2, size: Vector2, color: Color, is_start: bool) -> void:
	_rect_poly(pos, size, color, Z_MARK + 1)

	var line := Line2D.new()
	line.width = 5.0
	line.default_color = color.lightened(0.20)
	line.closed = true
	line.z_index = Z_MARK + 2
	line.add_point(pos + Vector2(-size.x * 0.5, -size.y * 0.5))
	line.add_point(pos + Vector2(size.x * 0.5, -size.y * 0.5))
	line.add_point(pos + Vector2(size.x * 0.5, size.y * 0.5))
	line.add_point(pos + Vector2(-size.x * 0.5, size.y * 0.5))
	add_child(line)

	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true
	area.name = "StartGate" if is_start else "FinishGate"
	add_child(area)

	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	shape_node.shape = rect_shape
	area.add_child(shape_node)

	area.body_entered.connect(func(body: Node2D) -> void:
		if is_start and body.has_method("start_challenge_section"):
			body.start_challenge_section()
		elif not is_start and body.has_method("finish_challenge_section"):
			body.finish_challenge_section()
	)


func _rect_poly(pos: Vector2, size: Vector2, color: Color, z_layer: int) -> Polygon2D:
	var poly := _rect_poly_local(size, color, z_layer)
	poly.position = pos
	add_child(poly)
	return poly


func _rect_poly_local(size: Vector2, color: Color, z_layer: int) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	poly.color = color
	poly.z_index = z_layer
	return poly
