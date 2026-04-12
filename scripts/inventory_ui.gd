extends CanvasLayer
class_name Inventory

@export var player: CharacterBody2D 

@onready var container = $HBoxContainer

func _ready() -> void:
	if player:
		player.inventory_changed.connect(update_ui)

func update_ui(inventory: Array[CollectibleItem]):
	for child in container.get_children():
		child.queue_free()
	
	for item in inventory:
		if item.icon:
			var icon_rect = TextureRect.new()
			icon_rect.texture = item.icon
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(256, 256)
			container.add_child(icon_rect)
	
