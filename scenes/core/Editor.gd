extends Control

onready var pen_pos_label = $VBoxContainer/InfoBar/PenPosLabel
onready var canvas_vp_container = $VBoxContainer/OpArea/VBoxContainer/HBoxContainer/ScrollContainer/Panel/CenterContainer/Panel/Bg/ViewportContainer
onready var canvas_viewport = canvas_vp_container.get_node("Viewport")
onready var canvas = canvas_viewport.get_node("Canvas")
onready var debug_label = $DebugLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	# Clear anything left before in the viewport.
	canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	pass # Replace with function body.


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
