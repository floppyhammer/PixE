extends Control

onready var pen_pos_label = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/InfoBar/PenPosLabel
onready var scroll_c = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/ScrollC
onready var scroll_panel = scroll_c.get_node("Panel")
onready var canvas_bg = scroll_panel.get_node("CanvasBg")
onready var canvas_vp_container = canvas_bg.get_node("ViewportC")
onready var canvas_viewport = canvas_vp_container.get_node("Viewport")
onready var canvas = canvas_viewport.get_node("Canvas")

onready var axes = scroll_panel.get_node("Axes")
onready var grid = canvas_bg.get_node("Grid")
onready var checked = canvas_bg.get_node("Checked")

onready var zoom_edit = $VBoxC/OpArea/VBoxC/HBoxC/Control2/MarginContainer/HBoxContainer/ZoomEdit
onready var palette = $VBoxC/OpArea/Palette

onready var info_bar = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/InfoBar

var cursor_pos : Vector2 = Vector2.ZERO

signal color_picker_called

# Canvas doesn't save any state, while Editor does.
var editor_state = {
	"grid": {
		"size": 16,
		"show": false,
	},
	"axes": {
		"show": false,
	},
	"checked": {
		"show": false,
	},
	"zoom": 1,
	"brush": DrawingCanvas.BrushModes.SELECT,
}


func setup(p_image_size : Vector2, p_initial_image : Image = null):
	Logger.info("Editor setup with size " + str(p_image_size), "Editor")
	
	canvas.IMAGE_SIZE = p_image_size
	
	if p_initial_image:
		canvas.img_cache.append(p_initial_image)
		canvas.cache_head += 1
	
	# Clear anything left before in the viewport.
	canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	
	canvas_vp_container.get_parent().rect_size = p_image_size
	canvas_viewport.size = p_image_size
	canvas.rect_size = p_image_size
	
	# Load editor state.
	change_zoom(editor_state.zoom)
	
	canvas.change_brush_mode(editor_state.brush)
	
	# Update axes.
	axes.xupdate(editor_state)
	
	_on_Pencil_pressed()


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
	canvas.undo()


func redo_canvas():
	canvas.redo()


func _on_ColorPicker_color_changed(new_color : Color):
	palette.change_current_color(new_color)
	canvas.brush_color = new_color


func _on_Palette_color_selected(new_color : Color):
	if canvas:
		canvas.brush_color = new_color


# Pass input events manually due to some input bug of Viewport.
func _on_ViewportContainer_gui_input(event):
	canvas.receive_gui_input(event)


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
				change_zoom(1, 0, event.position)
			if event.button_index == BUTTON_WHEEL_DOWN:
				change_zoom(-1, 0, event.position)


func _on_UndoButton_pressed():
	undo_canvas()


func _on_RedoButton_pressed():
	redo_canvas()


func _on_ZoomOut_pressed():
	change_zoom(-1)


func _on_ZoomIn_pressed():
	change_zoom(1)


func change_zoom(direction : int, exact_zoom : float = 0, mouse_pos : Vector2 = Vector2(-1, -1)):
	var interval = 0
	if editor_state.zoom <= 0.5:
		interval = 0.1
	elif editor_state.zoom > 0.5 and editor_state.zoom < 2.0:
		interval = 0.2
	else:
		interval = 1.0
	
	# This will not change during zooming, so the view center is always fixed.
	var mouse_pos_ratio_on_canvas = (mouse_pos - canvas_bg.rect_position) / (canvas_bg.rect_size * editor_state.zoom)
	
	var new_zoom = editor_state.zoom + sign(direction) * interval
	
	if not exact_zoom == 0:
		new_zoom = exact_zoom
	
	editor_state.zoom = clamp(new_zoom, 0.1, 20)
	
	zoom_edit.text = str(round(editor_state.zoom * 100)) + "%"
	
	# Adjust canvas.
	# -------------------------------------------
	canvas_bg.rect_scale = Vector2.ONE * editor_state.zoom
	
	# The real size of canvas bg.
	var real_canvas_bg_size = canvas_bg.rect_size * editor_state.zoom
	
	# Scroll container size. This is fixed.
	var scroll_c_size = scroll_c.rect_size
	
	var scroll_panel_size = Vector2.ZERO
	scroll_panel_size.x = 2 * max(real_canvas_bg_size.x * 2, scroll_c_size.x)
	scroll_panel_size.y = 2 * max(real_canvas_bg_size.y * 2, scroll_c_size.y)
	scroll_panel.rect_min_size = Vector2.ONE * scroll_panel_size
	
	# Center canvas.
	canvas_bg.rect_position = Vector2.ONE * scroll_panel_size * 0.5 - real_canvas_bg_size * 0.5
	
	# Keep the current pixel unmoved.
	if mouse_pos.x > -1 and mouse_pos.y > -1:
		var pos_mark = $VBoxC/OpArea/VBoxC/HBoxC/Control2/VBoxC/ScrollC/Panel/DebugMousePosition
		
		# Mouse postion relative to the center of the canvas.
		var mouse_pos_offset = (mouse_pos_ratio_on_canvas - Vector2.ONE * 0.5) * real_canvas_bg_size
		
		# We just need to keep this point fixed on the scroll container coordinates.
		var mouse_pos_after = scroll_panel_size * 0.5 + mouse_pos_offset
		
		# These two values have to be equal.
		var scroll_pos_after = _scroll_panel_pos_to_scroll_c(mouse_pos_after)
		var scroll_pos_before = _scroll_panel_pos_to_scroll_c(mouse_pos)
		
		# Before and after offset.
		var diff = scroll_pos_before - scroll_pos_after
		
		# Mark the mouse pos.
		pos_mark.position = mouse_pos_after
		
		# Add offset.
		scroll_c.scroll_horizontal -= diff.x
		scroll_c.scroll_vertical -= diff.y
	# -------------------------------------------


