extends Node2D

@onready var inventory_ui = $InventoryUI

@onready var layers = $Node2D

var total_length := 144*8


func _ready() -> void:
	var view_size := get_viewport_rect().size
	layers.position.x = (view_size.x / 2.0) - layers.scale.x*(total_length / 2.0)
	layers.position.y = (view_size.y / 2.0) - layers.scale.y*(total_length / 2.0)
