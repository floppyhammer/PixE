extends Control

var IMAGE_SIZE = Vector2(32, 32)

# Enums for the various modes and brush shapes that can be applied.
enum BrushModes {
	SELECT,
	PENCIL,
	ERASER,
	EYEDROPPER,
	MOVE,
	BUCKET,
	LINE_SHAPE,
	CIRCLE_SHAPE,
	RECTANGLE_SHAPE,
}

enum BrushShapes {
	RECTANGLE,
	CIRCLE,
}

# The top-left position of the canvas.
onready var TL_node = $TLPos

# A list to hold all of the dictionaries that make up each brush.
var brush_data_list = []

# A boolean to hold whether or not the mouse is inside the drawing area, the mouse position last _process call
# and the position of the mouse when the left mouse button was pressed.
var last_mouse_pos = Vector2()
var mouse_click_start_pos = null

# A boolean to tell whether we've set undo_elements_list_num, which holds the size of draw_elements_list
# before a new stroke is added (unless the current brush mode is 'rectangle shape' or 'circle shape', in
# which case we do things a litte differently. See the undo_stroke function for more details).
var undo_set = false
var undo_element_list_num = -1

# The current brush settings: The mode, size, color, and shape we have currently selected.
var brush_mode = BrushModes.PENCIL
var brush_size = 4
var brush_color = Color.black
var brush_shape = BrushShapes.RECTANGLE;

# The color of the background. We need this for the eraser (see the how we handle the eraser
# in the _draw function for more details).
var bg_color = Color.white

var mouse_pos = Vector2.ZERO
var snapped_mouse_pos = Vector2.ZERO

# Only draw new dot when mouse moved.
var last_pixel : Vector2

# Cache is used to undo steps. When a pixel path is drawn,
# add the resulting texture to cache.
var img_cache = [Image.new()]

# Only draw a pixel batch, which is from mouse press to mouse release.
var pixel_batch = []

var cache_head = 0

var need_to_redraw_cache = true

# Don't use a temporary variable to call draw_texture() as it will be
# dropped before the actual rendering takes place.
var tex = ImageTexture.new()

signal stroke_finished


func undo() -> bool:
	print("undo")
	
	if cache_head > 0:
		cache_head -= 1
		
		# Redraw if header is not at zero.
		need_to_redraw_cache = true
		
		update()
		
		return true
	else:
		cache_head = 0
		
		return false


func redo() -> bool:
	print("redo")
	
	if cache_head < img_cache.size() - 1:
		cache_head += 1
		
		need_to_redraw_cache = true
		
		update()
		
		return true
	else:
		cache_head = img_cache.size() - 1
		
		return false


func _draw():
	print("Redraw canvas")
	
	# NB: create_from_image() doesn't like empty images.
	if need_to_redraw_cache and cache_head > 0:
		# Draw the last texture in the cache.
		tex.create_from_image(img_cache[cache_head])
		
		draw_texture(tex, Vector2.ZERO)
		
		need_to_redraw_cache = false
	
	var color = brush_color
	
	match brush_mode:
		BrushModes.PENCIL:
			material.blend_mode = material.BLEND_MODE_MIX
		BrushModes.ERASER:
			material.blend_mode = material.BLEND_MODE_MUL
			color = Color.transparent
	
	for p in pixel_batch:
		draw_primitive([p + Vector2.RIGHT], [color], [])


func save_picture(path):
	# Wait until the frame has finished before getting the texture.
	yield(VisualServer, "frame_post_draw")

	# Get the viewport image.
	var img = get_viewport().get_texture().get_data()
	# Crop the image so we only have canvas area.
	var cropped_image = img.get_rect(Rect2(TL_node.global_position, IMAGE_SIZE))
	# Flip the image on the Y-axis (it's flipped upside down by default).
	cropped_image.flip_y()

	# Save the image with the passed in path we got from the save dialog.
	cropped_image.save_png(path)


func snap_to_pixel(pos : Vector2):
	pos.x = int(pos.x)
	pos.y = int(pos.y)
	return pos


func _on_Canvas_gui_input(event):
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if event.pressed:
				# If we do not have a position for when the mouse was first clicked, then this must
				# be the first time is_mouse_button_pressed has been called since the mouse button was
				# released, so we need to store the position.
				if mouse_click_start_pos == null:
					mouse_click_start_pos = mouse_pos
				
				var snapped = snap_to_pixel(event.position)
				snapped_mouse_pos = snapped
				
				if not snapped in pixel_batch:
					pixel_batch.append(snapped)
				last_pixel = snapped
				
				update()
			else:
				pixel_batch.clear()
				
				# If we did undo before, remove outdated images.
				# Don't remove the first empty image.
				if cache_head < img_cache.size() - 1:
					img_cache.resize(cache_head + 1)
				
				emit_signal("stroke_finished")
				
				update()
		
		# Drag.
		if event is InputEventMouseMotion:
			var snapped = snap_to_pixel(event.position)
			snapped_mouse_pos = snapped
			
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				if snapped.x > IMAGE_SIZE.x or snapped.y > IMAGE_SIZE.y:
					pixel_batch.clear()
					update()
					return
				
				if snapped != last_pixel:
					if not snapped in pixel_batch:
						pixel_batch.append(snapped)
					last_pixel = snapped
				
				update()
