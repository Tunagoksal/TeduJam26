extends Area2D
class_name Flag

@export var path:String
@export var star_count := 0
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		if star_count == body.star_count:
			SceneManager.load_new_scene(path)
			audio_stream_player.play()
