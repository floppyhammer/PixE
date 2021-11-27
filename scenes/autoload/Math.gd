extends Node

enum StepDirection {
	X,
	Y,
	None
}

func rot2vec(rot : float) -> Vector2:
	return Vector2(cos(rot), sin(rot))


func snap_to_pixel(pos : Vector2) -> Vector2:
	pos.x = int(pos.x)
	pos.y = int(pos.y)
	return pos


static func angle_to_angle(from, to):
	return fposmod(to - from + PI, PI * 2) - PI


func is_value_in_range(value, lower_limit, higher_limit):
	if value > lower_limit and value < higher_limit:
		return true
	else:
		return false


func slope(a, b):
	if a[0] == b[0]:
		return null

	return (b[1] - a[1]) / (b[0] - a[0])


func intercept(point, slope):
	# Vertical line.
	if slope == null:
		return point.x
	
	return point.y - slope * point.x


func interpolate_pixels_along_line(from : Vector2, to : Vector2) -> Array:
	var pixels = []
	
	var from_tile_coords = from.floor()
	var to_tile_coords = to.floor()
	
	var vector = to - from
	
	var tile_size = Vector2.ONE
	
	# Step is the direction to advance the tile.
	var step = Vector2.ZERO
	if vector.x < 0:
		step.x = -1
	else:
		step.x = 1
		
	if vector.y < 0:
		step.y = -1
	else:
		step.y = 1
	
	var temp = Vector2.ZERO
	if vector.x >= 0:
		temp.x = 1
	else:
		temp.x = 0
	if vector.y >= 0:
		temp.y = 1
	else:
		temp.y = 0
	
	var first_tile_crossing = (from_tile_coords + temp) * tile_size;
	
	# Value of t at which the ray crosses the first vertical/horizontal tile boundary.
	var t_max = (first_tile_crossing - from) / vector;

	var t_delta = (tile_size / vector).abs();
	
	var last_step_direction = StepDirection.None
	
	var current_position = from;
	var tile_coords = from_tile_coords
	
	while true:
		pixels.append(tile_coords)
		
		var next_step_direction
		
		if t_max.x < t_max.y:
			next_step_direction = StepDirection.X
		elif t_max.x > t_max.y:
			next_step_direction = StepDirection.Y
		else:
			if step.x > 0:
				next_step_direction = StepDirection.X
			else:
				next_step_direction = StepDirection.Y
		
		var next_t
		if next_step_direction == StepDirection.X:
			next_t = t_max.x
		else:
			next_t = t_max.y
		next_t = min(next_t, 1.0)
		
		if tile_coords == to_tile_coords:
			next_step_direction = StepDirection.None
		
		# Take a step.
		if next_step_direction == StepDirection.X:
			t_max += Vector2(t_delta.x, 0.0)
			tile_coords += Vector2(step.x, 0)
		elif next_step_direction == StepDirection.Y:
			t_max += Vector2(0.0, t_delta.y)
			tile_coords += Vector2(0, step.y)
		else:
			break
		
		var next_position = from + vector * next_t
		
		# Update current position.
		current_position = next_position

		# Update last step direction.
		last_step_direction = next_step_direction;
	
	return pixels
