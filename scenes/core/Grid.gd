extends Control

var image_size : Vector2 = Vector2(32, 32)
var interval : int = 1
var color = Color(1, 1, 1, 0.3)


func xupdate(p_image_size : Vector2, p_interval : int):
	image_size = p_image_size
	interval = p_interval
	
	update()


func _draw():
	# Draw grid.
	for i in range(0, image_size.x, interval):
		draw_line(Vector2(0, i), Vector2(image_size.y, i), color)
	for j in range(0, image_size.y, interval):
		draw_line(Vector2(j, 0), Vector2(j, image_size.x), color)
