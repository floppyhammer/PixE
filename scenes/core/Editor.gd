extends Control


onready var canvas = $VBoxContainer/OpArea/VBoxContainer/HBoxContainer/ScrollContainer/Panel/CenterContainer/Panel/ViewportContainer/Viewport/Canvas
onready var pen_pos_label = $VBoxContainer/InfoBar/PenPosLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	pen_pos_label.text = str(canvas.snapped_mouse_pos)
