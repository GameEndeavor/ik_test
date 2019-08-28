extends Node2D

onready var flipper = $Flipper

func _process(delta):
	update()

func _draw():
	
	flipper.global_rotation = get_global_mouse_position().angle() + PI
	draw_line(Vector2.ZERO, get_global_mouse_position(), Color.magenta, 1.0, true)