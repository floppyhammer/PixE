extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# get_modified_time()
	pass # Replace with function body.


func prepare_file(file_name, date_modified, file_size):
	$Icon.texture = load("res://assets/graphics/icon_file.png")
	$VBoxC/Info.text = "%s - %f MB" % [date_modified, file_size]


func prepare_folder(folder_name, files_included):
	$Icon.texture = load("res://assets/graphics/icon_dir.png")
	$VBoxC/Info.text = "(%d)" % [files_included]
