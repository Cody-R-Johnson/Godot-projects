extends Node2D
## Builds the track geometry at runtime: outer walls, obstacles, and cones.
## All walls are placed on collision layer 2 so the Player (mask=2) hits them.

const TRACK_HALF_SIZE := 1500.0

func _ready() -> void:
	_build()


func _build() -> void:
	# ── Outer boundary walls ──────────────────────────────────────────────
	_wall(Vector2(-TRACK_HALF_SIZE, 0), Vector2(24, TRACK_HALF_SIZE * 2.0), Color(0.55, 0.55, 0.60))  # left
	_wall(Vector2( TRACK_HALF_SIZE, 0), Vector2(24, TRACK_HALF_SIZE * 2.0), Color(0.55, 0.55, 0.60))  # right
	_wall(Vector2(0, -TRACK_HALF_SIZE), Vector2(TRACK_HALF_SIZE * 2.0, 24), Color(0.55, 0.55, 0.60))  # top
	_wall(Vector2(0,  TRACK_HALF_SIZE), Vector2(TRACK_HALF_SIZE * 2.0, 24), Color(0.55, 0.55, 0.60))  # bottom

	# ── Centre island ─────────────────────────────────────────────────────
	_wall(Vector2(0, 0), Vector2(280, 280), Color(0.35, 0.20, 0.12))

	# ── Corner pillars ────────────────────────────────────────────────────
	for p: Vector2 in [Vector2(-900, -900), Vector2(900, -900),
						Vector2(-900,  900), Vector2(900,  900)]:
		_wall(p, Vector2(140, 140), Color(0.30, 0.30, 0.36))

	# ── Chicane barriers (upper half) ─────────────────────────────────────
	_wall(Vector2(-420, -560), Vector2(540, 30), Color(0.50, 0.18, 0.18))
	_wall(Vector2( 420, -340), Vector2(540, 30), Color(0.50, 0.18, 0.18))

	# ── Chicane barriers (lower half, mirrored) ───────────────────────────
	_wall(Vector2( 420,  560), Vector2(540, 30), Color(0.50, 0.18, 0.18))
	_wall(Vector2(-420,  340), Vector2(540, 30), Color(0.50, 0.18, 0.18))

	# ── Side alcove blockers (narrow vertical pillars left & right) ───────
	_wall(Vector2(-1080, 0), Vector2(32, 380), Color(0.30, 0.30, 0.36))
	_wall(Vector2( 1080, 0), Vector2(32, 380), Color(0.30, 0.30, 0.36))

	# ── Slalom cones (top corridor) ───────────────────────────────────────
	var cone_color := Color(1.0, 0.42, 0.0)
	var top_xs := [-460, -230, 0, 230, 460, -345, -115, 115, 345]
	var top_ys := [-1160, -1080, -1160, -1080, -1160, -1260, -1260, -1260, -1260]
	for i: int in range(top_xs.size()):
		_wall(Vector2(top_xs[i], top_ys[i]), Vector2(26, 26), cone_color)

	# ── Slalom cones (bottom corridor) ────────────────────────────────────
	var bot_xs := [-460, -230, 0, 230, 460, -345, -115, 115, 345]
	var bot_ys := [1160, 1080, 1160, 1080, 1160, 1260, 1260, 1260, 1260]
	for i: int in range(bot_xs.size()):
		_wall(Vector2(bot_xs[i], bot_ys[i]), Vector2(26, 26), cone_color)


## Creates a StaticBody2D block at `pos` with the given `size` and `color`.
func _wall(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask  = 0
	body.position        = pos
	add_child(body)

	var shape_node := CollisionShape2D.new()
	var rect       := RectangleShape2D.new()
	rect.size       = size
	shape_node.shape = rect
	body.add_child(shape_node)

	var vis         := ColorRect.new()
	vis.size         = size
	vis.position     = -size * 0.5   # centre the rect on the body origin
	vis.color        = color
	body.add_child(vis)
