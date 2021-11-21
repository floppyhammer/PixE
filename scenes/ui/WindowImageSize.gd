extends Button

onready var width_edit = $CenterC/PanelC/MarginC/VBoxC/GridC/WidthLineEdit
onready var height_edit = $CenterC/PanelC/MarginC/VBoxC/GridC/HeightLineEdit
onready var lock_ratio_check = $CenterC/PanelC/MarginC/VBoxC/LockRatioCheck

var old_size : Vector2
var lock_ratio : bool = false

# INTERPOLATE_NEAREST
# INTERPOLATE_BILINEAR
# INTERPOLATE_CUBIC
# INTERPOLATE_TRILINEAR
# INTERPOLATE_LANCZOS
var interpolation = Image.INTERPOLATE_NEAREST

signal size_changed


func _ready():
	Logger.add_module("WindowImageSize")


func custom_show(image_size : Vector2):
	old_size = image_size
	
	width_edit.text = str(image_size.x)
	height_edit.text = str(image_size.y)
	
	show()


func _on_OK_pressed():
	var new_width = width_edit.text.to_int()
	var new_height = height_edit.text.to_int()
	
	if new_width == old_size.x and new_height == old_size.y:
		hide()
		return
	
	if Math.is_value_in_range(new_width, 0, Image.MAX_WIDTH) and Math.is_value_in_range(new_height, 0, Image.MAX_HEIGHT):
		emit_signal("size_changed", Vector2(new_width, new_height), interpolation)
		Logger.info("Change size to (%d, %d)" % [new_width, new_height], "WindowImageSize")
		hide()
	else:
		Logger.info("Invalid size (%d, %d)" % [new_width, new_height], "WindowImageSize")
		if not Math.is_value_in_range(new_width, 0, Image.MAX_WIDTH):
			width_edit.text = "Invalid width"
		if not Math.is_value_in_range(new_height, 0, Image.MAX_HEIGHT):
			height_edit.text = "Invalid height"


func _on_WindowImageSize_pressed():
	hide()


func _on_Cancel_pressed():
	hide()


func _on_InterpolationOption_item_selected(index):
	interpolation = index


func _on_WidthLineEdit_text_changed(new_text):
	if lock_ratio and old_size.x != 0:
		var new_width = new_text.to_int()
		
		var new_height = new_width * (old_size.y / old_size.x)
		print(new_height)
		height_edit.text = str(new_height)


func _on_HeightLineEdit_text_changed(new_text):
	if lock_ratio and old_size.y != 0:
		var new_height = new_text.to_int()
		
		var new_width = new_height / (old_size.y / old_size.x)
		
		width_edit.text = str(new_width)


func _on_LockRatioCheck_toggled(button_pressed):
	lock_ratio = button_pressed
