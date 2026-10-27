class_name TeletubbiesTextureFactory
extends RefCounted

static func create_noo_noo_texture(level: int) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var body_color: Color
	match level:
		1: body_color = Color(0.12, 0.35, 0.85, 1.0) # Classic Navy Blue
		2: body_color = Color(0.95, 0.45, 0.30, 1.0) # Revival Pink/Orange
		_: body_color = Color(0.85, 0.75, 0.20, 1.0) # Golden Noo-Noo

	var silver = Color(0.75, 0.78, 0.82, 1.0)
	var eye_w  = Color(1.0, 1.0, 1.0, 1.0)
	var eye_b  = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(32):
		for y in range(32):
			var dist = (x - 16)*(x - 16) + (y - 18)*(y - 18)
			# Domed main body
			if dist <= 120 and y >= 10:
				img.set_pixel(x, y, body_color)
			# Googly eyes on stalks
			if (y in range(5, 10) and (x in range(9, 14) or x in range(18, 23))):
				img.set_pixel(x, y, eye_w)
			if (y in range(6, 8) and (x == 11 or x == 20)):
				img.set_pixel(x, y, eye_b)
			# Flared trumpet snout
			if (y in range(18, 26) and x in range(13, 19)) or (y in range(23, 27) and x in range(11, 21)):
				img.set_pixel(x, y, silver)

	return ImageTexture.create_from_image(img)

static func create_baby_sun_texture(yawning: bool) -> ImageTexture:
	var img = Image.create(44, 44, false, Image.FORMAT_RGBA8)
	var sun_gold = Color(1.0, 0.85, 0.20, 1.0)
	var ray_color = Color(1.0, 0.65, 0.15, 0.9)
	var cheek_pink = Color(1.0, 0.60, 0.65, 1.0)
	var face_dark = Color(0.35, 0.15, 0.05, 1.0)

	for x in range(44):
		for y in range(44):
			var dist = (x - 22)*(x - 22) + (y - 22)*(y - 22)
			# Radiant outer corona
			if dist <= 380 and dist > 225 and (x + y) % 3 == 0:
				img.set_pixel(x, y, ray_color)
			# Inner golden face disk
			if dist <= 225:
				img.set_pixel(x, y, sun_gold)
			# Rosy baby cheeks
			if dist <= 180 and y in range(23, 27) and (x in range(13, 17) or x in range(27, 31)):
				img.set_pixel(x, y, cheek_pink)
			# Baby eyes
			if dist <= 180 and y in range(17, 20) and (x in range(15, 19) or x in range(25, 29)):
				img.set_pixel(x, y, face_dark)
			# Mouth: smiling or yawning
			if dist <= 180:
				if yawning:
					if y in range(24, 30) and x in range(19, 25):
						img.set_pixel(x, y, face_dark)
				else:
					if y == 26 and x in range(18, 26):
						img.set_pixel(x, y, face_dark)

	return ImageTexture.create_from_image(img)
