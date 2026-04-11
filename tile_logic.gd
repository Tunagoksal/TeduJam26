extends Node2D

@onready var display_layer: TileMapLayer = $DisplayLayer
@onready var front_data: TileMapLayer = $FrontLayer
@onready var back_data: TileMapLayer = $BackLayer 

# --- GRID CONFIGURATION ---
@export var chunk_size: int = 2
@export var macro_cols: int = 4
@export var macro_rows: int = 4 

var active_folds: Array[FoldDir] = []
var is_animating: bool = false
var animation_duration: float = 0.4 
var locked_directions_unfold: Array[FoldDir] = []
var locked_directions_fold: Array[FoldDir] = []

var drag_begin_pos:Vector2
var drag_end_pos:Vector2

var dragging:bool

enum FoldDir { TOP, BOTTOM, LEFT, RIGHT }

func _ready() -> void:
	apply_grid_state(simulate_paper_state(active_folds).grid)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				# Mouse pressed
				drag_begin_pos = get_global_mouse_position()
			
			else:
				# Mouse released
				drag_end_pos = get_global_mouse_position()
				
				# Calculate direction
				var direction: FoldDir
				
				var local_begin = display_layer.to_local(drag_begin_pos)
				var cell_begin = display_layer.local_to_map(local_begin)
				var local_end = display_layer.to_local(drag_end_pos)
				var cell_end = display_layer.local_to_map(local_end)
				
				if display_layer.get_used_rect().has_point(cell_begin):
					direction = get_fold_from_drag(local_begin,local_end,display_layer)
	


				#print("Start:", drag_begin_pos)
				#print("End:", drag_end_pos)
				#print("Direction:", direction)

	if event is InputEventKey and event.pressed and not event.echo:
		#if event.keycode == KEY_W: fold_side(FoldDir.TOP)
		#if event.keycode == KEY_S: fold_side(FoldDir.BOTTOM)
		#if event.keycode == KEY_A: fold_side(FoldDir.LEFT)
		#if event.keycode == KEY_D: fold_side(FoldDir.RIGHT)
		
		if event.keycode == KEY_UP: unfold_side(FoldDir.TOP)
		if event.keycode == KEY_DOWN: unfold_side(FoldDir.BOTTOM)
		if event.keycode == KEY_LEFT: unfold_side(FoldDir.LEFT)
		if event.keycode == KEY_RIGHT: unfold_side(FoldDir.RIGHT)
		
		# Test Fold Locks
		if event.keycode == KEY_Z: lock_fold_direction(FoldDir.TOP)
		if event.keycode == KEY_X: unlock_fold_direction(FoldDir.TOP)
		
		# Test Unfold Locks
		if event.keycode == KEY_C: lock_unfold_direction(FoldDir.TOP)
		if event.keycode == KEY_V: unlock_unfold_direction(FoldDir.TOP)


func get_fold_from_drag(begin: Vector2, end: Vector2, tilemap: TileMapLayer) -> FoldDir:
	var delta = end - begin
	
	var dir: FoldDir
	if abs(delta.x) > abs(delta.y):
		dir = FoldDir.RIGHT if delta.x > 0 else FoldDir.LEFT
	else:
		dir = FoldDir.BOTTOM if delta.y > 0 else FoldDir.TOP
	
	var used = tilemap.get_used_rect()
	var center = used.get_center()
	
	var cell_begin = tilemap.local_to_map(begin)
	
	match dir:
		FoldDir.RIGHT:
			if cell_begin.x < center.x:
				dir = FoldDir.LEFT   # left side → fold inward
				fold_by_mouse(begin,dir)
				return FoldDir.LEFT
			else:
				unfold_by_mouse(begin,dir)
				return FoldDir.RIGHT  # right side → unfold outward
		
		FoldDir.LEFT:
			if cell_begin.x < center.x:
				unfold_by_mouse(begin,dir)
				return FoldDir.LEFT
			else:
				dir = FoldDir.RIGHT
				fold_by_mouse(begin,dir)
				return FoldDir.RIGHT
		FoldDir.TOP:
			if cell_begin.y < center.y:
				unfold_by_mouse(begin,dir)
				return FoldDir.TOP
			else:
				dir = FoldDir.BOTTOM
				fold_by_mouse(begin,dir)
				return FoldDir.BOTTOM
		
		FoldDir.BOTTOM:
			if cell_begin.y < center.y:
				dir = FoldDir.TOP
				fold_by_mouse(begin,dir)
				return FoldDir.TOP
			else:
				unfold_by_mouse(begin,dir)
				return FoldDir.BOTTOM
	
	return dir


