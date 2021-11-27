extends Node


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


# a and b should be int Vector2.
func get_pixels_between_points(a : Vector2, b : Vector2) -> Array:
	if b.x < a.x:
		var temp = a
		a = b
		b = temp
	
	var m = slope(a, b)
	var n = intercept(a, m)
	
	var pixels = [];
	
	if m:
		for x in range(a.x, b.x + 1):
			var y = m * x + n;
			pixels.append(Vector2(x, y))
	
	return pixels


func interpolate_pixels_along_line(a : Vector2, b : Vector2) -> Array:
	"""Uses Xiaolin Wu's line algorithm to interpolate all of the pixels along a
	straight line, given two points (x0, y0) and (x1, y1)

	Wikipedia article containing pseudo code that function was based off of:
		http://en.wikipedia.org/wiki/Xiaolin_Wu's_line_algorithm
	"""
	var x0 = a.x
	var x1 = b.x
	var y0 = a.y
	var y1 = b.y
	
	var pixels = []
	var steep = abs(y1 - y0) > abs(x1 - x0)
	
	# Ensure that the path to be interpolated is shallow and from left to right
	if steep:
		var t = x0
		x0 = y0
		y0 = t

		t = x1
		x1 = y1
		y1 = t

	if x0 > x1:
		var t = x0
		x0 = x1
		x1 = t

		t = y0
		y0 = y1
		y1 = t

	var dx = x1 - x0
	var dy = y1 - y0
	var gradient = dy / dx  # slope

	# Get the first given coordinate and add it to the return list
	var x_end = round(x0)
	var y_end = y0 + (gradient * (x_end - x0))
	var xpxl0 = x_end
	var ypxl0 = round(y_end)
	if steep:
		pixels.append_array([Vector2(ypxl0, xpxl0), Vector2(ypxl0 + 1, xpxl0)])
	else:
		pixels.append_array([Vector2(xpxl0, ypxl0), Vector2(xpxl0, ypxl0 + 1)])

	var interpolated_y = y_end + gradient

	# Get the second given coordinate to give the main loop a range
	x_end = round(x1)
	y_end = y1 + (gradient * (x_end - x1))
	var xpxl1 = x_end
	var ypxl1 = round(y_end)

	# Loop between the first x coordinate and the second x coordinate, interpolating the y coordinates
	for x in range(xpxl0 + 1, xpxl1):
		if steep:
			pixels.append_array([Vector2(floor(interpolated_y), x), Vector2(floor(interpolated_y) + 1, x)])
		else:
			pixels.append_array([Vector2(x, floor(interpolated_y)), Vector2(x, floor(interpolated_y) + 1)])

		interpolated_y += gradient

	# Add the second given coordinate to the given list
	if steep:
		pixels.append_array([Vector2(ypxl1, xpxl1), Vector2(ypxl1 + 1, xpxl1)])
	else:
		pixels.append_array([Vector2(xpxl1, ypxl1), Vector2(xpxl1, ypxl1 + 1)])

	return pixels
