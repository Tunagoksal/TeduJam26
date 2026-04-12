extends Node2D

@onready var theme_player: AudioStreamPlayer = $ThemePlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme_player.play()
