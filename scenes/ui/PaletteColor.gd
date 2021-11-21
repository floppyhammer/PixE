extends Button
tool

export (Color) var color = Color.white setget set_content_color, get_content_color
var unique_id : int = 0 setget set_unique_id, get_unique_id


func _ready():
	get_stylebox("normal", "").resource_local_to_scene = true
	get_stylebox("hover", "").resource_local_to_scene = true
	get_stylebox("pressed", "").resource_local_to_scene = true


func set_content_color(p_color):
	color = p_color
	
	get_stylebox("normal", "").bg_color = color
	get_stylebox("hover", "").bg_color = color
	get_stylebox("pressed", "").bg_color = color


func get_content_color():
	return color


func set_unique_id(p_id):
	unique_id = p_id


func get_unique_id():
	return unique_id
