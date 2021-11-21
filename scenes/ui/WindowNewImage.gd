extends Button

onready var width_edit = $CenterC/PanelC/MarginC/VBoxC/GridC/WidthLineEdit
onready var height_edit = $CenterC/PanelC/MarginC/VBoxC/GridC/HeightLineEdit
onready var square_ratio_check = $CenterC/PanelC/MarginC/VBoxC/SquareCheckBox

signal ok_pressed


func _on_CheckBox_toggled(button_pressed):
	if button_pressed:
		height_edit.text = width_edit.text
		height_edit.editable = false
	else:
		height_edit.editable = true


func _on_Cancel_pressed():
	hide()


func _on_WindowNewSprite_pressed():
	hide()


func _on_WidthLineEdit_text_changed(new_text):
	if not height_edit.editable:
		height_edit.text = width_edit.text


func _on_OK_pressed():
	var new_width = width_edit.text.to_int()
	var new_height = height_edit.text.to_int()
	
	if Math.is_value_in_range(new_width, 0, Image.MAX_WIDTH) and Math.is_value_in_range(new_height, 0, Image.MAX_HEIGHT):
		emit_signal("ok_pressed", Vector2(new_width, new_height))
		hide()
	else:
		if not Math.is_value_in_range(new_width, 0, Image.MAX_WIDTH):
			width_edit.text = "Invalid width"
		if not Math.is_value_in_range(new_height, 0, Image.MAX_HEIGHT):
			height_edit.text = "Invalid height"
		return
