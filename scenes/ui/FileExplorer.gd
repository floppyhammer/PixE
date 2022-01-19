extends PanelContainer

"""
GUI layer of FileTree. Note that GUI is kept separate from implementation.
"""

# Adapt File Explorer to different usages.
enum Modes {
	SELECT_FILE = 0,
	SELECT_DIR,
	SELECT_DIR_FILE,
}
var mode = Modes.SELECT_FILE

# Used to undo and redo dir.
var dir_history = []
var dir_head : int

onready var address_edit = $MarginC/VBoxC/HBoxC4/AddressEdit
onready var file_tree = $MarginC/VBoxC/FileTree
onready var disk_option = $MarginC/VBoxC/HBoxC4/DiskOption

signal cancel_pressed
signal file_selected


func _ready():
	Logger.add_module("FileExplorer")
	
	# Disk option is Windows only.
	if OS.get_name() == "Windows":
		for i in range(file_tree.dir.get_drive_count()):
			var drive_name = file_tree.dir.get_drive(i)
			disk_option.add_item(drive_name)
		disk_option.select(file_tree.dir.get_current_drive())
	else:
		disk_option.hide()
	
	_on_FileTree_current_dir_changed(file_tree.get_current_dir())
	
	file_tree.setup()


func change_mode(new_mode):
	mode = new_mode
	
	match mode:
		Modes.OPEN:
			# When opening a file, no need to show the file name edit.
			$MarginC/VBoxC/FileNameBox.hide()
		Modes.EXPORT:
			pass


func _on_Cancel_pressed():
	emit_signal("cancel_pressed")


func _on_FileTree_current_dir_changed(new_dir : String):
	if not new_dir in dir_history:
		dir_history.append(new_dir)
		if dir_history.size() > 10:
			dir_history.remove(0)
	
	if OS.get_name() == "Windows":
		var drive_name = file_tree.dir.get_drive(file_tree.dir.get_current_drive())
		new_dir = new_dir.trim_prefix(drive_name)
	
	address_edit.text = new_dir


func _on_Upward_pressed():
	file_tree.go_upward()


func _on_NewFolder_pressed():
	var err = file_tree.dir.make_dir("New folder")
	file_tree.relist_dir()


func _on_Backward_pressed():
	pass # Replace with function body.


func _on_Forward_pressed():
	pass # Replace with function body.


func _on_DiskOption_item_selected(index):
	var drive_name = file_tree.dir.get_drive(index)
	file_tree.go_to(drive_name)


func _on_Go_pressed():
	file_tree.go_to(file_tree.get_current_drive_name() + address_edit.text)


func _on_FileTree_file_selected(full_file_path):
	emit_signal("file_selected", full_file_path)
