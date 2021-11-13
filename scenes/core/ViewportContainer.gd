extends ViewportContainer


var cursor_pos : Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	$Viewport.gui_disable_input = true


func _process(delta):
	update()


func _draw():
	draw_rect(Rect2(cursor_pos.x, cursor_pos.y, 1, 1), Color.black, false)
