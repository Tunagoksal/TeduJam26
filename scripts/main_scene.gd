extends Node3D

@export var paper_part: PaperPart
@export var width: int
@export var height: int

var dimensions: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dimensions = paper_part.get_dimension()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
