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

var transforms # Transforms to get the rotation needed to perform IK
var rotation_offsets # rotations needed for limb to point to the right

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
	points = []
	target.global_position = get_global_mouse_position()
	place_hand(base1, ik1, false)
	place_hand(base4, ik4, true)
	place_hand(base2, ik2, false)
	place_hand(base3, ik3, true, true)

func place_hand(base_node, ik_node, is_flipped, is_debug = false):
	transforms = []
	rotation_offsets = []
	_calc_ik(base_node, ik_node, target, true, is_flipped, is_debug)
	_apply_ik(base_node, ik_node, is_flipped, is_debug)

func _calc_ik(node, ik_node, target_node, is_forward, is_flipped, is_debug, index = 0):
	var length = 0 # How far from target to place position
	var target = null # What to target
	# Allocate data to array
	transforms.append(null)
	rotation_offsets.append(null)
	# If not the tip of the limb, then initialize data and recurse through first child
	if node.get_child_count() > 0 and node != ik_node:
		# Target the first child
		target = node.get_child(0).global_position
		# Generate rotation offset by getting the angle to the child
		rotation_offsets[index] = target.position.angle()
		# Get distance between target and self for positioning
		length = (target - node.global_position).length()
		# Recurse to the next joint
		_calc_ik(target, ik_node, target_node, is_forward, is_flipped, is_debug, index + 1)
	
	# If node is the tip of the limb
	if node == ik_node:
		# Rotation isn't important, place directly on the target
		var rot = 0
		var pos = target_node.global_position
		
		# Store for applying later
		transforms[index] = Transform2D(rot, pos)
	else:
		# Get the rotation towards the next joint, checking the stored transform
		# Due to recursion, processing happens from the tip down
		var rot = (transforms[index+1].get_origin() - node.global_position).angle()
		# Get the position needed to place the position at `length` distance from the next joint
		var pos = (transforms[index+1].get_origin() - (Vector2.RIGHT * length).rotated(rot))
		
		if is_flipped:
			rot += PI
		
		# Store the data needed to perform the IK as a transform
		# We're storing first so that the children don't get thrown off by relative positioning
		transforms[index] = Transform2D(rot, pos)

func _apply_ik(node, ik_node, is_flipped, is_debug = false, index = 0):
	
	if node != ik_node:
		# Once the calculation have been performed, apply rotation.
		# We don't need to move the nodes, since movement is relative
		# Rotation needs to be applied differently when flipped, which is half magic
		# Rotation offsets are also applied because when used with sprites, a rotation of
		# 0 may not point directly to the right
		if !is_flipped:
			node.global_rotation = transforms[index].get_rotation() - rotation_offsets[index]
		else:
			node.global_rotation = transforms[index].get_rotation() + rotation_offsets[index]
			node.global_rotation = PI - node.global_rotation
		
		# Recurse through the limb, applying to all children
		_apply_ik(node.get_child(0), ik_node, is_flipped, is_debug, index + 1)