func unfold_by_mouse(local_begin_pos, direction):
	unfold_side(direction)
	
func fold_by_mouse(local_begin, direction):
	fold_side(direction)
	
# ==========================================
# THE LAYER STACK SIMULATOR (CRITICAL FIX)
# ==========================================
func simulate_paper_state(folds: Array[FoldDir]) -> Dictionary:
	var grid = {}
	var total_width = macro_cols * chunk_size
	var total_height = macro_rows * chunk_size
	# 1. Initialize the paper. Every grid cell now holds an ARRAY of layers.
	for x in range(macro_cols * chunk_size):
		for y in range(macro_rows * chunk_size):
			var pos = Vector2i(x, y)
			
			var mirrored_x = (total_width - 1) - x
			var back_pos = Vector2i(mirrored_x, y)
			
			if front_data.get_cell_source_id(pos) != -1:
				grid[pos] = [{
					"orig_pos": pos,
					"back_orig_pos": back_pos, # Store the pre-mirrored position for the back
					"is_back": false, 
					"alt": front_data.get_cell_alternative_tile(pos)
				}]
			else:
				grid[pos] = []

	var bounds = { "min_c": 0, "max_c": macro_cols - 1, "min_r": 0, "max_r": macro_rows - 1 }

	# 2. Mathematically stack the layers for each fold
	for fold in folds:
		var c_line = 0; var t_line = 0; var is_vert = false; var hinge_idx = 0; var flip = 0
		
		if fold == FoldDir.TOP:
			is_vert = true; c_line = bounds.min_r; t_line = bounds.min_r + 1
			hinge_idx = max(c_line, t_line) * chunk_size; bounds.min_r += 1
			
			# THE FIX: Change this to TRANSFORM_FLIP_H if your texture is mirroring wrong.
			# (Or use: TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_FLIP_H for a 180-degree rotation)
			flip = TileSetAtlasSource.TRANSFORM_FLIP_H 
			
		elif fold == FoldDir.BOTTOM:
			is_vert = true; c_line = bounds.max_r; t_line = bounds.max_r - 1
			hinge_idx = (min(c_line, t_line) + 1) * chunk_size; bounds.max_r -= 1
			
			flip = TileSetAtlasSource.TRANSFORM_FLIP_H # Match your Top fold here
			
		elif fold == FoldDir.LEFT:
			is_vert = false; c_line = bounds.min_c; t_line = bounds.min_c + 1
			hinge_idx = max(c_line, t_line) * chunk_size; bounds.min_c += 1
			
			flip = TileSetAtlasSource.TRANSFORM_FLIP_V # Swap this too if needed!
			
		elif fold == FoldDir.RIGHT:
			is_vert = false; c_line = bounds.max_c; t_line = bounds.max_c - 1
			hinge_idx = (min(c_line, t_line) + 1) * chunk_size; bounds.max_c -= 1
			
			flip = TileSetAtlasSource.TRANSFORM_FLIP_V

		var src_min_x = bounds.min_c * chunk_size; var src_max_x = (bounds.max_c + 1) * chunk_size - 1
		var src_min_y = bounds.min_r * chunk_size; var src_max_y = (bounds.max_r + 1) * chunk_size - 1
		if is_vert:
			src_min_y = c_line * chunk_size; src_max_y = (c_line + 1) * chunk_size - 1
		else:
			src_min_x = c_line * chunk_size; src_max_x = (c_line + 1) * chunk_size - 1

		# Gather all moving tile stacks
		var moving_stacks = []
		for x in range(src_min_x, src_max_x + 1):
			for y in range(src_min_y, src_max_y + 1):
				var src_pos = Vector2i(x, y)
				if grid.has(src_pos) and grid[src_pos].size() > 0:
					var dst_pos = Vector2i(x, 2 * hinge_idx - 1 - y) if is_vert else Vector2i(2 * hinge_idx - 1 - x, y)
					moving_stacks.append({"src": src_pos, "dst": dst_pos, "layers": grid[src_pos]})
					grid[src_pos] = [] # Clear the original location

		# Drop the stacks onto their new destination
		for move in moving_stacks:
			var layers = move.layers
			if not grid.has(move.dst): grid[move.dst] = []
			
			# Physical Rule of Paper: When a stack of layers folds over, its order reverses!
			# (The top flap hits the table first, becoming the bottom layer)
			layers.reverse()
			
			for tile in layers:
				tile.is_back = not tile.is_back
				tile.alt = tile.alt ^ flip
				grid[move.dst].append(tile)

	return {"grid": grid, "bounds": bounds}

