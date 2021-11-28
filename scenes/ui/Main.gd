extends Panel

onready var file_mb = $VBoxC/MenuBar/HBoxC/File
onready var edit_mb = $VBoxC/MenuBar/HBoxC/Edit
onready var image_mb = $VBoxC/MenuBar/HBoxC/Image
onready var view_mb = $VBoxC/MenuBar/HBoxC/View
onready var help_mb = $VBoxC/MenuBar/HBoxC/Help
onready var tabs = $VBoxC/MenuBar/Tabs
onready var tab_c = $VBoxC/TabC

var current_editor = null

var editor_scene = preload("res://scenes/core/Editor.tscn")

var loaded_image : Image = Image.new()

func _ready():
	Logger.add_module("Editor")
	Logger.add_module("Canvas")
	
	_reload()
	
	get_tree().connect("files_dropped", self, "_get_dropped_files_path")


func _reload():
	var popup_menu = file_mb.get_popup()
	
	popup_menu.add_item("New..")
	popup_menu.add_item("Open..")
	popup_menu.add_separator("")
	popup_menu.add_item("Import..")
	popup_menu.add_item("Export..")
	popup_menu.add_separator("")
	popup_menu.add_item("Close")
	popup_menu.add_item("Close All")
	popup_menu.add_separator("")
	popup_menu.add_item("Settings..")
	popup_menu.add_item("Quit")
	popup_menu.connect("index_pressed", self, "_file_mb_pressed")

	popup_menu = edit_mb.get_popup()

	popup_menu.add_item("Undo")
	popup_menu.add_item("Redo")
	popup_menu.add_separator("")
	popup_menu.add_item("Cut")
	popup_menu.add_item("Copy")
	popup_menu.add_item("Paste")
	popup_menu.add_item("Delete")
	popup_menu.add_separator("")
	popup_menu.add_item("Clear")
	popup_menu.connect("index_pressed", self, "_edit_mb_pressed")
	
	popup_menu = image_mb.get_popup()
	popup_menu.add_item("Canvas Size..")
	popup_menu.add_item("Image Size..")
	popup_menu.connect("index_pressed", self, "_image_mb_pressed")
	
	popup_menu = view_mb.get_popup()
	popup_menu.add_check_item("Grid")
	popup_menu.add_item("Center Image")
	
	popup_menu = help_mb.get_popup()
	popup_menu.add_item("About")
	
	help_mb
	tabs.add_tab("Home")
	tabs.add_tab("New")
	tabs.set_tab_close_display_policy(tabs.CLOSE_BUTTON_SHOW_ACTIVE_ONLY)


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
		var file_name = file_path.get_basename().trim_prefix(file_path.get_base_dir())
		
		tab_c.add_child(new_editor)
		tabs.add_tab(file_name)
		tab_c.current_tab = tab_c.get_tab_count() - 1
		tabs.current_tab = tabs.get_tab_count() - 1
		
		current_editor = new_editor
		
		print("Dropped in file " + file_path)


func _file_mb_pressed(index):
	match index:
		0:
			$WindowNewImage.show()
		1:
			$WindowOpenImage.show()
		3:
			$WindowOpenImage.show()
		4:
			$WindowExport.show()
		6:
			_on_Tabs_tab_close(tabs.current_tab)
		7:
			for i in range(tab_c.get_child_count()):
				_on_Tabs_tab_close(0)
			current_editor = null
		9:
			get_tree().quit()


func _edit_mb_pressed(index):
	if not current_editor: return
	
	match index:
		0:
			current_editor.undo_canvas()
		1:
			current_editor.redo_canvas()


func _image_mb_pressed(index):
	if not current_editor: return
	
	match index:
		0:
			pass
		1:
			$WindowImageSize.custom_show(current_editor.canvas.IMAGE_SIZE)


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


func _on_WindowImageSize_size_changed(new_size : Vector2, interpolation):
	if current_editor:
		current_editor.change_image_size(new_size, interpolation)
