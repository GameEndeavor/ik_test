extends Node2D

signal test_signal(parameter)

onready var base1 = $Base1
onready var ik1 = $Base1/Line2/IK
onready var base2 = $Base2
onready var ik2 = $Base2/Line2/IK
onready var base3 = $Base3
onready var ik3 = $Base3/Line2/IK
onready var base4 = $Base4
onready var ik4 = $Base4/Line2/IK
onready var target = $Target

var points = []

func _ready():
	emit_signal("test_signal", "param1")

func _process(delta):
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		update_ik()

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() && event.button_index == BUTTON_LEFT:
			update_ik()

func update_ik():
	for i in 1:
		points = []
		target.global_position = get_global_mouse_position()
		place_hand(base1, ik1, false)
		place_hand(base4, ik4, false)
		place_hand(base2, ik2, false, false)
		place_hand(base3, ik3, true, true)
		update()

func _draw():
	for point in points:
		draw_circle(point, 1, Color.magenta)

var transforms
var rotation_offsets
func place_hand(base_node, ik_node, is_flipped, is_debug = false):
	transforms = []
	rotation_offsets = []
	var t = base_node.global_scale
	_calc_ik(base_node, ik_node, target, true, is_flipped, is_debug)
	_apply_ik(base_node, ik_node, is_flipped)

func _calc_ik(node, ik_node, target_node, is_forward, is_flipped, is_debug, index = 0):
	# Recurse
	var length = 0
	var target = null
	var rotation_offset = 0
	transforms.append(null)
	rotation_offsets.append(null)
	if node.get_child_count() > 0 and node != ik_node:
		target = node.get_child(0).global_position
		rotation_offset = node.get_child(0).position.angle()
		rotation_offsets[index] = rotation_offset
		length = (target - node.global_position).length()
		_calc_ik(node.get_child(0), ik_node, target_node, is_forward, is_flipped, is_debug, index + 1)
	
	if node == ik_node:
		var rot = 0
		var pos = target_node.global_position
#		if is_flipped: pos.x = -pos.x
		transforms[index] = Transform2D(rot, pos)
		if is_debug: points.append(transforms[index].origin)
	else:
#		var rot = -rotation_offset
		var rot = (transforms[index+1].get_origin() - node.global_position).angle()
		var pos = (transforms[index+1].get_origin() - (Vector2.RIGHT * length).rotated(rot))
		var t = Transform2D(rot, pos)
		if is_flipped:
			t = t.scaled(Vector2(-1, 1))
		transforms[index] = t
		if is_debug: points.append(transforms[index].origin)
#		if index == 1: print(transforms[index].get_rotation())

func _apply_ik(node, ik_node, is_flipped, index = 0):
	if node != ik_node:
#		if !is_flipped:
		var offset = rotation_offsets[index]
#		if is_flipped: offset *= -1
		node.global_rotation = transforms[index].get_rotation()# - offset
#		else:
#			node.global_rotation = transforms[index].get_rotation() - PI
#		if index == 0 && is_flipped:
#			node.global_rotation += PI
		_apply_ik(node.get_child(0), ik_node, is_flipped, index + 1)
#	print(node.name + " : " + str(node.rotation_degrees))
