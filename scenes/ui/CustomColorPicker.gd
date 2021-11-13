extends ColorPicker
tool

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in range(4):
		get_child(4).get_child(i).get_child(2).size_flags_horizontal = SIZE_EXPAND_FILL
	
	get_child(4).get_child(4).get_child(1).hide()
	get_child(4).get_child(4).get_child(3).size_flags_horizontal = SIZE_EXPAND_FILL
