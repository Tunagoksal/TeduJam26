extends Node2D

@onready var display_layer: TileMapLayer = $DisplayLayer
@onready var front_data: TileMapLayer = $FrontLayer
@onready var back_data: TileMapLayer = $BackLayer 
@onready var tilemap_cols: int = 4
@onready var tilemap_rows: int = 4

# Replaced curr_rows and curr_cols with Boundary Tracking
var min_x: int = 0
var max_x: int = 3 # (4 columns total: 0, 1, 2, 3)
var min_y: int = 0
var max_y: int = 3 # (4 rows total: 0, 1, 2, 3)
var fold_history: Array = []

var is_animating: bool = false
var animation_duration: float = 0.4 

# Create an Enum so we can easily tell our function which way to fold
enum FoldDir { TOP, BOTTOM, LEFT, RIGHT }

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		
		# --- FOLD INWARD (WASD) ---
		if event.keycode == KEY_W: fold_side(FoldDir.TOP)
		if event.keycode == KEY_S: fold_side(FoldDir.BOTTOM)
		if event.keycode == KEY_A: fold_side(FoldDir.LEFT)
		if event.keycode == KEY_D: fold_side(FoldDir.RIGHT)
		
		# --- UNDO LAST FOLD ---
		if event.keycode == KEY_SPACE: undo_last_fold()
		

func get_grid_snapshot() -> Dictionary:
	var snap = {}
	for x in range(tilemap_cols):
		for y in range(tilemap_rows):
			var pos = Vector2i(x, y)
			snap[pos] = {
				"id": display_layer.get_cell_source_id(pos),
				"coords": display_layer.get_cell_atlas_coords(pos),
				"alt": display_layer.get_cell_alternative_tile(pos)
			}
	return snap

