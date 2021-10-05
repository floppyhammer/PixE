extends Panel


onready var file_mb = $VBoxContainer/HBoxContainer/File


func _ready():
	_reload()


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


func _when_file_entry_pressed(index):
	match index:
		0:
			$NewSpriteDialog.popup()
		1:
			$OpenSpriteDialog.popup()
		8:
			get_tree().quit()


func _on_Browser_article_pressed(url):
	$Reader.prepare(url)


func _on_Words_pressed():
	$VBoxC/Middle.current_tab = 0
	
	$VBoxC/Top.show()


func _on_Pictures_pressed():
	$VBoxC/Middle.current_tab = 1
	
	$VBoxC/Top.show()


func _on_Audio_pressed():
	$VBoxC/Middle.current_tab = 2
	
	$VBoxC/Top.show()


func _on_About_pressed():
	$VBoxC/Middle.current_tab = 3
	
	$VBoxC/Top.hide()


func _on_BrowserImages_image_pressed():
	$ImageViewer.show()
