class_name ElementalAirstrikeTextures
extends RefCounted

static func create_dragon_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var red = Color(0.9, 0.15, 0.1, 1.0)
	var orange = Color(1.0, 0.55, 0.1, 1.0)
	var yellow = Color(1.0, 0.9, 0.2, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 18 and x >= 4 and x <= 27) or (x >= 12 and x <= 20 and y >= 6 and y <= 25):
				img.set_pixel(x, y, red)
			elif (y >= 10 and y <= 12 and x >= 8 and x <= 24) or (x >= 24 and x <= 28 and y >= 14 and y <= 17):
				img.set_pixel(x, y, orange)
			elif x >= 27 and x <= 30 and y >= 15 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_water_bomber_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var blue = Color(0.1, 0.55, 0.95, 1.0)
	var white = Color(0.95, 0.95, 1.0, 1.0)
	var yellow = Color(1.0, 0.85, 0.2, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 14 and y <= 17 and x >= 3 and x <= 28):
				img.set_pixel(x, y, white)
			elif (x >= 14 and x <= 17 and y >= 4 and y <= 27):
				img.set_pixel(x, y, blue)
			elif (y >= 20 and y <= 22 and x >= 10 and x <= 22) or (y >= 9 and y <= 11 and x >= 10 and x <= 22):
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_agent_orange_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var dark_camo = Color(0.2, 0.28, 0.2, 1.0)
	var toxic_green = Color(0.3, 0.95, 0.25, 1.0)
	var dark_metal = Color(0.35, 0.38, 0.35, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 18 and x >= 2 and x <= 29):
				img.set_pixel(x, y, dark_camo)
			elif (abs(x - 16) <= (28 - y) and y >= 6 and y <= 26):
				img.set_pixel(x, y, dark_metal)
			elif (x in [10, 16, 22] and y in [14, 15, 16, 17]):
				img.set_pixel(x, y, toxic_green)
	return ImageTexture.create_from_image(img)
