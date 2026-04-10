extends Node2D

#TODO THESE VALUES ARE DISPLAY!!!!
@onready var display_layer: TileMapLayer = $DisplayLayer
@onready var front_data: TileMapLayer = $FrontLayer
@onready var back_data: TileMapLayer = $BackLayer
@onready var tilemap_cols = 4
@onready var tilemap_rows = 4
@onready var curr_rows = 4

var is_animating: bool = false
var animation_duration: float = 0.4 

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		if not is_animating and curr_rows > 0:
			fold_top_row_once()

func fold_top_row_once() -> void:
	is_animating = true
	var current_y = tilemap_rows - curr_rows
	var target_y = current_y + 1
	
	var row_data = [] 
	
	# 1. Setup all sprites for the entire row FIRST
	for x in range(tilemap_cols):
		var cell_pos = Vector2i(x, current_y)
		
		var front_id = display_layer.get_cell_source_id(cell_pos)
		var front_coords = display_layer.get_cell_atlas_coords(cell_pos)
		
		var back_id = back_data.get_cell_source_id(cell_pos)
		var back_coords = back_data.get_cell_atlas_coords(cell_pos)
		var back_alt = back_data.get_cell_alternative_tile(cell_pos)
		back_alt = back_alt | TileSetAtlasSource.TRANSFORM_FLIP_V
		
		# Erase the original tile so the sprite can take its place
		display_layer.set_cell(cell_pos, -1)
		
		if front_id != -1 and back_id != -1:
			var temp_sprite = Sprite2D.new()
			# CRITICAL FIX: Attach the sprite directly to the display layer!
			display_layer.add_child(temp_sprite)
			
			var tileset = display_layer.tile_set
			var front_source: TileSetAtlasSource = tileset.get_source(front_id) as TileSetAtlasSource
			temp_sprite.texture = front_source.texture
			temp_sprite.region_enabled = true
			temp_sprite.region_rect = front_source.get_tile_texture_region(front_coords)
			
			var cell_size = tileset.tile_size
			# Because the sprite is now a child of the tilemap, local coordinates are perfect
			var cell_center = display_layer.map_to_local(cell_pos)
			
			temp_sprite.position = cell_center
			temp_sprite.position.y += cell_size.y / 2.0
			temp_sprite.offset = Vector2(0, -cell_size.y / 2.0)
			
			row_data.append({
				"x": x,
				"id": back_id,
				"coords": back_coords,
				"alt": back_alt,
				"sprite": temp_sprite
			})

	# 2. Animate the ENTIRE row perfectly simultaneously
	var tween = get_tree().create_tween()
	
	# Phase 1: Squish all tiles vertically at the exact same time
	for data in row_data:
		tween.parallel().tween_property(data.sprite, "scale:y", 0.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Phase 2: Swap textures to the "back" at the halfway point
	tween.tween_callback(func():
		var tileset = display_layer.tile_set
		for data in row_data:
			var back_source: TileSetAtlasSource = tileset.get_source(data.id) as TileSetAtlasSource
			data.sprite.texture = back_source.texture
			data.sprite.region_rect = back_source.get_tile_texture_region(data.coords)
			data.sprite.offset = Vector2(0, tileset.tile_size.y / 2.0)
			data.sprite.flip_v = true
	)
	
	# Phase 3: Expand all tiles downwards to the next row
	for data in row_data:
		tween.parallel().tween_property(data.sprite, "scale:y", 1.0, animation_duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Phase 4: Snap the real tiles into the new row and delete the sprites
	tween.tween_callback(func():
		for data in row_data:
			display_layer.set_cell(Vector2i(data.x, target_y), data.id, data.coords, data.alt)
			data.sprite.queue_free()
			
		curr_rows -= 1
		is_animating = false
	)
