class_name HenryTextureFactory
extends RefCounted

static func apply_henry_skin(sprite: Sprite2D, tier: int) -> void:
	if not is_instance_valid(sprite): return
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var body = Color(0.88, 0.12, 0.14, 1.0)
	match tier:
		2: body = Color(0.96, 0.42, 0.68, 1.0) # Hetty Pink
		3: body = Color(0.14, 0.48, 0.92, 1.0) # Harry Blue
		4: body = Color(0.12, 0.72, 0.28, 1.0) # George Green
		5: body = Color(0.95, 0.82, 0.12, 1.0) # Charles Yellow
	
	var black = Color(0.1, 0.1, 0.1, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	
	for x in range(8, 24):
		for y in range(4, 12):
			img.set_pixel(x, y, black)
	for x in range(4, 28):
		img.set_pixel(x, 12, black)
		
	for x in range(6, 26):
		for y in range(13, 30):
			img.set_pixel(x, y, body)
			
	for x in range(10, 14):
		for y in range(16, 20):
			img.set_pixel(x, y, white)
			if x > 11 and y > 17: img.set_pixel(x, y, black)
	for x in range(18, 22):
		for y in range(16, 20):
			img.set_pixel(x, y, white)
			if x > 19 and y > 17: img.set_pixel(x, y, black)
			
	for x in range(14, 18):
		for y in range(20, 24):
			img.set_pixel(x, y, black)
			
	for x in range(10, 22):
		var sy = 26 + int(abs(x - 15.5) * 0.3)
		if sy < 32:
			img.set_pixel(x, sy, black)
			
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.offset = Vector2(0, -16)
