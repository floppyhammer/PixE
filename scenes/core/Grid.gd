extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _draw():
	# Draw grid.
	for i in range(32):
		draw_line(Vector2(0, i), Vector2(32, i), Color(1, 1, 1, 0.3))
	for j in range(32):
		draw_line(Vector2(j, 0), Vector2(j, 32), Color(1, 1, 1, 0.3))
