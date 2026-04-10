extends Node3D

@export var paper_part_scene: PackedScene
@export var width: int = 4
@export var height: int = 4

@export var sprite_size_pixels: Vector2 = Vector2(128, 128)
@export var pixel_ratio: float = 100.0

var parts: Array = []

func _ready() -> void:
	if paper_part_scene:
		setup_grid()

func setup_grid() -> void:
	parts.clear()
	
	var unit_dim = sprite_size_pixels / pixel_ratio

	var total_w = (width - 1) * unit_dim.x
	var total_h = (height - 1) * unit_dim.y
	
	parts.resize(width)
	
	for i in range(width):
		var column = []
		column.resize(height)
		
		for j in range(height):
			var new_part = paper_part_scene.instantiate()
			add_child(new_part)
			
			if "grid_coords" in new_part:
				new_part.grid_coords = Vector2i(i, j)
			
			if new_part.has_signal("clicked"):
				new_part.clicked.connect(_on_part_clicked)
				
			var x_pos = (i * unit_dim.x) - (total_w / 2.0)
			var y_pos = (j * unit_dim.y) - (total_h / 2.0)
			
			new_part.position = Vector3(x_pos, y_pos, 0)
			
			_apply_pixel_scale(new_part)
			
			column[j] = new_part
			
		parts[i] = column

func _on_part_clicked(coords: Vector2i) -> void:
	var target_node = parts[coords.x][coords.y]
	var a1 = get_row(coords.x)
	var a2 = get_column(coords.y)

func _apply_pixel_scale(node: Node) -> void:
	var sprite = node if node is Sprite3D else node.find_child("*", true, false)
	if sprite and sprite is Sprite3D:
		sprite.pixel_size = 1.0 / pixel_ratio

func get_column(column: int) -> Array:
	var arr = []
	
	for i in range(width):
		arr.append(parts[column][i])
	
	return arr
	
func get_row(row: int) -> Array:
	return parts[row]
	
func _process(_delta: float) -> void:
	for i in range(width):
		for j in range(height):
			var part = parts[i][j]
			if part.is_dragging:
				var arr = get_row(i)
				for k in range(arr.size()):
					fold_around_vertical_axis(arr[k],1.5)

func _update_drag_position(part: Node3D) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# 2. Calculate the intersection with the X,Y plane (where Z = 0)
	# Formula: origin + direction * (distance_to_plane)
	if ray_direction.z != 0: # Ensure we aren't looking perfectly parallel to the plane
		var t = -ray_origin.z / ray_direction.z
		var target_world_pos = ray_origin + ray_direction * t
		
		# 3. Apply the position (keeping Z at 0)
		part.global_position = Vector3(target_world_pos.x, target_world_pos.y, 0)


func fold_around_vertical_axis(node: Node3D, x_hinge: float, duration: float = 0.6):
	# 1. Pivot point is now on the X-axis (vertical line where x = x_hinge)
	var pivot_point = Vector3(x_hinge, node.global_position.y, node.global_position.z)
	var start_pos = node.global_position
	var start_rot = node.rotation
	
	var tween = create_tween()
	
	tween.tween_method(
		func(angle_deg):
			var angle_rad = deg_to_rad(angle_deg)
			
			# Calculate offset relative to the vertical hinge
			var offset = start_pos - pivot_point
			
			# 2. Rotate around Vector3.UP (the Y axis)
			var rotated_offset = offset.rotated(Vector3.UP, angle_rad)
			
			# 3. Update Position and Y-rotation
			node.global_position = pivot_point + rotated_offset
			node.rotation.y = start_rot.y + angle_rad, 0.0, 180.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
