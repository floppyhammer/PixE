extends Panel

onready var tween = $Tween


func fancy_hide():
	pass


func _on_RichTextLabel_meta_clicked(meta):
	OS.shell_open(meta)


func _on_ImageViewer_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed == false:
			hide()
