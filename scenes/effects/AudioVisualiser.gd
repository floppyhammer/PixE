extends ColorRect

# Gonkee's audio visualiser for Godot 3.2 - full tutorial https://youtu.be/AwgSICbGxJM
# If you use this, I would prefer if you gave credit to me and my channel

onready var spectrum = AudioServer.get_bus_effect_instance(0, 0)
export (NodePath) var audio_player = null

var definition = 16  # Number of the bars
var size = Vector2(960, 128)  # Size of the area to show the bars
var line_width = 16  # Width of the bars
var line_color = Color.white

var min_freq = 20
var max_freq = 20000

var max_db = 0
var min_db = -40

var accel = 10
var histogram = []  # Ratio of the bars (from 0 to 1)
var histogram_now = []
var falling_speed = 0.2

func _ready():
	_reset_layout()
	
	for i in range(definition):
		histogram.append(0)
		histogram_now.append(0)
		
	if audio_player:
		max_db += get_node(audio_player).volume_db
		min_db += get_node(audio_player).volume_db


func _process(delta):
	if not audio_player: return
	
	if not get_node(audio_player).stream_paused:
		var freq = min_freq
		var interval = (max_freq - min_freq) / definition
		
		for i in range(definition):
			var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
			freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
			freqrange_low = lerp(min_freq, max_freq, freqrange_low)
			
			freq += interval
			
			var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
			freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
			freqrange_high = lerp(min_freq, max_freq, freqrange_high)
			
			var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
			mag = linear2db(mag.length())
			mag = (mag - min_db) / (max_db - min_db)
			
			mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
			mag = clamp(mag, 0.0, 1.0)
			
			histogram[i] = lerp(histogram[i], mag, accel * delta)
	else:
		for i in range(len(histogram)):
			histogram[i] = 0
	
	for i in range(len(histogram)):
		if histogram_now[i] < histogram[i]:
			histogram_now[i] = histogram[i]
		
		# Fall
		histogram_now[i] -= falling_speed * delta
		histogram_now[i] = clamp(histogram_now[i], 0, size.y)
	
	update()
	return


func _draw():
	if not audio_player: return
	
	# Horizontal Visualiser
	var start_pos = Vector2(0, size.y)
	var line_length = 0
	var line_interval = (size.x - line_width) / (definition - 1)

	for i in range(definition):
		start_pos.x = line_width / 2 + line_interval * i
		line_length = histogram_now[i] * size.y
		draw_line(start_pos, start_pos - Vector2(0, line_length), line_color, line_width)
	
	return


func _reset_layout():
	size = rect_size


func _on_AudioVisualiser_resized():
	_reset_layout()
