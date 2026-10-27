class_name DroneTextureFactory
extends RefCounted

static func create_miner_drone_texture() -> ImageTexture:
	var img = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	var body = Color(0.25, 0.28, 0.32, 1.0)
	var rotor = Color(0.70, 0.75, 0.80, 0.9)
	var light = Color(0.20, 0.85, 1.00, 1.0)
	var motor = Color(0.12, 0.14, 0.16, 1.0)

	for x in range(32):
		for y in range(24):
			# Central streamlined drone body
			if (y in range(9, 17) and x in range(10, 22)):
				img.set_pixel(x, y, body)
			# Front searchlight
			if y in range(12, 15) and x in range(20, 24):
				img.set_pixel(x, y, light)
			# Quad motor arms
			if (y in range(7, 10) and (x in range(4, 11) or x in range(21, 28))):
				img.set_pixel(x, y, motor)
			# Spinning rotor blade blur
			if (y == 6 and (x in range(1, 13) or x in range(19, 31))):
				img.set_pixel(x, y, rotor)
	return ImageTexture.create_from_image(img)

static func create_cargo_drone_texture() -> ImageTexture:
	var img = Image.create(36, 28, false, Image.FORMAT_RGBA8)
	var body = Color(0.85, 0.55, 0.15, 1.0)
	var frame = Color(0.20, 0.22, 0.25, 1.0)
	var rotor = Color(0.75, 0.80, 0.85, 0.85)
	var magnet = Color(0.90, 0.15, 0.15, 1.0)

	for x in range(36):
		for y in range(28):
			if (y in range(8, 18) and x in range(11, 25)):
				img.set_pixel(x, y, body)
			if (y in range(6, 9) and (x in range(3, 12) or x in range(24, 33))):
				img.set_pixel(x, y, frame)
			if (y == 5 and (x in range(1, 14) or x in range(22, 35))):
				img.set_pixel(x, y, rotor)
			# Underslung magnetic collector winch
			if y in range(19, 24) and x in range(15, 21):
				img.set_pixel(x, y, magnet)
	return ImageTexture.create_from_image(img)
