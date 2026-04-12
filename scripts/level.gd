extends Node2D

@onready var inventory_ui = $InventoryUI

@onready var layers = $Node2D

@export var total_length := 144*8
@export var layer_scale = 0.8

func _ready() -> void:
	var view_size := get_viewport_rect().size
	layers.position.x = (view_size.x / 2.0) - layer_scale*(total_length / 2.0)
	layers.position.y = (view_size.y / 2.0) - layer_scale*(total_length / 2.0)
