extends CharacterBody2D


class RopePoint:
	var position = Vector2.ZERO
	var normal = Vector2.ZERO
	func _init(pos: Vector2, nor: Vector2):
		position = pos
		normal = nor
	func is_finished(gl_pos: Vector2):
		return (gl_pos - position).dot(normal) < 0.0


var now_hook_point = RopePoint.new(Vector2.ZERO, Vector2.ZERO)
var points_stack = []
var now_lenght = 40.0

var gravity = 980.0
var gravity_dir = Vector2.DOWN

var old_global_position = Vector2.ZERO
var debug_points = []

var e_all = 0.0
var e_kin = 0.0
var e_pot = 0.0

func _draw():
	draw_line(Vector2.ZERO, now_hook_point.position - global_position, Color.AQUA, 10.0)
	var last_point = now_hook_point.position
	var debug_line = []
	debug_line.append_array(points_stack)
	debug_line.reverse()
	for i in debug_line:
		if i is RopePoint:
			draw_line(last_point - global_position, i.position - global_position, Color.AQUA, 10.0)
			last_point = i.position
	for i in debug_points:
		draw_circle(i - global_position, 10.0, Color.BROWN)

func change_hook_point(new_hook_point: RopePoint, lenght = -1.0):
	now_hook_point = new_hook_point
	if lenght <= 0.0:
		now_lenght = (global_position - new_hook_point.position).length()
	e_pot = (now_lenght - (gravity_dir.dot(global_position) - gravity_dir.dot(now_hook_point.position))) * gravity
	e_kin = pow((global_position - new_hook_point.position).rotated(PI / 2).normalized().dot(velocity), 2) / 2
	e_all = e_kin + e_pot
	pass

func _ready():
	old_global_position = global_position
	change_hook_point(now_hook_point)

func _input(event):
	if event is InputEventMouse:
		if event.is_pressed():
			points_stack = []
			change_hook_point(RopePoint.new(get_global_mouse_position(), Vector2.ZERO))

func  _process(delta):
	queue_redraw()

func update_points():
	
	queue_redraw()
	var poly_obj = $CollisionPolygon2D
	poly_obj.polygon[0] = now_hook_point.position - global_position
	poly_obj.polygon[1] = old_global_position - global_position
	poly_obj.polygon[2] = global_position - global_position
	
	var world = get_world_2d()
	var state = world.direct_space_state
	var parameters = PhysicsShapeQueryParameters2D.new()
	parameters.shape = ConvexPolygonShape2D.new()
	parameters.shape.points = poly_obj.polygon
	parameters.shape_rid = parameters.shape.get_rid()
	parameters.collide_with_bodies = true
	parameters.transform = get_global_transform()
	var points = state.collide_shape(parameters)
	debug_points = points
	if points:
		var point = change_points(points)
		points_stack.push_back(now_hook_point)
		change_hook_point(RopePoint.new(point - (global_position - old_global_position).normalized() * 5.0, global_position - old_global_position))

	if now_hook_point.is_finished(global_position):
		if not points_stack.is_empty():
			change_hook_point(points_stack[-1])
			points_stack.pop_back()
	
func change_points(points: Array[Vector2]):
	#return points[0]
	var result = null
	var r_x = INF
	var on_n = (global_position - old_global_position).normalized()
	var bh_n = on_n.rotated(PI / 2)
	var bh = abs(bh_n.dot(old_global_position - now_hook_point.position))
	for p in points:
		var p_h = abs(bh_n.dot(now_hook_point.position - p))
		var p_x = on_n.dot(p - old_global_position) - on_n.dot(now_hook_point.position - old_global_position) * (bh - p_h)
		p_x = p_x * bh / p_h
		if p_x < r_x:
			result = p
			r_x = p_x
	return result

func _physics_process(delta):
	var hook_vec = (global_position - now_hook_point.position)
	var hook_dir = hook_vec.normalized()
	var move_dir = hook_dir.rotated(PI / 2)
	
	if now_lenght < hook_vec.dot(hook_dir):
		global_position = hook_dir * now_lenght + now_hook_point.position
		e_pot = (now_lenght - (gravity_dir.dot(global_position) - gravity_dir.dot(now_hook_point.position))) * gravity
		#velocity = sqrt((e_all - e_pot) * 2) * move_dir * sign(velocity.dot(move_dir))
		velocity = velocity.dot(move_dir) * move_dir
	
	update_points()
	
	old_global_position = global_position
	velocity += gravity_dir * gravity * delta
	move_and_slide()
	pass
