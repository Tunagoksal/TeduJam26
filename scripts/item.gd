extends Area2D
class_name Item

@export var item_data: CollectibleItem 

@onready var sprite: Sprite2D = $Icon

func _on_body_entered(body: Node2D) -> void:
	if body is Character and item_data != null:
		body.collect_item(item_data)
		queue_free()
