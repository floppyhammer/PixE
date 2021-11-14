extends Panel

onready var file_mb = $VBoxC/MenuBar/HBoxC/File
onready var edit_mb = $VBoxC/MenuBar/HBoxC/Edit
onready var image_mb = $VBoxC/MenuBar/HBoxC/Image
onready var view_mb = $VBoxC/MenuBar/HBoxC/View
onready var tabs = $VBoxC/MenuBar/Tabs
onready var tab_c = $VBoxC/TabC

var current_editor = null

var editor_scene = preload("res://scenes/core/Editor.tscn")

var loaded_image : Image = Image.new()

func _ready():
	_reload()
	
	get_tree().connect("files_dropped", self, "_get_dropped_files_path")


func _reload():
	var popup_menu = file_mb.get_popup()
	
	popup_menu.add_item("New...")
	popup_menu.add_item("Open...")
	popup_menu.add_separator("")
	popup_menu.add_item("Import...")
	popup_menu.add_item("Export...")
	popup_menu.add_separator("")
	popup_menu.add_item("Close")
	popup_menu.add_item("Close All")
	popup_menu.add_item("Quit")
	popup_menu.connect("index_pressed", self, "_when_file_entry_pressed")

	popup_menu = edit_mb.get_popup()

	popup_menu.add_item("Undo")
	popup_menu.add_item("Redo")
	popup_menu.add_separator("")
	popup_menu.add_item("Cut")
	popup_menu.add_item("Copy")
	popup_menu.add_item("Paste")
	popup_menu.add_separator("")
	popup_menu.add_item("Clear")
	popup_menu.add_separator("")
	popup_menu.add_item("Preferences")
	popup_menu.connect("index_pressed", self, "edit_mb_pressed")
	
	popup_menu = image_mb.get_popup()
	popup_menu.add_item("Canvas Size...")
	popup_menu.add_item("Image Size...")
	
	popup_menu = view_mb.get_popup()
	popup_menu.add_check_item("Grid")
	popup_menu.add_item("Center Image")
	
	tabs.add_tab("Home")
	tabs.add_tab("New")
	tabs.set_tab_close_display_policy(tabs.CLOSE_BUTTON_SHOW_ALWAYS)


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
		2:
			_on_Tabs_tab_close(tabs.current_tab)
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


func _on_Tabs_tab_close(tab):
	# Remove from tabs.
	tabs.remove_tab(tab)
	
	# Remove from tab container and tree.
	var closed_tab = tab_c.get_child(tab)
	tab_c.remove_child(closed_tab)
	closed_tab.free()


func _on_Cancel_pressed():
	$NewSpriteDialog.hide()
