extends Button

@export var animation_speed := 0.3  
@export var shake_angle := 5.0      
@export var shake_duration := 0.5   
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var _shake_tween: Tween = null
var _is_shaking := false
var hover_tween: Tween

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


func _stop_shake_animation():
	if _shake_tween:
		_shake_tween.kill()
	
	_is_shaking = false
	
	# smooth şekilde 0’a dönsün (snap olmasın)
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation_degrees", 0, 0.15)


func _on_mouse_entered() -> void:
	audio_stream_player.play()
	_stop_shake_animation()  # 🔴 önemli
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_BACK)
	hover_tween.set_ease(Tween.EASE_OUT)
	
	hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)


func _on_mouse_exited() -> void:
	_start_shake_animation()
	
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_SINE)
	hover_tween.set_ease(Tween.EASE_IN_OUT)
	
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
