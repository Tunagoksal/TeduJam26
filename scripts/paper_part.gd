class_name PaperPart extends Area3D

var dimensions : Vector2
@export var sprite : Sprite3D 

func _ready() -> void:
	dimensions = sprite.texture.get_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_dimension() -> Vector2:
	return dimensions
