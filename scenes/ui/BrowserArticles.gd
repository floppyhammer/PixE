extends Control

onready var tree = $Tree

var db : Dictionary

signal article_pressed

func _ready():
	db = JsonParser.load_data('res://dbs/articles/index.json')

	_reload_tree()


func _reload_tree():
	# Clear tree
	tree.clear()
	
	# Create root
	var root = tree.create_item()
	
	# Add items
	for author_key in db:
		var author_item = add_tree_branch(tree, root, author_key)
		
		for volume_key in db[author_key]:
			var volume_item = add_tree_branch(tree, author_item, volume_key)
			
			for article_key in db[author_key][volume_key]:
				var article_data = db[author_key][volume_key][article_key]
				var text = '%s. %s' % [article_key, article_data["title"]]
				var article_item = add_tree_leaf(tree, volume_item, text, article_data["url"])
	
	return


func add_tree_branch(p_tree : Tree, p_branch : TreeItem, p_text : String) -> TreeItem:
	var branch = tree.create_item(p_branch)
	branch.set_text(0, p_text)
	branch.set_tooltip(0, ' ')
	branch.set_selectable(0, false)
	
	return branch


func add_tree_leaf(p_tree : Tree, p_branch : TreeItem, p_text : String, p_meta) -> TreeItem:
	var leaf = p_tree.create_item(p_branch)
	leaf.set_text(0, p_text)
	leaf.set_tooltip(0, ' ')
	leaf.set_metadata(0, p_meta)
	
	return leaf


func _on_Tree_item_selected():
	var url = tree.get_selected().get_metadata(0)
	emit_signal('article_pressed', url)
