extends Area2D
class_name Flag

@export var path:String
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		if body.star_count_check():
			SceneManager.load_new_scene(path)
			audio_stream_player.play()
