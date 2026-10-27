class_name HenryTextureFactory
extends RefCounted

static func create_henry_texture(level: int) -> ImageTexture:
	var img = Image.create(28, 28, false, Image.FORMAT_RGBA8)
	var body_color: Color
	match level:
		1: body_color = Color(0.92, 0.15, 0.15, 1.0) # Henry (Red)
		2: body_color = Color(0.95, 0.45, 0.70, 1.0) # Hetty (Pink)
		3: body_color = Color(0.20, 0.55, 0.95, 1.0) # Harry (Blue)
		4: body_color = Color(0.18, 0.75, 0.28, 1.0) # George (Green)
		_: body_color = Color(0.95, 0.85, 0.18, 1.0) # Charles (Yellow)

	var hat_color = Color(0.12, 0.12, 0.14, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var black = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(28):
		for y in range(28):
			var dist = (x - 14)*(x - 14) + (y - 15)*(y - 15)
			# Cylindrical body
			if dist <= 100 and y >= 8:
				img.set_pixel(x, y, body_color)
			# Bowler hat rim & crown
			if (y in range(5, 8) and x in range(6, 22)) or (y in range(2, 6) and x in range(9, 19)):
				img.set_pixel(x, y, hat_color)
			# Smiling eyes
			if y in range(12, 15) and (x in range(9, 12) or x in range(16, 19)):
				img.set_pixel(x, y, white)
			if y == 13 and (x == 10 or x == 17):
				img.set_pixel(x, y, black)
			# Hose snout / mouth
			if y in range(16, 20) and x in range(12, 16):
				img.set_pixel(x, y, black)
			# Cheerful smile line
			if y == 21 and x in range(10, 18):
				img.set_pixel(x, y, black)

	return ImageTexture.create_from_image(img)