# Helper to fetch texture data securely
func get_tile_render_data(tile: Dictionary) -> Dictionary:
	if tile.is_back:
		var b_pos = tile.get("back_orig_pos", tile.orig_pos)
		return {
			"id": back_data.get_cell_source_id(b_pos),
			"coords": back_data.get_cell_atlas_coords(b_pos),
			"alt": tile.alt
		}
	return {
		"id": front_data.get_cell_source_id(tile.orig_pos),
		"coords": front_data.get_cell_atlas_coords(tile.orig_pos),
		"alt": tile.alt
	}

func apply_grid_state(grid_state: Dictionary) -> void:
	display_layer.clear()
	for pos in grid_state:
		var stack = grid_state[pos]
		if stack.size() > 0:
			# Only draw the tile at the very top of the stack
			var top_tile = stack.back() 
			var render = get_tile_render_data(top_tile)
			display_layer.set_cell(pos, render.id, render.coords, render.alt)

# ==========================================
# ANIMATION & LOCKING LOGIC
# ==========================================
func get_last_fold_index(target_dir: FoldDir) -> int:
	for i in range(active_folds.size() - 1, -1, -1):
		if active_folds[i] == target_dir: return i
	return -1

# --- MANUAL FOLD LOCKS ---
func lock_fold_direction(dir: FoldDir) -> void:
	if dir not in locked_directions_fold:
		locked_directions_fold.append(dir)

func unlock_fold_direction(dir: FoldDir) -> void:
	if dir in locked_directions_fold:
		locked_directions_fold.erase(dir)

# --- MANUAL UNFOLD LOCKS ---
func lock_unfold_direction(dir: FoldDir) -> void:
	if dir not in locked_directions_unfold:
		locked_directions_unfold.append(dir)

func unlock_unfold_direction(dir: FoldDir) -> void:
	if dir in locked_directions_unfold:
		locked_directions_unfold.erase(dir)

# --- PHYSICS UNFOLD LOCK CHECK ---
func is_unfold_locked(target_dir: FoldDir) -> bool:
	# 1. Manual Unfold Check
	if target_dir in locked_directions_unfold:
		return true
		
	# 2. Physics Check
	var idx = get_last_fold_index(target_dir)
	if idx == -1: return true
	var target_vert = (target_dir == FoldDir.TOP or target_dir == FoldDir.BOTTOM)
	for i in range(idx + 1, active_folds.size()):
		var later_vert = (active_folds[i] == FoldDir.TOP or active_folds[i] == FoldDir.BOTTOM)
		if target_vert != later_vert: return true
	return false

# --- ACTION LOGIC ---
func fold_side(dir: FoldDir) -> void:
	if is_animating: return
	
	# NEW: Prevent folding if explicitly locked!
	if dir in locked_directions_fold: return
	
	var b = simulate_paper_state(active_folds).bounds
	if (dir == FoldDir.TOP or dir == FoldDir.BOTTOM) and b.min_r >= b.max_r: return
	if (dir == FoldDir.LEFT or dir == FoldDir.RIGHT) and b.min_c >= b.max_c: return
	
	is_animating = true
	var pre_state = simulate_paper_state(active_folds)
	active_folds.append(dir)
	var post_state = simulate_paper_state(active_folds)
	_animate_chunk_transition(dir, true, pre_state, post_state)

func unfold_side(dir: FoldDir) -> void:
	# UPDATED: Now uses the explicitly named is_unfold_locked function
	if is_animating or is_unfold_locked(dir): return
	is_animating = true
	var pre_state = simulate_paper_state(active_folds)
	
	var idx = get_last_fold_index(dir)
	active_folds.remove_at(idx)
	
	var post_state = simulate_paper_state(active_folds)
	_animate_chunk_transition(dir, false, pre_state, post_state)

