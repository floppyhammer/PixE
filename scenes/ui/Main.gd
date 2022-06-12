extends Panel

onready var home_panel = $VBoxC/Home

onready var file_mb = $VBoxC/MenuBar/HBoxC/File
onready var image_mb = $VBoxC/MenuBar/HBoxC/Image
onready var view_mb = $VBoxC/MenuBar/HBoxC/View
onready var help_mb = $VBoxC/MenuBar/HBoxC/Help

onready var tabs = $VBoxC/MenuBar/Tabs
onready var tab_c = $VBoxC/TabC

var current_editor = null

var editor_scene = preload("res://scenes/core/Editor.tscn")

var loaded_image : Image = Image.new()

func _ready():
	Logger.add_module("Main")
	Logger.add_module("Editor")
	Logger.add_module("Canvas")
	Logger.add_module("FileExplorer")
	
	# Set menu bar.
	_reload_menu_bar()
	_disable_editor_options_in_menu_bar(true)
	
	home_panel.show()
	tab_c.hide()
	tabs.set_tab_close_display_policy(tabs.CLOSE_BUTTON_SHOW_ACTIVE_ONLY)
	
	# Connect file dropping signal.
	get_tree().connect("files_dropped", self, "_get_dropped_files_path")


func _reload_menu_bar():
	var popup_menu = file_mb.get_popup()
	popup_menu.clear()
	popup_menu.add_item("New...")
	popup_menu.add_item("Open...")
	popup_menu.add_separator("")
	popup_menu.add_item("Import...")
	popup_menu.add_item("Export...")
	popup_menu.add_separator("")
	popup_menu.add_item("Close")
	popup_menu.add_item("Close All")
	popup_menu.add_separator("")
	popup_menu.add_item("Settings...")
	popup_menu.add_separator("")
	popup_menu.add_item("Quit")
	popup_menu.connect("index_pressed", self, "_file_mb_pressed")

	popup_menu = image_mb.get_popup()
	popup_menu.clear()
	popup_menu.add_item("Canvas Size...")
	popup_menu.add_item("Image Size...")
	popup_menu.connect("index_pressed", self, "_image_mb_pressed")
	
	popup_menu = view_mb.get_popup()
	popup_menu.clear()
#	popup_menu.add_check_item("Axes")
#	popup_menu.add_check_item("Grid")
#	popup_menu.add_check_item("Checked")
	popup_menu.add_item("Center Image")
	
	popup_menu = help_mb.get_popup()
	popup_menu.clear()
	popup_menu.add_item("About")
	popup_menu.connect("index_pressed", self, "_help_mb_pressed")


func _disable_editor_options_in_menu_bar(disabled : bool):
	var popup_menu = file_mb.get_popup()
	popup_menu.set_item_disabled(3, disabled)
	popup_menu.set_item_disabled(4, disabled)
	
	if tab_c.get_child_count() > 0:
		popup_menu.set_item_disabled(6, false)
		popup_menu.set_item_disabled(7, false)
	else:
		popup_menu.set_item_disabled(6, true)
		popup_menu.set_item_disabled(7, true)
	
	if disabled:
		image_mb.disabled = true
		view_mb.disabled = true
	else:
		image_mb.disabled = false
		view_mb.disabled = false


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
			pass
		11:
			get_tree().quit()


func _image_mb_pressed(index):
	if not current_editor: return
	
	match index:
		0:
			pass
		1:
			$WindowImageSize.custom_show(current_editor.canvas.IMAGE_SIZE)


func _help_mb_pressed(index):
	match index:
		0:
			$WindowAbout.show()


func _get_dropped_files_path(files : PoolStringArray, screen : int) -> void:
	if not files.empty():
		var file_path : String = files[0]
		var err = loaded_image.load(file_path)
		if err != OK:
			return
		
		var img_size = loaded_image.get_size()
		
		var file_name = file_path.get_file()
		
		_add_editor(img_size, file_name, loaded_image)
		
		Logger.info("Dropped in file " + file_path, "Main")


func _add_editor(img_size : Vector2, file_name : String, loaded_image):
	if img_size.x == 0 or img_size.y == 0: return
	
	var new_editor = editor_scene.instance()
	tab_c.add_child(new_editor)
	new_editor.call_deferred("setup", img_size, loaded_image)
	tabs.add_tab(file_name)
	tab_c.current_tab = tab_c.get_tab_count() - 1
	tabs.current_tab = tabs.get_tab_count() - 1
	
	current_editor = new_editor
	
	home_panel.hide()
	tab_c.show()
	
	_disable_editor_options_in_menu_bar(false)


func _on_Tabs_tab_changed(tab):
	tab_c.current_tab = tab
	
	current_editor = tab_c.get_child(tab)


func _on_Tabs_tab_close(tab):
	# Remove from tabs.
	tabs.remove_tab(tab)
	
	# Remove from tab container and tree.
	var closed_tab = tab_c.get_child(tab)
	tab_c.remove_child(closed_tab)
	closed_tab.free()
	
	# Reset current editor.
	if tab_c.get_child_count() > 0:
		tab_c.current_tab = tabs.current_tab
		current_editor = tab_c.get_child(tabs.current_tab)
	else: # If no editor left, show the home panel.
		home_panel.show()
		tab_c.hide()
		current_editor = null


# Change image size.
func _on_WindowImageSize_size_changed(new_size : Vector2, interpolation):
	if current_editor:
		current_editor.change_image_size(new_size, interpolation)


func _on_New_pressed():
	$WindowNewImage.show()


func _on_Open_pressed():
	$WindowOpenImage.show()


func _on_ColorPicker_color_changed(color):
	if current_editor:
		current_editor.change_palette_current_color(color)


func _on_New_color_picker_called():
	$WindowColorPicker.custom_show()


func _on_WindowNewImage_ok_pressed(img_size : Vector2):
	_add_editor(img_size, "New", null)
