extends Control

var img_url = "https://i.pximg.net/img-original/img/2021/01/11/22/24/37/86989689_p0.png"
onready var http_request = $HTTPRequest
onready var tex_rect = $ScrollC/VBoxC/Item/VBoxC/TextureRect
signal image_pressed


func _ready():
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request(img_url)
	if http_error != OK:
		print("An error occurred in the HTTP request.")
	print(2)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print(1)
	print(result, response_code, headers, body)
	var image = Image.new()
	var image_error = image.load_jpg_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image as jpg.")
		image_error = image.load_png_from_buffer(body)
		if image_error != OK:
			print("An error occurred while trying to display the image as png.")
			image_error = image.load_webp_from_buffer(body)
			if image_error != OK:
				print("An error occurred while trying to display the image as webp.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	tex_rect.texture = texture


func _on_Item_pressed():
	emit_signal("image_pressed")
