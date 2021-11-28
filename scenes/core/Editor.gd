extends Control

onready var pen_pos_label = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/InfoBar/PenPosLabel
onready var scroll_c = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/ScrollC
onready var scroll_panel = scroll_c.get_node("Panel")
onready var canvas_bg = scroll_panel.get_node("Bg")
onready var canvas_vp_container = canvas_bg.get_node("ViewportC")
onready var canvas_viewport = canvas_vp_container.get_node("Viewport")

onready var canvas = canvas_viewport.get_node("Canvas")
onready var zoom_edit = $VBoxC/OpArea/VBoxC/HBoxC/Control2/MarginContainer/HBoxContainer/ZoomEdit
onready var palette = $VBoxC/OpArea/Palette/Palette

var cursor_pos : Vector2 = Vector2.ZERO
var canvas_zoom : float = 1


func _ready():
	change_zoom(5)


func setup(p_image_size : Vector2, p_initial_image : Image = null):
	canvas.IMAGE_SIZE = p_image_size
	
	if p_initial_image:
		canvas.img_cache.append(p_initial_image)
		canvas.cache_head += 1
	
	# Clear anything left before in the viewport.
	canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	
	canvas_vp_container.get_parent().rect_size = p_image_size
	canvas_viewport.size = p_image_size
	canvas.rect_size = p_image_size
	
	change_zoom(5)


func _process(delta):
	var snapped_cursor_pos = Math.snap_to_pixel(cursor_pos)
	pen_pos_label.text = "%d,%d" % [snapped_cursor_pos.x, snapped_cursor_pos.y]
	
	if Input.is_action_just_pressed("undo"):
		undo_canvas()
	if Input.is_action_just_pressed("redo"):
		redo_canvas()
	
	canvas_vp_container.cursor_pos = snapped_cursor_pos


func _on_Canvas_stroke_finished():
	print("Stroke finished")
	var img = canvas_viewport.get_texture().get_data()
	img.flip_y()
	
	canvas.img_cache.append(img)
	canvas.cache_head += 1


func _on_Canvas_draw():
	pass
	#Logger.info("Image Cache: " + str(canvas.img_cache), "Editor")
	#Logger.info("Cache Head: " + str(canvas.cache_head), "Editor")
	#Logger.info("Pixel Batch: " + str(canvas.pixel_batch), "Editor")
	#Logger.info("Brush Mode: " + str(canvas.brush_mode), "Editor")


func undo_canvas():
	if canvas.undo():
		canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME


func redo_canvas():
	if canvas.redo():
		canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME


func _on_Eraser_toggled(button_pressed):
	canvas.brush_mode = canvas.BrushModes.ERASER


func _on_Pencil_toggled(button_pressed):
	canvas.brush_mode = canvas.BrushModes.PENCIL


func _on_Add_pressed():
	var color_btn = $VBoxC/OpArea/Palette/Color
	palette.add_color(color_btn.get_stylebox("normal").bg_color)


func _on_ColorPicker_color_changed(color):
	var color_btn = $VBoxC/OpArea/Palette/Color
	color_btn.get_stylebox("normal").bg_color = color
	color_btn.get_stylebox("pressed").bg_color = color
	canvas.brush_color = color


func _on_Palette_color_selected(color):
	var color_btn = $VBoxC/OpArea/Palette/Color
	color_btn.get_stylebox("normal").bg_color = color
	color_btn.get_stylebox("pressed").bg_color = color
	canvas.brush_color = color


# Pass input events manually due to some input bug of Viewport.
func _on_ViewportContainer_gui_input(event):
	canvas.receive_gui_input(event)


func _on_Color_pressed():
	$ColorPickerPopup.custom_show()


func _on_ZoomEdit_text_entered(new_text):
	var zoom = new_text.to_int()
	zoom_edit.text = str(zoom) + "%"
	
	canvas_vp_container.get_parent().rect_scale = Vector2.ONE * zoom * 0.01


