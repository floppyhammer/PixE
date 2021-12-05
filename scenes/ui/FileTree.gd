extends Tree

var dir = Directory.new()

# Default dir for different platforms.
var start_urls = {
	"Android": '/storage/emulated/0',
	"X11": "/usr",
	"Windows": "C:/users",
}

var current_drive
var drive_count : int

signal file_selected
signal quit_pressed
signal current_dir_changed

var touch_points = [null, null]

# 选择项目信号发出时不要更新树，会导致阻塞，激活项目信号发出时没关系

func setup():
	drive_count = dir.get_drive_count()
	current_drive = dir.get_current_drive()
	
	# 要求权限的过程是并发的，路径更新会发生在取得权限之前
	var perm = OS.get_granted_permissions()
	if perm.empty():
		OS.request_permissions()
	Logger.info('Granted Permissions: %s' % str(perm), "FileExplorer")
	
	# Open the default dir.
	if dir.open(start_urls[OS.get_name()]) == OK:
		relist_dir()
	else:
		Logger.error("Error occurred when trying to access path: %s" % start_urls[OS.get_name()], "FileExplorer")
	
	hide_root = true
	allow_reselect = true
	
	emit_signal("current_dir_changed", dir.get_current_dir())
	
	return


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		go_upward()


func _input(event):
	if event is InputEventScreenTouch:
		# Ignore multitouch
		if event is InputEventScreenTouch:
			if event.index != 0: return

		if event.pressed:
			touch_points[0] = event.position
		else:
			touch_points[1] = event.position

			# If no drag
			if touch_points[0].distance_to(touch_points[1]) < 8:
				_on_item_selected()

			# Deselect item on release
			if get_selected():
				get_selected().deselect(0)

			# Reset touch points on release
			touch_points = [null, null]
	return


func go_to(new_dir):
	var error = dir.change_dir(new_dir)
	
	# If is a valid dir, return.
	if error == 0:
		relist_dir()
		
		emit_signal("current_dir_changed", dir.get_current_dir())
		
		return null
	# If is a file, return the full path
	elif new_dir.get_extension() in ['png']:
		var file_path = dir.get_current_dir() + '/' + new_dir
		
		Logger.info('File selected: %s' % file_path, "FileExplorer")
		
		return file_path
	
	return null


func go_upward():
	var error = dir.change_dir("..")
	if error == 0:
		relist_dir()
		
		emit_signal("current_dir_changed", dir.get_current_dir())
	else:
		Logger.error('Failed to go upward.', "FileExplorer")


func get_current_dir() -> String:
	return dir.get_current_dir()


func relist_dir():
	var dirs = []
	var files = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Is a dir
		if dir.current_is_dir():
			if not file_name.begins_with('.'):
				dirs.append(file_name)
		# Is a file
		else:
			if file_name.get_extension() in ['png']:
				files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	_reload_list(dirs, files)
	
	return


func _reload_list(dirs, files):
	Logger.info('Reload file tree with %d dirs.' % dirs.size(), "FileExplorer")
	Logger.info('Reload tree with %d files.' % files.size(), "FileExplorer")
	
	# Sort
	dirs.sort()
	files.sort()
	
	# Clear tree
	clear()
	
	# Create root
	var root = create_item()
	
	var tree_item
	
	# Add '..' dir to go back, but not for top dirs
#	if not dir.get_current_dir() in start_urls:
#		tree_item = create_item(root)
#		tree_item.set_text(0, '..')
#		tree_item.set_icon(0, ResourceLoader.load('res://assets/graphics/icon_dir.png'))
#		tree_item.set_tooltip(0, ' ')
#		#add_item('..', ResourceLoader.load('res://assets/graphic/icon_dir.png'))
	
	for thing in dirs:
		tree_item = create_item(root)
		tree_item.set_text(0, thing)
		tree_item.set_icon(0, ResourceLoader.load('res://assets/graphics/icon_dir.png'))
		tree_item.set_tooltip(0, ' ')
		#add_item(thing, ResourceLoader.load('res://assets/graphic/icon_dir.png'))
	
	for thing in files:
		tree_item = create_item(root)
		tree_item.set_text(0, thing)
		tree_item.set_icon(0, ResourceLoader.load('res://assets/graphics/icon_file.png'))
		tree_item.set_tooltip(0, ' ')
		#add_item(thing, ResourceLoader.load('res://assets/graphic/icon_file.png'))
	
	# Scroll to the top.
	scroll_to_item(root)
	
	return


# Do not connect this to item_selected() signal
func _on_item_selected():
	if not get_selected(): return
	
	# Sadly tree_item.deselect() does not update tree.get_selected()
	if not get_selected().is_selected(0): return
	
	# Get file name with extension
	var new_dir = get_selected().get_text(0)
	
	Logger.info('Selected: ' + get_selected().get_text(0), "FileExplorer")
	
	#var new_dir = get_item_text(index)
	
	# Go back to the parent dir.
	if new_dir == '..':
		go_upward()
	else:
		var full_file_path = go_to(new_dir)
	
		if full_file_path != null:
			emit_signal("file_selected", full_file_path)
	return
