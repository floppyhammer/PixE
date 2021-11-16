extends Control

onready var pen_pos_label = $VBoxContainer/InfoBar/PenPosLabel
onready var canvas_vp_container = $VBoxContainer/OpArea/VBoxContainer/HBoxContainer/ScrollContainer/Panel/Bg/ViewportContainer
onready var canvas_viewport = canvas_vp_container.get_node("Viewport")
onready var canvas = canvas_viewport.get_node("Canvas")
onready var debug_label = $DebugLabel
onready var color_picker = $CenterContainer/PopupPanel/ColorPicker
onready var zoom_menu_button = $VBoxContainer/InfoBar/ZoomMenuButton
onready var zoom_edit = $VBoxContainer/InfoBar/ZoomEdit


func _ready():
	color_picker.get_child(4).get_child(4).get_child(1).hide()
	
	zoom_menu_button.get_popup().connect("index_pressed", self, "_when_zoom_level_pressed")


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


func _process(delta):
	pen_pos_label.text = str(canvas.snapped_mouse_pos)
	
	if Input.is_action_just_pressed("undo"):
		undo_canvas()
	if Input.is_action_just_pressed("redo"):
		redo_canvas()
	
	canvas_vp_container.cursor_pos = canvas.snapped_mouse_pos


func _on_Canvas_stroke_finished():
	print("Stroke finished")
	var img = canvas_viewport.get_texture().get_data()
	img.flip_y()
	
	canvas.img_cache.append(img)
	canvas.cache_head += 1


func _on_Canvas_draw():
	var text = ""
	text += "Image Cache: " + str(canvas.img_cache)
	text += "\nCache Head: " + str(canvas.cache_head)
	text += "\nPixel Batch: " + str(canvas.pixel_batch)
	text += "\nBrush Mode: " + str(canvas.brush_mode)
	debug_label.text = text


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
	pass


func _on_ColorPicker_color_changed(color):
	var color_btn = $VBoxContainer/OpArea/Palette/Color
	color_btn.get_stylebox("normal").bg_color = color
	color_btn.get_stylebox("pressed").bg_color = color
	canvas.brush_color = color


func _on_Palette_color_selected(p_color):
	canvas.brush_color = p_color


# Pass input events manually due to some input bug of Viewport.
func _on_ViewportContainer_gui_input(event):
	canvas.receive_gui_input(event)


func _when_zoom_level_pressed(p_index):
	var item_text : String = zoom_menu_button.get_popup().get_item_text(p_index)
	var zoom = item_text.to_int()
	zoom_edit.text = item_text
	
	canvas_vp_container.get_parent().rect_scale = Vector2.ONE * zoom * 0.01


func _on_Color_pressed():
	$CenterContainer/PopupPanel.popup()


func _on_ZoomEdit_text_entered(new_text):
	var zoom = new_text.to_int()
	zoom_edit.text = str(zoom) + "%"
	
	canvas_vp_container.get_parent().rect_scale = Vector2.ONE * zoom * 0.01
