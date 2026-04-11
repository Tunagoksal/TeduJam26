extends Control
@export var speech_sound:AudioStreamWAV

@export var next_level_path: String



func _ready() -> void:
	await get_tree().create_timer(0.5).timeout 
	DialogManager.start_dialog(Vector2(200,200),["Hello my name is jeff", "Fuck you"],speech_sound)


func _on_game_button_pressed() -> void:
	SceneManager.load_new_scene(next_level_path)