func change_canvas_size(new_size : Vector2):
	Logger.info("Change canvas size (%d, %d)" % [new_size.x, new_size.y], "Editor")
	canvas_vp_container.get_parent().rect_size = new_size
	
	canvas.change_size(new_size)


func change_image_size(new_size : Vector2, interpolation):
	Logger.info("Change image size (%d, %d)" % [new_size.x, new_size.y], "Editor")
	
	canvas.IMAGE_SIZE = new_size
	var img = Image.new()
	
	if not canvas.img_cache.empty() and canvas.cache_head > 0:
		var new_img : Image = canvas.img_cache.back().duplicate()
		new_img.resize(new_size.x, new_size.y, interpolation)
	
	change_canvas_size(new_size)


func _on_Canvas_bursh_moved_by_mouse(new_cursor_pos : Vector2):
	cursor_pos = new_cursor_pos


func _on_TouchPad_touch_pad_operated(relative_pos, pushed, just_pushed, just_released):
	cursor_pos += relative_pos * 0.1
	
	cursor_pos.x = clamp(cursor_pos.x, 0, canvas.IMAGE_SIZE.x)
	cursor_pos.y = clamp(cursor_pos.y, 0, canvas.IMAGE_SIZE.y)

	canvas.receive_touch_input(cursor_pos, pushed, just_pushed, just_released)


# Canvas viewport control.
func _on_Panel_gui_input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			scroll_c.scroll_horizontal -= event.relative.x
			scroll_c.scroll_vertical -= event.relative.y
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				change_zoom(canvas_zoom + canvas_zoom * 0.1)
			if event.button_index == BUTTON_WHEEL_DOWN:
				change_zoom(canvas_zoom - canvas_zoom * 0.1)


func _on_UndoButton_pressed():
	undo_canvas()


func _on_RedoButton_pressed():
	redo_canvas()


func _on_ZoomOut_pressed():
	change_zoom(canvas_zoom - canvas_zoom * 0.1)


func _on_ZoomIn_pressed():
	change_zoom(canvas_zoom + canvas_zoom * 0.1)


func change_zoom(new_zoom : float):
	canvas_zoom = clamp(new_zoom, 0.2, 20)
	
	zoom_edit.text = str(round(canvas_zoom * 100)) + "%"
	
	canvas_bg.rect_scale = Vector2.ONE * canvas_zoom
	
	# This is fixed.
	var scroll_size = scroll_c.rect_size
	
	canvas_bg.rect_scale = Vector2.ONE * canvas_zoom
	
	var canvas_bg_scaled_size = canvas_bg.rect_size * canvas_bg.rect_scale
	
	var canvas2scroll_ratio = canvas_bg_scaled_size / scroll_size
	
	#var cursor_pos_ratio_before = event.position / scroll_panel.rect_min_size
	
	var scroll_panel_size
	var max_canvas_bg_scaled_size = max(canvas_bg_scaled_size.x, canvas_bg_scaled_size.y)
	if max_canvas_bg_scaled_size > scroll_size.y * 0.5:
		scroll_panel_size = max_canvas_bg_scaled_size * 2
	else: # Don't scale scroll panel.
		scroll_panel_size = scroll_c.rect_size.x
	
	scroll_panel_size = max(scroll_panel_size, scroll_c.rect_size.x)
	
	scroll_panel.rect_min_size = Vector2.ONE * scroll_panel_size
	
	# Center canvas.
	canvas_bg.rect_position = Vector2.ONE * scroll_panel_size * 0.5 - canvas_bg_scaled_size * 0.5
	
	#var cursor_pos_after = cursor_pos_ratio_before * scroll_panel_size
	
	# Set view center.
	scroll_c.scroll_horizontal = scroll_panel_size * 0.5 - scroll_size.x * 0.5
	scroll_c.scroll_vertical = scroll_panel_size * 0.5 - scroll_size.y * 0.5