func fold_side(dir: FoldDir) -> void:
	if is_animating: return
	
	var is_vertical = (dir == FoldDir.TOP or dir == FoldDir.BOTTOM)
	
	# Prevent folding if there's no paper left to fold!
	if is_vertical and min_y >= max_y: return
	if not is_vertical and min_x >= max_x: return
	
	is_animating = true
	
	# TAKE A SNAPSHOT AND SAVE IT TO HISTORY
	var current_snapshot = get_grid_snapshot()
	fold_history.append({
		"dir": dir,
		"snapshot": current_snapshot
	})
	
	# --- 1. DYNAMIC SETUP BASED ON DIRECTION ---
	var current_line: int
	var target_line: int
	var loop_start: int
	var loop_end: int
	var flip_flag: int
	var scale_prop: String
	
	var hinge_shift: Vector2
	var initial_offset: Vector2
	var target_offset: Vector2
	
	var cell_size = display_layer.tile_set.tile_size
	
	if dir == FoldDir.TOP:
		current_line = min_y
		target_line = min_y + 1
		loop_start = min_x; loop_end = max_x
		flip_flag = TileSetAtlasSource.TRANSFORM_FLIP_V
		scale_prop = "scale:y"
		hinge_shift = Vector2(0, cell_size.y / 2.0)
		initial_offset = Vector2(0, -cell_size.y / 2.0)
		target_offset = Vector2(0, cell_size.y / 2.0)
		min_y += 1 # Shrink our active paper bounds
		
	elif dir == FoldDir.BOTTOM:
		current_line = max_y
		target_line = max_y - 1
		loop_start = min_x; loop_end = max_x
		flip_flag = TileSetAtlasSource.TRANSFORM_FLIP_V
		scale_prop = "scale:y"
		hinge_shift = Vector2(0, -cell_size.y / 2.0)
		initial_offset = Vector2(0, cell_size.y / 2.0)
		target_offset = Vector2(0, -cell_size.y / 2.0)
		max_y -= 1
		
	elif dir == FoldDir.LEFT:
		current_line = min_x
		target_line = min_x + 1
		loop_start = min_y; loop_end = max_y
		flip_flag = TileSetAtlasSource.TRANSFORM_FLIP_H
		scale_prop = "scale:x" # Side folds squish horizontally!
		hinge_shift = Vector2(cell_size.x / 2.0, 0)
		initial_offset = Vector2(-cell_size.x / 2.0, 0)
		target_offset = Vector2(cell_size.x / 2.0, 0)
		min_x += 1
		
	elif dir == FoldDir.RIGHT:
		current_line = max_x
		target_line = max_x - 1
		loop_start = min_y; loop_end = max_y
		flip_flag = TileSetAtlasSource.TRANSFORM_FLIP_H
		scale_prop = "scale:x"
		hinge_shift = Vector2(-cell_size.x / 2.0, 0)
		initial_offset = Vector2(cell_size.x / 2.0, 0)
		target_offset = Vector2(-cell_size.x / 2.0, 0)
		max_x -= 1

	# --- 2. GATHER SPRITES FOR THE LINE ---
	var row_data = [] 
	
	for i in range(loop_start, loop_end + 1):
		var cell_pos = Vector2i(i, current_line) if is_vertical else Vector2i(current_line, i)
		var target_pos = Vector2i(i, target_line) if is_vertical else Vector2i(target_line, i)
		
		var front_id = display_layer.get_cell_source_id(cell_pos)
		var front_coords = display_layer.get_cell_atlas_coords(cell_pos)
		var front_alt = display_layer.get_cell_alternative_tile(cell_pos)
		
		var back_id = back_data.get_cell_source_id(cell_pos)
		var back_coords = back_data.get_cell_atlas_coords(cell_pos)
		var back_alt = back_data.get_cell_alternative_tile(cell_pos)
		
		# Mathematical XOR operator (^): It perfectly toggles the flip state! 
		# If it's already flipped, it unflips it. If normal, it flips it.
		back_alt = back_alt ^ flip_flag 
		
		display_layer.set_cell(cell_pos, -1)
		
		if front_id != -1 and back_id != -1:
			var temp_sprite = Sprite2D.new()
			display_layer.add_child(temp_sprite)
			
			var front_source: TileSetAtlasSource = display_layer.tile_set.get_source(front_id) as TileSetAtlasSource
			temp_sprite.texture = front_source.texture
			temp_sprite.region_enabled = true
			temp_sprite.region_rect = front_source.get_tile_texture_region(front_coords)
			
			# Accurately restore any existing flips on both axes
			temp_sprite.flip_v = (front_alt & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
			temp_sprite.flip_h = (front_alt & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
			
			temp_sprite.position = display_layer.map_to_local(cell_pos) + hinge_shift
			temp_sprite.offset = initial_offset
			
			row_data.append({
				"target_pos": target_pos,
				"id": back_id,
				"coords": back_coords,
				"alt": back_alt,
				"sprite": temp_sprite
			})

	# --- 3. THE UNIVERSAL ANIMATION TWEEN ---
	var tween = get_tree().create_tween()
	
	# Phase 1: Squish
	for data in row_data:
		tween.parallel().tween_property(data.sprite, scale_prop, 0.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Phase 2: Swap Textures & Adjust Offsets
	tween.tween_callback(func():
		var tileset = display_layer.tile_set
		for data in row_data:
			var back_source: TileSetAtlasSource = tileset.get_source(data.id) as TileSetAtlasSource
			data.sprite.texture = back_source.texture
			data.sprite.region_rect = back_source.get_tile_texture_region(data.coords)
			data.sprite.offset = target_offset
			
			# Apply our perfectly toggled flip state to the new texture
			data.sprite.flip_v = (data.alt & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
			data.sprite.flip_h = (data.alt & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
	)
	
	# Phase 3: Expand
	for data in row_data:
		tween.parallel().tween_property(data.sprite, scale_prop, 1.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Phase 4: Snap and Cleanup
	tween.tween_callback(func():
		for data in row_data:
			display_layer.set_cell(data.target_pos, data.id, data.coords, data.alt)
			data.sprite.queue_free()
		is_animating = false
	)

func undo_last_fold() -> void:
	if is_animating or fold_history.is_empty(): return
	is_animating = true
	
	# Pop the last action from our history stack
	var last_action = fold_history.pop_back()
	var dir = last_action.dir
	var target_state = last_action.snapshot
	
	var is_vertical = (dir == FoldDir.TOP or dir == FoldDir.BOTTOM)
	
	var current_line: int
	var target_line: int
	var loop_start: int
	var loop_end: int
	
	var scale_prop: String
	var hinge_shift: Vector2
	var initial_offset: Vector2
	var target_offset: Vector2
	
	var cell_size = display_layer.tile_set.tile_size
	
	# Setup the reverse geometry based on the direction we originally folded
	if dir == FoldDir.TOP:
		current_line = min_y
		target_line = min_y - 1
		loop_start = min_x; loop_end = max_x
		scale_prop = "scale:y"
		hinge_shift = Vector2(0, -cell_size.y / 2.0)
		initial_offset = Vector2(0, cell_size.y / 2.0)
		target_offset = Vector2(0, -cell_size.y / 2.0)
		
	elif dir == FoldDir.BOTTOM:
		current_line = max_y
		target_line = max_y + 1
		loop_start = min_x; loop_end = max_x
		scale_prop = "scale:y"
		hinge_shift = Vector2(0, cell_size.y / 2.0)
		initial_offset = Vector2(0, -cell_size.y / 2.0)
		target_offset = Vector2(0, cell_size.y / 2.0)
		
	elif dir == FoldDir.LEFT:
		current_line = min_x
		target_line = min_x - 1
		loop_start = min_y; loop_end = max_y
		scale_prop = "scale:x"
		hinge_shift = Vector2(-cell_size.x / 2.0, 0)
		initial_offset = Vector2(cell_size.x / 2.0, 0)
		target_offset = Vector2(-cell_size.x / 2.0, 0)
		
	elif dir == FoldDir.RIGHT:
		current_line = max_x
		target_line = max_x + 1
		loop_start = min_y; loop_end = max_y
		scale_prop = "scale:x"
		hinge_shift = Vector2(cell_size.x / 2.0, 0)
		initial_offset = Vector2(-cell_size.x / 2.0, 0)
		target_offset = Vector2(cell_size.x / 2.0, 0)

	var row_data = [] 
	
	for i in range(loop_start, loop_end + 1):
		var current_pos = Vector2i(i, current_line) if is_vertical else Vector2i(current_line, i)
		var target_pos = Vector2i(i, target_line) if is_vertical else Vector2i(target_line, i)
		
		# 1. Grab the flap currently sitting on the display
		var flap_id = display_layer.get_cell_source_id(current_pos)
		var flap_coords = display_layer.get_cell_atlas_coords(current_pos)
		var flap_alt = display_layer.get_cell_alternative_tile(current_pos)
		
		# 2. Grab what the destination flap SHOULD be from our history snapshot!
		var dest_data = target_state[target_pos]
		
		# 3. Restore the tiles underneath instantly from our history snapshot!
		var underneath_data = target_state[current_pos]
		display_layer.set_cell(current_pos, underneath_data.id, underneath_data.coords, underneath_data.alt)
		
		if flap_id != -1:
			var temp_sprite = Sprite2D.new()
			display_layer.add_child(temp_sprite)
			
			var flap_source: TileSetAtlasSource = display_layer.tile_set.get_source(flap_id) as TileSetAtlasSource
			temp_sprite.texture = flap_source.texture
			temp_sprite.region_enabled = true
			temp_sprite.region_rect = flap_source.get_tile_texture_region(flap_coords)
			
			temp_sprite.flip_v = (flap_alt & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
			temp_sprite.flip_h = (flap_alt & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
			
			temp_sprite.position = display_layer.map_to_local(current_pos) + hinge_shift
			temp_sprite.offset = initial_offset
			
			row_data.append({
				"sprite": temp_sprite,
				"dest_id": dest_data.id,
				"dest_coords": dest_data.coords,
				"dest_alt": dest_data.alt,
			})

	var tween = get_tree().create_tween()
	
	# Squish
	for data in row_data:
		tween.parallel().tween_property(data.sprite, scale_prop, 0.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Swap to the historical texture
	tween.tween_callback(func():
		var tileset = display_layer.tile_set
		for data in row_data:
			# If the tile was blank in history, hide the sprite so it doesn't error out
			if data.dest_id == -1:
				data.sprite.visible = false
				continue
				
			var dest_source: TileSetAtlasSource = tileset.get_source(data.dest_id) as TileSetAtlasSource
			data.sprite.texture = dest_source.texture
			data.sprite.region_rect = dest_source.get_tile_texture_region(data.dest_coords)
			data.sprite.offset = target_offset
			
			data.sprite.flip_v = (data.dest_alt & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
			data.sprite.flip_h = (data.dest_alt & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
	)
	
	# Expand
	for data in row_data:
		tween.parallel().tween_property(data.sprite, scale_prop, 1.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Absolute Sync Cleanup
	tween.tween_callback(func():
		for data in row_data:
			data.sprite.queue_free()
			
		# FORCES the entire grid to snap perfectly to the history state. 
		# This eliminates 100% of spatial overlapping bugs!
		for pos in target_state:
			var d = target_state[pos]
			display_layer.set_cell(pos, d.id, d.coords, d.alt)
			
		# Restore our active paper bounds
		if dir == FoldDir.TOP: min_y -= 1
		elif dir == FoldDir.BOTTOM: max_y += 1
		elif dir == FoldDir.LEFT: min_x -= 1
		elif dir == FoldDir.RIGHT: max_x += 1
		
		is_animating = false
	)
