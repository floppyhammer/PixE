extends VBoxContainer

var current_color : Color = Color.white

var colors = []

var preset_colors = [
	Color("d9ed92"), Color("b5e48c"),
	Color("99d98c"), Color("76c893"),
	Color("52b69a"), Color("34a0a4"),
	Color("168aad"), Color("1a759f"),
	Color("1e6091"), Color("184e77")
]

var color_scene = preload("res://scenes/ui/PaletteColor.tscn")

var color_button_group = ButtonGroup.new()

onready var grid_c = $PanelC/ScrollC/GridC
onready var current_color_btn = $CurrentColor

signal color_selected
signal current_color_button_pressed


func _ready():
	color_button_group.connect("pressed", self, "_when_color_selected")
	
	for c in preset_colors:
		_add_color(c)
	
	change_current_color(Color.white)


func _add_color(new_color : Color):
	if not new_color in colors:
		colors.append(new_color)
		
		var color_node = color_scene.instance()
		color_node.set_content_color(new_color)
		color_node.set_unique_id(grid_c.get_child_count())
		color_node.group = color_button_group
		grid_c.add_child(color_node)
		
		# Select the newly added color.
		color_node.pressed = true


func _delete_color():
	var selected_color_button = color_button_group.get_pressed_button()
	
	if not selected_color_button: return
	
	
	var selected_color = selected_color_button.get_content_color()
	
	colors.remove(colors.find(selected_color))
	grid_c.remove_child(selected_color_button)
	selected_color_button.queue_free()


func change_current_color(new_color : Color):
	current_color = new_color
	
	current_color_btn.get_stylebox("normal").bg_color = new_color
	current_color_btn.get_stylebox("pressed").bg_color = new_color


func _when_color_selected(index):
	var color = color_button_group.get_pressed_button().get_content_color()
	emit_signal("color_selected", color)


func _on_Add_pressed():
	_add_color(current_color)


func _on_Delete_pressed():
	_delete_color()


func _on_CurrentColor_pressed():
	emit_signal("current_color_button_pressed")
	
	var selected_color_button = color_button_group.get_pressed_button()
	
	if selected_color_button is Button:
		selected_color_button.pressed = false

