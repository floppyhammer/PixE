extends Control


var title : String
var content : String
var refs : Dictionary

onready var article_title_label = $VBoxC/PanelC/HBoxC/Title
onready var content_label = $VBoxC/RichTextLabel
onready var ref_title_label = $Panel/Panel/VBoxC/Title
onready var ref_content_label = $Panel/Panel/VBoxC/Content


# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel.hide()


func prepare(url):
	var data = JsonParser.load_data(url)

	title = data['title']
	content = data['content']
	refs = data['refs']
	
	article_title_label.text = title
	content_label.bbcode_text = content
	
	show()


func _on_RichTextLabel_meta_clicked(meta):
	print('Clicked on ', meta)
	
	if meta.begins_with('ref'):
		var ref_no = meta.to_int()
		ref_title_label.text = '引用%d' % ref_no
		ref_content_label.text = refs[str(ref_no)]
		ref_content_label.scroll_to_line(0)
	$Panel.show()


func _on_Panel_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed == false:
			$Panel.hide()


func _on_Back_pressed():
	hide()


func _on_RichTextLabel_gui_input(event):
	return
	if event is InputEventScreenTouch:
		if event.pressed == false:
			$MenuPanel.show()


func _on_MenuPanel_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed == false:
			$MenuPanel.hide()
