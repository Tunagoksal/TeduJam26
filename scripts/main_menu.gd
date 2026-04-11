extends Control
@export var speech_sound:AudioStreamWAV

@export var next_level_path: String
@onready var title: TextureRect = $TextureRect3

var tween: Tween

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout 
	DialogManager.start_dialog(Vector2(200,200),["Hello my name is jeff", "Fuck you"],speech_sound)




func _on_game_button_pressed() -> void:
	SceneManager.load_new_scene(next_level_path)


func _on_button_focus_entered() -> void:
	pass # Replace with function body.

func idle_title():
	var t = create_tween()
	t.set_loops()  # sonsuz loop
	
	t.tween_property(title, "scale", Vector2(1.03, 1.03), 1.2)
	t.tween_property(title, "scale", Vector2(1.0, 1.0), 1.2)
	
func _on_start_button_pressed() -> void:
	SceneManager.load_new_scene(next_level_path)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
