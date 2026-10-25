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
			if (y >= 14 and y <= 17 and x >= 3 and x <= 28) or (x >= 13 and x <= 18 and y >= 8 and y <= 23):
				img.set_pixel(x, y, blue)
			elif (y in [13, 18] and x >= 10 and x <= 21):
				img.set_pixel(x, y, white)
			elif x >= 27 and x <= 30 and y >= 15 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_agent_orange_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var green = Color(0.15, 0.75, 0.25, 1.0)
	var dark_green = Color(0.08, 0.45, 0.15, 1.0)
	var yellow = Color(1.0, 0.85, 0.15, 1.0)
	for x in range(32):
		for y in range(32):
			if (y >= 13 and y <= 17 and x >= 4 and x <= 28) or (x >= 12 and x <= 19 and y >= 9 and y <= 22):
				img.set_pixel(x, y, green)
			elif y in [12, 18] and x >= 8 and x <= 23:
				img.set_pixel(x, y, dark_green)
			elif x >= 27 and x <= 30 and y >= 14 and y <= 16:
				img.set_pixel(x, y, yellow)
	return ImageTexture.create_from_image(img)

static func create_b52_texture() -> ImageTexture:
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var camo_dark = Color(0.22, 0.26, 0.22, 1.0)
	var camo_light = Color(0.38, 0.44, 0.35, 1.0)
	var cockpit = Color(0.65, 0.85, 0.95, 1.0)
	for x in range(40):
		for y in range(40):
			if (y >= 17 and y <= 22 and x >= 2 and x <= 37) or (x >= 15 and x <= 24 and y >= 5 and y <= 34):
				img.set_pixel(x, y, camo_dark if (x + y) % 3 == 0 else camo_light)
			elif x in range(32, 36) and y in range(18, 21):
				img.set_pixel(x, y, cockpit)
	return ImageTexture.create_from_image(img)

static func create_fireball_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var core = Color(1.0, 0.95, 0.3, 1.0)
	var outer = Color(0.95, 0.25, 0.1, 1.0)
	for x in range(16):
		for y in range(16):
			var dist = (x - 8)*(x - 8) + (y - 8)*(y - 8)
			if dist <= 16:
				img.set_pixel(x, y, core)
			elif dist <= 36:
				img.set_pixel(x, y, outer)
	return ImageTexture.create_from_image(img)

static func create_water_drop_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var core = Color(0.4, 0.85, 1.0, 1.0)
	var outer = Color(0.1, 0.45, 0.9, 1.0)
	for x in range(16):
		for y in range(16):
			var dist = (x - 8)*(x - 8) + (y - 8)*(y - 8)
			if dist <= 16:
				img.set_pixel(x, y, core)
			elif dist <= 36:
				img.set_pixel(x, y, outer)
	return ImageTexture.create_from_image(img)

static func create_heavy_bomb_texture() -> ImageTexture:
	var img = Image.create(18, 18, false, Image.FORMAT_RGBA8)
	var iron = Color(0.2, 0.2, 0.22, 1.0)
	var yellow = Color(0.95, 0.8, 0.1, 1.0)
	for x in range(18):
		for y in range(18):
			var dist = (x - 9)*(x - 9) + (y - 9)*(y - 9)
			if dist <= 32:
				img.set_pixel(x, y, yellow if x % 4 == 0 else iron)
	return ImageTexture.create_from_image(img)
