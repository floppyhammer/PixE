extends Control


onready var pen_pos_label = $VBoxContainer/InfoBar/PenPosLabel
onready var canvas_viewport = $VBoxContainer/OpArea/VBoxContainer/HBoxContainer/ScrollContainer/Panel/CenterContainer/Panel/ViewportContainer/Viewport
onready var canvas = canvas_viewport.get_node("Canvas")
onready var debug_label = $DebugLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	pen_pos_label.text = str(canvas.snapped_mouse_pos)
	
	if Input.is_action_just_pressed("undo"):
		canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		canvas.undo()
	if Input.is_action_just_pressed("redo"):
		canvas_viewport.render_target_clear_mode = canvas_viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		canvas.redo()


func _on_Canvas_stroke_finished():
	print("Stroke finished")
	var img = canvas_viewport.get_texture().get_data()
	img.flip_y()
	
	canvas.texture_cache.append(img)
	canvas.cache_header += 1


func _on_Canvas_draw():
	var text = ""
	text += "texture_cache: " + str(canvas.texture_cache)
	text += "\ncache_header: " + str(canvas.cache_header)
	text += "\npixel_patch: " + str(canvas.pixel_patch)
	debug_label.text = text
	
	if canvas.cache_header > -1 and canvas.cache_header < canvas.texture_cache.size():
		var tex = ImageTexture.new()
		tex.create_from_image(canvas.texture_cache[canvas.cache_header])
		$TextureRect.texture = tex
