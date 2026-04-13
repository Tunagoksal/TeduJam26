extends Node2D

@onready var display_layer: TileMapLayer = $DisplayLayer
@onready var front_data: TileMapLayer = $FrontLayer
@onready var back_data: TileMapLayer = $BackLayer 
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2
# --- GRID CONFIGURATION ---
@export var chunk_size: int = 2
@export var macro_cols: int = 4
@export var macro_rows: int = 4

var footstep_sounds := [
	preload("uid://c0mvfg2dbc377"),
	preload("uid://gnkpqibupiyg"),
	preload("uid://by0vhiefqviqs")
]

var item_scenes = {
	1: "res://flag.tscn",
	2: "res://scenes/star.tscn",
}

var all_items: Dictionary = {}

@export var next_level_path:String

var arrow_cursor_texture = load("res://assets/Light/Arrows/Arrow2.png")
var point_cursor_texture = load("res://assets/Light/Hands/Hand2.png")
var drag_cursor_texture = load("res://assets/Light/Hands/Hand_Drag2.png")

var active_folds: Array[FoldDir] = []
var is_animating: bool = false
var animation_duration: float = 0.4 
var locked_directions_unfold: Array[FoldDir] = []
var locked_directions_fold: Array[FoldDir] = []

var drag_begin_pos:Vector2
var drag_end_pos:Vector2

var dragging:bool
var is_player_trapped: bool = false
var rescue_direction: FoldDir

var total_width: int
var total_height: int

enum FoldDir { TOP, BOTTOM, LEFT, RIGHT }

func _ready() -> void:
	total_width = macro_cols * chunk_size
	total_height = macro_rows * chunk_size
	Input.set_custom_mouse_cursor(point_cursor_texture)
	
	spawn_initial_items()
	
	var initial_grid = simulate_paper_state(active_folds).grid
	apply_grid_state(simulate_paper_state(active_folds).grid)
	refresh_items_visibility(initial_grid)
	
func _process(_delta):
	out_of_map()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !dragging:
		var mouse_pos = get_global_mouse_position()
		var local_pos = display_layer.to_local(mouse_pos)
		var cell = display_layer.local_to_map(local_pos)
		if display_layer.get_used_rect().has_point(cell):
			Input.set_custom_mouse_cursor(point_cursor_texture)
		else:
			Input.set_custom_mouse_cursor(arrow_cursor_texture)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				# Mouse pressed
				drag_begin_pos = get_global_mouse_position()
				dragging = true
				var local_drag_begin = display_layer.to_local(drag_begin_pos)
				var cell = display_layer.local_to_map(local_drag_begin)
				if display_layer.get_used_rect().has_point(cell):
					Input.set_custom_mouse_cursor(drag_cursor_texture)

			
			else:
				dragging = false
				drag_end_pos = get_global_mouse_position()
				
				var local_drag_end = display_layer.to_local(drag_end_pos)
				var cell = display_layer.local_to_map(local_drag_end)
				if display_layer.get_used_rect().has_point(cell):
					Input.set_custom_mouse_cursor(point_cursor_texture)
				
				# Calculate direction
				var direction: FoldDir
				
				var local_begin = display_layer.to_local(drag_begin_pos)
				var cell_begin = display_layer.local_to_map(local_begin)
				var local_end = display_layer.to_local(drag_end_pos)
				var cell_end = display_layer.local_to_map(local_end)
				
				if display_layer.get_used_rect().has_point(cell_begin):
					direction = get_fold_from_drag(local_begin,local_end,display_layer)

	if event is InputEventKey and event.pressed and not event.echo:
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
	var audio_players = [audio_stream_player, audio_stream_player_2]
	audio_players.pick_random().play()
	AchievementManager.unlock_achivement("Ctrl + Z")
	
func fold_by_mouse(local_begin, direction):
	fold_side(direction)
	var audio_players = [audio_stream_player, audio_stream_player_2]
	audio_players.pick_random().play()
	AchievementManager.unlock_achivement("Reality Bender")
	
