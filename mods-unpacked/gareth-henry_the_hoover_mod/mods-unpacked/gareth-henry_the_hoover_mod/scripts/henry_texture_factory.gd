class_name HenryTextureFactory
extends RefCounted

# High-fidelity procedural render based on the official Numatic Henry 200 reference image
static func create_henry_texture(level: int) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)

	var body_color: Color
	match level:
		1: body_color = Color(0.88, 0.12, 0.14, 1.0) # Classic Henry Red
		2: body_color = Color(0.96, 0.42, 0.68, 1.0) # Hetty Pink
		3: body_color = Color(0.14, 0.48, 0.92, 1.0) # Harry Blue
		4: body_color = Color(0.12, 0.72, 0.28, 1.0) # George Green
		_: body_color = Color(0.95, 0.82, 0.12, 1.0) # Charles Yellow

	var bowler_black = Color(0.08, 0.08, 0.10, 1.0)
	var bowler_highlight = Color(0.24, 0.24, 0.28, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var eye_pupil = Color(0.06, 0.06, 0.08, 1.0)
	var nose_ring = Color(0.18, 0.18, 0.20, 1.0)
	var nose_hole = Color(0.02, 0.02, 0.02, 1.0)

	for x in range(64):
		for y in range(64):
			# 1. Bowler Hat Top Dome (Y: 6-28, X: 14-50)
			var hat_dx = (x - 32) * (x - 32)
			var hat_dy = (y - 20) * (y - 20)
			if hat_dx + hat_dy <= 290 and y <= 28:
				if hat_dx + hat_dy <= 120 and y <= 16:
					img.set_pixel(x, y, bowler_highlight)
				else:
					img.set_pixel(x, y, bowler_black)

			# 2. Bowler Hat Rim (Y: 26-30, X: 10-54)
			if y in range(26, 31) and x in range(10, 55):
				img.set_pixel(x, y, bowler_black)

			# 3. Cylindrical Canister Body (Y: 30-58, X: 12-52)
			var body_dx = (x - 32) * (x - 32)
			if x in range(13, 52) and y in range(30, 58):
				if body_dx <= 360:
					# Subtle 3D cylinder edge shading
					if x in range(13, 17) or x in range(48, 52):
						img.set_pixel(x, y, body_color.darkened(0.25))
					elif x in range(20, 26):
						img.set_pixel(x, y, body_color.lightened(0.15))
					else:
						img.set_pixel(x, y, body_color)

			# 4. Large Arched Eyes (Y: 34-44, Left: 18-28, Right: 36-46)
			# Left Eye
			if (x - 23)*(x - 23) + (y - 39)*(y - 39) <= 22:
				img.set_pixel(x, y, white)
			# Left Pupil (looking cheekily forward)
			if (x - 24)*(x - 24) + (y - 39)*(y - 39) <= 7:
				img.set_pixel(x, y, eye_pupil)

			# Right Eye
			if (x - 41)*(x - 41) + (y - 39)*(y - 39) <= 22:
				img.set_pixel(x, y, white)
			# Right Pupil
			if (x - 40)*(x - 40) + (y - 39)*(y - 39) <= 7:
				img.set_pixel(x, y, eye_pupil)

			# 5. Nose Hose-Coupling Port (Y: 41-51, X: 27-37)
			var nose_d = (x - 32)*(x - 32) + (y - 46)*(y - 46)
			if nose_d <= 25:
				img.set_pixel(x, y, nose_ring)
			if nose_d <= 12:
				img.set_pixel(x, y, nose_hole)

			# 6. Classic Curved Cheerful Smile (Y: 50-55, X: 22-43)
			if y in range(50, 54):
				var smile_arc = 51 + int(round(pow(float(x - 32) / 8.0, 2)))
				if y == smile_arc and x in range(20, 45):
					img.set_pixel(x, y, bowler_black)

	return ImageTexture.create_from_image(img)
