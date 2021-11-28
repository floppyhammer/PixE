extends Control

var axes_color = Color(1.0, 1.0, 1.0, 0.5)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _draw():
	var center = rect_size * 0.5
	
	draw_line(Vector2(0, center.y), Vector2(rect_size.x, center.y), axes_color)
	draw_line(Vector2(center.x, 0), Vector2(center.x, rect_size.y), axes_color)