# ==========================================
# THE LAYER STACK SIMULATOR
# ==========================================
func simulate_paper_state(folds: Array[FoldDir]) -> Dictionary:
	var grid = {}

	# 1. Initialize the paper — no pre-mirroring, back position is computed dynamically
	for x in range(total_width):
		for y in range(total_height):
			var pos = Vector2i(x, y)
			if front_data.get_cell_source_id(pos) != -1:
				grid[pos] = [{
					"orig_pos": pos,
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
			flip = TileSetAtlasSource.TRANSFORM_FLIP_H
			
		elif fold == FoldDir.BOTTOM:
			is_vert = true; c_line = bounds.max_r; t_line = bounds.max_r - 1
			hinge_idx = (min(c_line, t_line) + 1) * chunk_size; bounds.max_r -= 1
			flip = TileSetAtlasSource.TRANSFORM_FLIP_H
			
		elif fold == FoldDir.LEFT:
			is_vert = false; c_line = bounds.min_c; t_line = bounds.min_c + 1
			hinge_idx = max(c_line, t_line) * chunk_size; bounds.min_c += 1
			flip = TileSetAtlasSource.TRANSFORM_FLIP_V
			
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
			layers.reverse()
			
			for tile in layers:
				tile.is_back = not tile.is_back
				tile.alt = tile.alt ^ flip
				grid[move.dst].append(tile)

	return {"grid": grid, "bounds": bounds}

# Helper to fetch texture data — back tile always mirrors on both axes
func get_tile_render_data(tile: Dictionary) -> Dictionary:
	if tile.is_back:
		var orig = tile.orig_pos
		var b_pos = Vector2i((total_width - 1) - orig.x, (total_height - 1) - orig.y)
		
		# 1. Figure out which flips were applied during folding
		var original_front_alt = front_data.get_cell_alternative_tile(orig)
		var fold_flips = tile.alt ^ original_front_alt
		
		# 2. Apply those fold flips to the back layer's actual alternative ID
		var native_back_alt = back_data.get_cell_alternative_tile(b_pos)
		var final_alt = native_back_alt ^ fold_flips
		
		return {
			"id": back_data.get_cell_source_id(b_pos),
			"coords": back_data.get_cell_atlas_coords(b_pos),
			"alt": final_alt
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
	if dir in locked_directions_fold: return
	
	if is_player_trapped:
		print("Action Blocked: Player is trapped. You must unfold!")
		return
	
	var pre_state = simulate_paper_state(active_folds)
	var b = pre_state.bounds
	if (dir == FoldDir.TOP or dir == FoldDir.BOTTOM) and b.min_r >= b.max_r: return
	if (dir == FoldDir.LEFT or dir == FoldDir.RIGHT) and b.min_c >= b.max_c: return
	
	# Preview the fold to check player collisions
	var temp_folds = active_folds.duplicate()
	temp_folds.append(dir)
	var post_state = simulate_paper_state(temp_folds)
	
	var player = get_tree().get_first_node_in_group("player") as Character
	if is_instance_valid(player):
		var p_cell = display_layer.local_to_map(display_layer.to_local(player.global_position))
		var pre_size = pre_state.grid.get(p_cell, []).size()
		var post_size = post_state.grid.get(p_cell, []).size()
		
		# If stack size goes down, the paper they are standing on is moving away!
		if pre_size > post_size:
			print("Fold Cancelled: You cannot fold the flap the player is standing on!")
			return

	is_animating = true
	active_folds.append(dir)
	_animate_chunk_transition(dir, true, pre_state, post_state)


func spawn_initial_items() -> void:
	# 1. Spawn front items
	for cell in front_data.get_used_cells():
		var data = front_data.get_cell_tile_data(cell)
		if data and data.get_custom_data("item"):
			_create_and_store_item(cell, false, data.get_custom_data("item"))
			
	# 2. Spawn back items (reversing their coordinates to match the logical grid)
	for cell in back_data.get_used_cells():
		var data = back_data.get_cell_tile_data(cell)
		if data and data.get_custom_data("item"):
			var orig_pos = Vector2i((total_width - 1) - cell.x, (total_height - 1) - cell.y)
			_create_and_store_item(orig_pos, true, data.get_custom_data("item"))

func _create_and_store_item(orig_pos: Vector2i, is_back: bool, item_id: int) -> void:
	if not item_scenes.has(item_id): return
	var scene = load(item_scenes[item_id])
	var inst = scene.instantiate()
	
	if inst.get("path") != null: # Check for the flag's next_level_path
		inst.path = next_level_path
		
	add_child(inst)
	inst.hide() # Start invisible
	inst.set_deferred("monitoring", false) # Start without collision
	
	# Store in dictionary using a Vector3i as the key: (X, Y, Z=1 if back else 0)
	var dict_key = Vector3i(orig_pos.x, orig_pos.y, 1 if is_back else 0)
	all_items[dict_key] = inst

func refresh_items_visibility(grid_state: Dictionary) -> void:
	# 1. Hide everything first
	for key in all_items:
		var item = all_items[key]
		# is_instance_valid automatically ignores items the player has collected!
		if is_instance_valid(item):
			item.hide()
			item.set_deferred("monitoring", false)
			
	# 2. Look at only what is on TOP of the current folded paper
	for pos in grid_state:
		var stack = grid_state[pos]
		if stack.size() > 0:
			var top_tile = stack.back()
			var dict_key = Vector3i(top_tile.orig_pos.x, top_tile.orig_pos.y, 1 if top_tile.is_back else 0)
			
			# If an item belongs to this top piece of paper, show it and move it to the right spot!
			if all_items.has(dict_key):
				var item = all_items[dict_key]
				if is_instance_valid(item):
					item.position = display_layer.position + display_layer.map_to_local(pos)
					item.show()
					item.set_deferred("monitoring", true)

func unfold_side(dir: FoldDir) -> void:
	if is_animating or is_unfold_locked(dir): return
	
	if is_player_trapped:
		if active_folds.is_empty() or dir != active_folds.back():
			print("Action Blocked: You can only unfold the flap that crushed the player!")
			return

	var pre_state = simulate_paper_state(active_folds)
	var temp_folds = active_folds.duplicate()
	var idx = get_last_fold_index(dir)
	temp_folds.remove_at(idx)
	var post_state = simulate_paper_state(temp_folds)
	
	var player = get_tree().get_first_node_in_group("player") as Character
	# Check if standing on unfolding flap (Ignore this rule if they are trapped under it!)
	if is_instance_valid(player) and not is_player_trapped:
		var p_cell = display_layer.local_to_map(display_layer.to_local(player.global_position))
		var pre_size = pre_state.grid.get(p_cell, []).size()
		var post_size = post_state.grid.get(p_cell, []).size()
		
		if pre_size > post_size:
			print("Unfold Cancelled: You cannot unfold the flap the player is standing on!")
			return

	is_animating = true
	active_folds.remove_at(idx)
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
		
		refresh_items_visibility(post.grid)
		
		if is_instance_valid(player):
			var p_local = display_layer.to_local(player.global_position)
			var p_cell = display_layer.local_to_map(p_local)
			
			var pre_size = pre.grid.get(p_cell, []).size()
			var post_size = post.grid.get(p_cell, []).size()
			
			# If stack size increased, paper was dropped ON the player
			if post_size > pre_size:
				player.trap_under_paper()
				is_player_trapped = true
			# If stack size decreased, the paper trapping them was pulled back
			elif post_size < pre_size:
				player.reveal_from_paper()
				is_player_trapped = false
			# If the paper didn't touch them at all, just unfreeze them
			else:
				player.is_frozen = false 
		
		is_animating = false
	)

var unlocked:bool = false

func out_of_map():
	if unlocked:
		return
		
	var player = get_tree().get_first_node_in_group("player") as Character
	if !is_instance_valid(player):
		return

	var player_pos = display_layer.to_local(player.global_position)
	var map_pos = display_layer.local_to_map(player_pos)

	var grid_state = simulate_paper_state(active_folds).grid

	if !grid_state.has(map_pos) or grid_state[map_pos].size() == 0:
		AchievementManager.unlock_achivement("It is not a bug it is a feature")
		unlocked = true
	
