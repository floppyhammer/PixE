extends Panel

onready var file_mb = $VBoxC/MenuBar/File
onready var edit_mb = $VBoxC/MenuBar/Edit
onready var tabs = $VBoxC/MenuBar/Tabs
onready var tab_c = $VBoxC/TabC

var current_editor = null

var editor_scene = preload("res://scenes/core/Editor.tscn")

var loaded_image : Image = Image.new()

func _ready():
	_reload()
	
	get_tree().connect("files_dropped", self, "_get_dropped_files_path")


func _reload():
	file_mb.get_popup().add_item("New")
	file_mb.get_popup().add_item("Open")
	file_mb.get_popup().add_item("Close")
	file_mb.get_popup().add_item("Close All")
	file_mb.get_popup().add_separator("")
	file_mb.get_popup().add_item("Import")
	file_mb.get_popup().add_item("Export")
	file_mb.get_popup().add_separator("")
	file_mb.get_popup().add_item("Exit")
	file_mb.get_popup().connect("index_pressed", self, "_when_file_entry_pressed")

	edit_mb.get_popup().add_item("Undo")
	edit_mb.get_popup().add_item("Redo")
	edit_mb.get_popup().connect("index_pressed", self, "edit_mb_pressed")
	
	
	tabs.add_tab("Home")
	tabs.add_tab("New")


func _get_dropped_files_path(files : PoolStringArray, screen : int) -> void:
	if not files.empty():
		var file_path : String = files[0]
		var err = loaded_image.load(file_path)
		if err != OK:
			return
		
		var img_size = loaded_image.get_size()
		if img_size.x == 0 or img_size.y == 0: return
		
		var new_editor = editor_scene.instance()
		new_editor.call_deferred("setup", img_size, loaded_image)
		var file_name = file_path.get_basename().trim_prefix(file_path.get_base_dir() + "/")
		
		tab_c.add_child(new_editor)
		tabs.add_tab(file_name)
		
		current_editor = new_editor


func _when_file_entry_pressed(index):
	match index:
		0:
			$NewSpriteDialog.popup()
		1:
			$OpenSpriteDialog.popup()
		8:
			get_tree().quit()


func edit_mb_pressed(index):
	if not current_editor: return
	
	match index:
		0:
			current_editor.undo_canvas()
		1:
			current_editor.redo_canvas()


func _on_Tabs_tab_changed(tab):
	tab_c.current_tab = tab
	
	if tab == 0:
		current_editor = null
	else:
		current_editor = tab_c.get_child(tab)