func _animate_chunk_transition(dir: FoldDir, is_folding: bool, pre: Dictionary, post: Dictionary) -> void:
	var b = pre.bounds
	var is_vert = false; var scale_prop = ""; var hinge_idx = 0; 
	var c_line = 0; var t_line = 0;
	
	if dir == FoldDir.TOP:
		is_vert = true; scale_prop = "scale:y"; c_line = b.min_r
		t_line = b.min_r + 1 if is_folding else b.min_r - 1
		hinge_idx = max(c_line, t_line) * chunk_size
	elif dir == FoldDir.BOTTOM:
		is_vert = true; scale_prop = "scale:y"; c_line = b.max_r
		t_line = b.max_r - 1 if is_folding else b.max_r + 1
		hinge_idx = (min(c_line, t_line) + 1) * chunk_size
	elif dir == FoldDir.LEFT:
		is_vert = false; scale_prop = "scale:x"; c_line = b.min_c
		t_line = b.min_c + 1 if is_folding else b.min_c - 1
		hinge_idx = max(c_line, t_line) * chunk_size
	elif dir == FoldDir.RIGHT:
		is_vert = false; scale_prop = "scale:x"; c_line = b.max_c
		t_line = b.max_c - 1 if is_folding else b.max_c + 1
		hinge_idx = (min(c_line, t_line) + 1) * chunk_size

	var src_min_x = b.min_c * chunk_size; var src_max_x = (b.max_c + 1) * chunk_size - 1
	var src_min_y = b.min_r * chunk_size; var src_max_y = (b.max_r + 1) * chunk_size - 1
	if is_vert:
		src_min_y = c_line * chunk_size; src_max_y = (c_line + 1) * chunk_size - 1
	else:
		src_min_x = c_line * chunk_size; src_max_x = (c_line + 1) * chunk_size - 1

	var pivot = Node2D.new()
	display_layer.add_child(pivot)
	var temp_layer = TileMapLayer.new()
	temp_layer.tile_set = display_layer.tile_set
	
	#DISABLE PHYSICS WHILE FOLDING
	temp_layer.collision_enabled = false
	pivot.add_child(temp_layer)
	
	var cell_size = display_layer.tile_set.tile_size
	var hinge_px = Vector2(hinge_idx * cell_size.x, hinge_idx * cell_size.y) if not is_vert else Vector2(0, hinge_idx * cell_size.y)
	if is_vert: hinge_px.x = 0
	else: hinge_px.y = 0
	
	pivot.position = hinge_px
	temp_layer.position = -hinge_px

	for x in range(src_min_x, src_max_x + 1):
		for y in range(src_min_y, src_max_y + 1):
			var src_pos = Vector2i(x, y)
			
			var pre_stack = pre.grid.get(src_pos, [])
			if not is_folding:
				var post_stack = post.grid.get(src_pos, [])
				if post_stack.size() > 0:
					var r = get_tile_render_data(post_stack.back())
					display_layer.set_cell(src_pos, r.id, r.coords, r.alt)
				else:
					display_layer.set_cell(src_pos, -1)
			else:
				display_layer.set_cell(src_pos, -1)
				
			if pre_stack.size() > 0:
				var r = get_tile_render_data(pre_stack.back())
				temp_layer.set_cell(src_pos, r.id, r.coords, r.alt)

	var player = get_tree().get_first_node_in_group("player") as Character
	if is_instance_valid(player):
		player.is_frozen = true

	var tween = get_tree().create_tween()
	tween.tween_property(pivot, scale_prop, 0.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(func():
		temp_layer.clear()
		for x in range(src_min_x, src_max_x + 1):
			for y in range(src_min_y, src_max_y + 1):
				var src_pos = Vector2i(x, y)
				var dst_pos = Vector2i(x, 2 * hinge_idx - 1 - y) if is_vert else Vector2i(2 * hinge_idx - 1 - x, y)
				var post_stack = post.grid.get(dst_pos, [])
				if post_stack.size() > 0:
					var r = get_tile_render_data(post_stack.back())
					temp_layer.set_cell(dst_pos, r.id, r.coords, r.alt)
	)
	
	tween.tween_property(pivot, scale_prop, 1.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		pivot.queue_free()
		apply_grid_state(post.grid) 
		
		if is_instance_valid(player):
			# We DO NOT unfreeze the player immediately here anymore. 
			# The Character script handles unfreezing based on whether they are trapped or animating.
			
			var p_local = display_layer.to_local(player.global_position)
			var p_cell = display_layer.local_to_map(p_local)
			
			# Look at the new grid state at that cell
			var stack = post.grid.get(p_cell, [])
			if stack.size() > 0:
				var top_tile = stack.back()
				
				# If the top tile is a BACK face, the paper folded over them!
				if top_tile.is_back:
					player.trap_under_paper()
				else:
					player.reveal_from_paper()
			else:
				player.reveal_from_paper()
		
		is_animating = false
	)
