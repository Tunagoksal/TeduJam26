extends CanvasLayer
class_name LoadingScreen

signal transition_in_complete

@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer

var starting_animation_name: String

func start_transition(animation_name: String) -> void:
	
	if !animation_player.has_animation(animation_name):
		push_warning("'%s' animation does not exist" %animation_name)
		animation_name = "pixel_to_black"

	starting_animation_name = animation_name
	animation_player.play(animation_name)
	
	timer.start()
	
func finish_transition() -> void:
	if timer:
		timer.stop()
		
	var ending_animation_name: String = starting_animation_name.replace("to","from")
	
	if !animation_player.has_animation(ending_animation_name):
		push_warning("'%s' animation does not exist" %ending_animation_name)
		ending_animation_name = "pixel_from_black"
	
	animation_player.play(ending_animation_name)
	
	await animation_player.animation_finished
	queue_free()

func report_midpoint() -> void:
	transition_in_complete.emit()
