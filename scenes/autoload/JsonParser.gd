extends Node


# Load a josn file as a dictionary
func load_data(url : String) -> Dictionary:
	var file = File.new()
	
	# If the url is invalid or the file does not exist, return nothing
	if url == null or !file.file_exists(url):
		print('[Error] The URL for JSON parsing is not valid!')
		return {}
	
	# Open the JSON file
	file.open(url, File.READ)
	
	# Get the JSON result
	var json_result = JSON.parse(file.get_as_text())
	
	# Monitor error message from the JSON processing
	if json_result.error_string != '':
		print('[Error] JSON Parser: %s' % json_result.error_string)
		print('[Error] JSON Parser, error on line: %d' % json_result.error_line)
		return {}
	
	# Get a dictionary from the JSON result
	var data = json_result.result
	
	# Close the JSON file
	file.close()
	
	return data


# Save a dictionary as a josn file
func write_data(url : String, dict : Dictionary) -> int:
	# If the url is invalid, return nothing
	if url == null:
		print('The URL for saving the JSON file is invalid!')
		return FAILED
	
	# Save the dictionary into a JSON file
	var file = File.new()
	var err = file.open(url, File.WRITE)
	
	if err != OK:
		print('Cannot open the file at: %s!' % url)
		print("Error code: ", err)
		return FAILED
	
	#file.store_line(JSONBeautifier.beautify_json(JSON.print(dict)))
	file.close()
	
	return OK


func create_dir(dir_ : String) -> int:
	var dir = Directory.new()
	
	if not dir.dir_exists(dir_):
		var err = dir.make_dir(dir_)
		
		if err != OK:
			print('Failed to create directory: %s' % dir_)
			return FAILED
	
	return OK
