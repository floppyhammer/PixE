extends PanelContainer


signal cancel_pressed


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#popup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Cancel_pressed():
	emit_signal("cancel_pressed")
