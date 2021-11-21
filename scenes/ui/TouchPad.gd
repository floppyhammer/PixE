extends PanelContainer

var window_dragged : bool = false
var pad_push_pressed : bool = false
var pad_move_pressed : bool = false

onready var dummy_push_btn_l = $MarginC/VBoxC/HBoxC/DummyPushButtonL
onready var dummy_push_btn_r = $MarginC/VBoxC/HBoxC/DummyPushButtonR

signal touch_pad_operated


func _process(delta):
	$DebugLabel.text = "pad_push_pressed: " + str(pad_push_pressed)
	$DebugLabel.text += "\npad_move_pressed: " + str(pad_move_pressed)


func _on_TouchPad_gui_input(event):
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			window_dragged = event.pressed
			
			var color = get_stylebox("panel").border_color
			if event.pressed:
				color.a = 1
			else:
				color.a = 0.5
			get_stylebox("panel").border_color = color
	
	if event is InputEventMouseMotion:
		if window_dragged:
			rect_position += event.relative


func _on_PanelC_gui_input(event):
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			pad_move_pressed = event.pressed
	
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			emit_signal("touch_pad_operated", event.relative, pad_push_pressed, false, false)


func _on_TouchScreenButton_pressed():
	pad_push_pressed = true
	dummy_push_btn_l.pressed = true
	emit_signal("touch_pad_operated", Vector2.ZERO, true, true, false)


func _on_TouchScreenButton_released():
	pad_push_pressed = false
	dummy_push_btn_l.pressed = false
	emit_signal("touch_pad_operated", Vector2.ZERO, false, false, true)
