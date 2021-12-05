extends ViewportContainer


var cursor_pos : Vector2 = Vector2.ZERO

var color : Color = Color.white

var rainbow = [
	Color(255, 0, 0),  # 0 ~ 255 (256)
	Color(255, 255, 0),  # 255 ~ 255 * 2 (256)
	Color(0, 255, 0),  # 255 * 2 ~ 255 * 3 (256)
	Color(0, 255, 255),  # 255 * 3 ~ 255 * 4 (256)
	Color(0, 0, 255),  # 255 * 2 ~ 255 * 3 (256)
	Color(255, 0, 255),  # 255 * 2 ~ 255 * 3 (256)
	Color(255, 0, 0),  # 255 * 2 ~ 255 * 3 (256)
]

var offset = 0.0

var total_colors = 256 * 6

var speed = 1.0


func assign_color(percent):
	var color_index = int(percent * total_colors)
	var step = int(color_index / 256)
	var local = color_index % 256
	
	var c = Color(255, 255, 255)
	match step:
		0:
			c = Color(255, local, 0)
		1:
			c = Color(255 - local, 255, 0)
		2:
			c = Color(0, 255, local)
		3:
			c = Color(0, 255 - local, 255)
		4:
			c = Color(local, 0, 255)
		5:
			c = Color(255, 0, 255 - local)
	
	c.r /= 255.0
	c.g /= 255.0
	c.b /= 255.0
	
	return c


func _ready():
	$Viewport.gui_disable_input = true


func _process(delta):
	offset += delta * speed
	if offset >= 2 * PI:
		offset -= 2 * PI
	
	color = assign_color(offset / (2 * PI))
	
	update()


func _draw():
	draw_rect(Rect2(cursor_pos.x, cursor_pos.y, 1, 1), color, false)
