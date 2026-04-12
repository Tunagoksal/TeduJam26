extends Control
class_name StarRemainingUI

@onready var label: Label = $HBoxContainer/Label

@export var max_star_count: int = 4

func update_max_star_count(x):
	max_star_count = x
	update_star_count(0)

func update_star_count(star_count: int) -> void:
	label.text = str(star_count) + "/" + str(max_star_count)
