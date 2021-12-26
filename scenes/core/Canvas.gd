extends Control
class_name DrawingCanvas

var IMAGE_SIZE = Vector2(32, 32)

enum BrushModes {
	SELECT = 0,
	PENCIL,
	ERASER,
	EYEDROPPER,
	MOVE,
	BUCKET,
	LINE,
}

enum BrushShapes {
	RECTANGLE,
	CIRCLE,
}

# Brush config.
var brush_mode = BrushModes.PENCIL
var brush_size = 4
var brush_color = Color.black
var brush_shape = BrushShapes.RECTANGLE
var brush_pos = Vector2.ZERO

# Integer brush position.
var snapped_brush_pos = Vector2.ZERO

# Where the brush touches and leaves the canvas.
var brush_start_pos = Vector2.ZERO
var brush_end_pos = Vector2.ZERO

# Only draw new dot when mouse moved.
# Also, fix incontinuous pixels when moving the brush fast.
var last_pixel : Vector2 # Snapped.
var last_pos : Vector2 # Not snapped.

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

# Once OP is finished, update image cache.
signal stroke_finished

# Clear viewport, redraw cache head, redraw pixel batch.
signal need_to_redraw

signal bursh_moved_by_mouse

var custom_touch_input_info = {
	"pushed": false,
	"position": Vector2.ZERO,
}

var current_pixel_info = {
	"pos": Vector2.ZERO,
	"color": Color.white,
}


func undo() -> bool:
	Logger.info("Undo", "Canvas")
	
	if cache_head > 0:
		cache_head -= 1
		
		# Redraw if header is not at zero.
		need_to_redraw_cache = true
		
		update()
		
		emit_signal("need_to_redraw")
		
		return true
	else:
		cache_head = 0
		
		return false


func redo() -> bool:
	Logger.info("Redo", "Canvas")
	
	if cache_head < img_cache.size() - 1:
		cache_head += 1
		
		need_to_redraw_cache = true
		
		update()
		
		emit_signal("need_to_redraw")
		
		return true
	else:
		cache_head = img_cache.size() - 1
		
		return false


func _draw():
	Logger.info("Redraw canvas", "Canvas")
	
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
		draw_primitive([p + Vector2.DOWN], [color], [])


func save_picture(path):
	# Wait until the frame has finished before getting the texture.
	yield(VisualServer, "frame_post_draw")
	
	# Get the viewport image.
	var img = get_viewport().get_texture().get_data()
	# Crop the image so we only have canvas area.
	var cropped_image = img.get_rect(Rect2(Vector2.ZERO, IMAGE_SIZE))
	# Flip the image on the Y-axis (it's flipped upside down by default).
	cropped_image.flip_y()
	
	# Save the image with the passed in path we got from the save dialog.
	cropped_image.save_png(path)


func change_brush_mode(new_mode):
	var enum_name = BrushModes.keys()[new_mode]
	Logger.info("Change brush mode to " + enum_name, "Canvas")
	brush_mode = new_mode


# Pass input events manually due to some input bug of Viewport.
func receive_gui_input(event):
	match brush_mode:
		BrushModes.PENCIL:
			_handle_pencil(event)
		BrushModes.EYEDROPPER:
			_handle_eyedropper(event)
		BrushModes.LINE:
			_handle_line(event)


func _handle_pencil(event):
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if event.pressed:
				var snapped = Math.snap_to_pixel(event.position)
				snapped_brush_pos = snapped
				
				match brush_mode:
					BrushModes.PENCIL:
						_add_pixel_to_batch(snapped)
						
						last_pixel = snapped
						last_pos = event.position
						
						update()
					BrushModes.EYEDROPPER:
						current_pixel_info.color = img_cache[cache_head].get_pixel(snapped)
						print(current_pixel_info.color)
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
			var snapped = Math.snap_to_pixel(event.position)
			snapped_brush_pos = snapped
			
			emit_signal("bursh_moved_by_mouse", event.position)
			
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				# Brush out of the canvas.
				if snapped.x > IMAGE_SIZE.x or snapped.y > IMAGE_SIZE.y:
					pixel_batch.clear()
					update()
					return
				
				# To avoid adding the same pixel when moving the brush
				# inside the pixel.
				if snapped != last_pixel:
					var pixels = Math.interpolate_pixels_along_line(last_pos, event.position)
					
					for p in pixels:
						_add_pixel_to_batch(p)
					
					last_pixel = snapped
					last_pos = event.position
				
				update()


