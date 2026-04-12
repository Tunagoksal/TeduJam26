extends Area2D
class_name Item

@export var item_data: CollectibleItem 
@export var tilemap:TileMapLayer
@export var default_tile_atlas_coor:Vector2

@onready var sprite: Sprite2D = $YildizSari
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	sprite.texture = item_data.icon
	audio_stream_player.play()


func _on_body_entered(body: Node2D) -> void:
	if body is Character and item_data != null:
		body.collect_item(item_data)
		queue_free()


func on_destroy():
	tilemap.set_cell(tilemap.local_to_map(position),0,default_tile_atlas_coor)
	
