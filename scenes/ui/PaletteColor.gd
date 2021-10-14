extends Button
tool

export (Color) var color = Color.white setget set_color


func _ready():
	get_stylebox("normal", "").resource_local_to_scene = true
	get_stylebox("hover", "").resource_local_to_scene = true
	get_stylebox("pressed", "").resource_local_to_scene = true


func set_color(p_color):
	color = p_color
	
	get_stylebox("normal", "").bg_color = color
	get_stylebox("hover", "").bg_color = color
	get_stylebox("pressed", "").bg_color = color
