extends TextureRect

@export var animation_speed := 0.3  
@export var shake_angle := 5.0      
@export var shake_duration := 0.5   


var _shake_tween: Tween = null
var _is_shaking := false

func _ready():
	scale = Vector2(0, 0)
	rotation_degrees = 0

	await get_tree().process_frame
	pivot_offset = size / 2
	_start_shake_animation()

func _start_shake_animation():
	if _is_shaking:
		return
	_is_shaking = true

	_shake_tween = create_tween()
	_shake_tween.set_loops() 
	_shake_tween.set_trans(Tween.TRANS_SINE)
	_shake_tween.set_ease(Tween.EASE_IN_OUT)

	_shake_tween.tween_property(self, "rotation_degrees", shake_angle, shake_duration)
	_shake_tween.tween_property(self, "rotation_degrees", -shake_angle, shake_duration)


func _on_panel_focus_entered() -> void:
	scale *= 1.2


func _on_focus_exited() -> void:
	scale *= 1.2
