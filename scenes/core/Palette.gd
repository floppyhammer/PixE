extends ScrollContainer

var colors = [Color.white, Color.red, Color.green, Color.blue]

var color_scene = preload("res://scenes/ui/PaletteColor.tscn")

var color_button_group = ButtonGroup.new()

onready var grid_c = $GridContainer

signal color_selected

# Called when the node enters the scene tree for the first time.
func _ready():
	color_button_group.connect("pressed", self, "_when_color_selected")
	
	for c in colors:
		add_color(c)


func add_color(p_color):
	var color_node = color_scene.instance()
	color_node.set_content_color(p_color)
	color_node.set_unique_id(grid_c.get_child_count())
	color_node.group = color_button_group
	grid_c.add_child(color_node)


func _when_color_selected(index):
	var color = color_button_group.get_pressed_button().get_content_color()
	emit_signal("color_selected", color)
