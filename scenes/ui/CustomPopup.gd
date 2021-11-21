extends Button
class_name CustomPopup

onready var tween = $Tween
onready var bg_color_rect = $BgColorRect


func _ready():
	hide()
	modulate = Color.transparent


func custom_show():
	show()
	
	tween.remove_all()
	tween.interpolate_property(self, "modulate", modulate, Color.white, 0.2)
	tween.start()
	
	yield(tween, "tween_all_completed")


func custom_hide():
	modulate = Color.white
	
	tween.remove_all()
	tween.interpolate_property(self, "modulate", modulate, Color.transparent, 0.2)
	tween.start()
	
	yield(tween, "tween_all_completed")
	
	hide()


func _on_CustomPopup_pressed():
	custom_hide()
