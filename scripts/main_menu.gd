extends Control
@export var speech_sound:AudioStreamWAV

@export var next_level_path: String
@onready var title: TextureRect = $TextureRect3
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var marker: Node2D = $Marker

var arrow_cursor_texture = load("res://assets/Light/Arrows/Arrow2.png")
var point_cursor_texture = load("res://assets/Light/Hands/Hand2.png")
var drag_cursor_texture = load("res://assets/Light/Hands/Hand_Drag2.png")


var tween: Tween

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	Input.set_custom_mouse_cursor(arrow_cursor_texture) 
	DialogManager.start_dialog(marker.position,["WASD for explore","SHIFT for Dash"],speech_sound)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if DialogManager.current_line_index == 0:
			if event.keycode == KEY_W or event.keycode == KEY_A or event.keycode == KEY_D or event.keycode == KEY_S:
				DialogManager.next_line()
		else:
			if event.keycode == KEY_SHIFT:
				DialogManager.next_line()
				
func _on_game_button_pressed() -> void:
	SceneManager.load_new_scene(next_level_path)


func _on_button_focus_entered() -> void:
	pass # Replace with function body.

func idle_title():
	var t = create_tween()
	t.set_loops()
	
	t.tween_property(title, "scale", Vector2(1.03, 1.03), 1.2)
	t.tween_property(title, "scale", Vector2(1.0, 1.0), 1.2)
	
func _on_start_button_pressed() -> void:
	audio_stream_player.play()
	audio_stream_player.finished
	SceneManager.load_new_scene(next_level_path)

func _on_exit_button_pressed() -> void:
	audio_stream_player.play()
	audio_stream_player.finished
	get_tree().quit()