func _handle_eyedropper(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			var snapped = Math.snap_to_pixel(event.position)
			snapped_brush_pos = snapped
			
			img_cache[cache_head].lock()
			current_pixel_info.color = img_cache[cache_head].get_pixelv(snapped)
			img_cache[cache_head].unlock()


func _handle_line(event):
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			var snapped = Math.snap_to_pixel(event.position)
			
			# Start drawing line.
			if event.pressed:
				brush_start_pos = event.position
				snapped_brush_pos = snapped

			else: # Line is decided upon mouse release.
				# If we did undo before, remove outdated images.
				# Don't remove the first empty image.
				if cache_head < img_cache.size() - 1:
					img_cache.resize(cache_head + 1)
				
				brush_end_pos = event.position
				
				var start_pos_pixel_center = Math.snap_to_pixel(brush_start_pos) + Vector2(0.5, 0.5)
				var end_pos_pixel_center = snapped + Vector2(0.5, 0.5)
				
				var pixels = Math.interpolate_pixels_along_line(start_pos_pixel_center, end_pos_pixel_center)
				
				# Remove pixels that contact two or more pixels.
				var pixels_to_exclude = []
#				for p0 in pixels:
#					var vertical_contact_count = 0
#					var horizontal_contact_count = 0
#					for p1 in pixels:
#						if p0 != p1 and p0.distance_to(p1) < 1.1:
#							if p0.x != p1.x:
#								horizontal_contact_count += 1
#							if p0.y != p1.y:
#								vertical_contact_count += 1
#					if vertical_contact_count >= 1 and horizontal_contact_count >= 1:
#						pixels_to_exclude.append(p0)
				
				pixel_batch.clear()
				for p in pixels:
					var point_center = p + Vector2.ONE * 0.5
					var dis_to_line = Math.distance_from_point_to_line(start_pos_pixel_center, end_pos_pixel_center, point_center)
					var m = (start_pos_pixel_center.y - end_pos_pixel_center.y) / (start_pos_pixel_center.x - end_pos_pixel_center.x)
					print(dis_to_line)
					var vertical_dis = (m * (point_center.x - start_pos_pixel_center.x) + start_pos_pixel_center.y)
#					var above_line = point_center.y < vertical_dis
#					if above_line:
#						if vertical_dis < 0.5:
#							_add_pixel_to_batch(p)
#					else:
#						if dis_to_line < 0.5:
#							_add_pixel_to_batch(p)
					if dis_to_line <= 0.5:
						_add_pixel_to_batch(p)
				
				emit_signal("stroke_finished")
				
				# 1. Clean frame.
				# 2. Draw things that exist before LINE operation.
				# 3. Draw dragged line.
				# 4. Update image cache.
				update()
		
		# Drag.
		if event is InputEventMouseMotion:
			var snapped = Math.snap_to_pixel(event.position)
			snapped_brush_pos = snapped
			
			var start_pos = Math.snap_to_pixel(last_pos) + Vector2(0.5, 0.5)
			var end_pos = snapped + Vector2(0.5, 0.5)
			
			emit_signal("bursh_moved_by_mouse", event.position)
			
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				# To avoid adding the same pixel when moving the brush
				# inside the pixel.
				if snapped != last_pixel:
					var pixels = Math.interpolate_pixels_along_line(start_pos, end_pos)
					
					for p in pixels:
						_add_pixel_to_batch(p)
					
					last_pixel = snapped
					last_pos = event.position
					
					# 1. Clean frame.
					# 2. Draw things that exist before LINE operation.
					# 3. Draw dragged line.
					# 4. Don't update image cache.
					#update()


func receive_touch_input(brush_pos, pushed, just_pushed, just_released):
	if just_pushed:
		var snapped = Math.snap_to_pixel(brush_pos)
		snapped_brush_pos = snapped
		
		_add_pixel_to_batch(snapped)
		
		last_pixel = snapped
		last_pos = brush_pos
		
		update()
	if just_released:
		pixel_batch.clear()
		
		# If we did undo before, remove outdated images.
		# Don't remove the first empty image.
		if cache_head < img_cache.size() - 1:
			img_cache.resize(cache_head + 1)
		
		emit_signal("stroke_finished")
		
		update()
	
	var snapped = Math.snap_to_pixel(brush_pos)
	snapped_brush_pos = snapped
	
	if pushed:
		# Brush out of the canvas.
		if snapped.x > IMAGE_SIZE.x or snapped.y > IMAGE_SIZE.y:
			pixel_batch.clear()
			update()
			return
		
		# To avoid adding the same pixel when moving the brush
		# inside the pixel.
		if snapped != last_pixel:
			var pixels = Math.interpolate_pixels_along_line(last_pos, brush_pos)
			
			for p in pixels:
				_add_pixel_to_batch(p)
			
			last_pixel = snapped
			last_pos = brush_pos
		
		update()


func _add_pixel_to_batch(new_pixel : Vector2):
	if not new_pixel in pixel_batch:
		pixel_batch.append(new_pixel)


func change_size(new_size : Vector2):
	IMAGE_SIZE = new_size
	
	rect_size = new_size


func change_image_size(new_size : Vector2):
	pass
