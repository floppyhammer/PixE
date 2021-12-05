extends ColorPicker
tool


func _ready():
	for i in range(4):
		get_child(4).get_child(i).get_child(2).size_flags_horizontal = SIZE_EXPAND_FILL
	
	get_child(1).get_child(0).rect_min_size.y = 24
	get_child(1).get_child(1).hide()
	get_child(3).hide() # Hide separator.
	get_child(4).get_child(4).get_child(1).hide()
	get_child(4).get_child(4).get_child(3).size_flags_horizontal = SIZE_EXPAND_FILL