func _center_canvas():
	var scroll_c_size = scroll_c.rect_size
	var scroll_panel_size = scroll_panel.rect_size
	
	var h = (scroll_panel_size.x - scroll_c_size.x) * 0.5
	var v = (scroll_panel_size.y - scroll_c_size.y) * 0.5
	
	# Add offset.
	scroll_c.set_deferred("scroll_horizontal", h)
	scroll_c.set_deferred("scroll_vertical", v)


func _info_bar_hide_brush_specific_nodes():
	info_bar.get_node("SelectSizeLabel").hide()
	info_bar.get_node("EyedropperColor").hide()


func _info_bar_disable_brush_specific_edit_ops():
	info_bar.get_node("Cut").disabled = true
	info_bar.get_node("Copy").disabled = true
	info_bar.get_node("Paste").disabled = true
	info_bar.get_node("Delete").disabled = true


# Brush tools.
# ---------------------------------------------
func _on_Select_pressed():
	canvas.change_brush_mode(canvas.BrushModes.SELECT)
	
	_info_bar_hide_brush_specific_nodes()
	info_bar.get_node("SelectSizeLabel").show()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Eraser_pressed():
	canvas.change_brush_mode(canvas.BrushModes.ERASER)
	
	_info_bar_hide_brush_specific_nodes()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Pencil_pressed():
	canvas.change_brush_mode(canvas.BrushModes.PENCIL)
	
	_info_bar_hide_brush_specific_nodes()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Eyedropper_pressed():
	canvas.change_brush_mode(canvas.BrushModes.EYEDROPPER)
	
	_info_bar_hide_brush_specific_nodes()
	info_bar.get_node("EyedropperColor").show()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Move_pressed():
	canvas.change_brush_mode(canvas.BrushModes.MOVE)
	
	_info_bar_hide_brush_specific_nodes()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Bucket_pressed():
	canvas.change_brush_mode(canvas.BrushModes.BUCKET)
	
	_info_bar_hide_brush_specific_nodes()
	_info_bar_disable_brush_specific_edit_ops()


func _on_Line_pressed():
	canvas.change_brush_mode(canvas.BrushModes.LINE)
	
	_info_bar_hide_brush_specific_nodes()
	_info_bar_disable_brush_specific_edit_ops()
# ---------------------------------------------


func _on_ShowAxes_toggled(button_pressed):
	editor_state.axes.show = button_pressed
	
	# Update Canvas overlay.
	axes.xupdate(editor_state)


func _on_ShowGrid_toggled(button_pressed):
	editor_state.grid.show = button_pressed
	
	grid.visible = button_pressed


func _on_ShowChecked_toggled(button_pressed):
	editor_state.checked.show = button_pressed
	
	checked.visible = button_pressed


func change_palette_current_color(new_color : Color):
	palette.change_current_color(new_color)
	
	canvas.brush_color = new_color


func _on_Palette_current_color_button_pressed():
	emit_signal("color_picker_called")


func _on_ScrollC_gui_input(event):
	pass # Replace with function body.


func _scroll_c_pos_to_scroll_panel(pos : Vector2) -> Vector2:
	var new_pos = Vector2.ZERO
	
	new_pos.x = scroll_c.scroll_horizontal
	new_pos.y = scroll_c.scroll_vertical
	
	new_pos += pos
	
	return new_pos


func _scroll_panel_pos_to_scroll_c(pos : Vector2) -> Vector2:
	var new_pos = Vector2.ZERO
	
	new_pos.x = pos.x - scroll_c.scroll_horizontal
	new_pos.y = pos.y - scroll_c.scroll_vertical
	
	return new_pos


func _on_ScrollC_item_rect_changed():
	_center_canvas()


func _on_Canvas_need_to_redraw():
	canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME

