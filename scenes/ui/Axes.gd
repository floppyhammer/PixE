extends Control

var axes_color = Color(1.0, 1.0, 1.0, 0.5)

var editor_state_copy : Dictionary


func xupdate(editor_state : Dictionary):
	editor_state_copy = editor_state
	update()


func _draw():
	if not editor_state_copy: return
	
	if editor_state_copy.axes.show:
		var center = rect_size * 0.5
		
		draw_line(Vector2(0, center.y), Vector2(rect_size.x, center.y), axes_color)
		draw_line(Vector2(center.x, 0), Vector2(center.x, rect_size.y), axes_color)

	if editor_state_copy.grid.show:
		pass
