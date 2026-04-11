extends CharacterBody2D

@export_group("Movement")
@export var max_speed: float = 400.0
@export var acceleration: float = 15000.0
@export var friction: float = 5000.0

@export_group("Roll")
@export var roll_force: float = 500.0
@export var roll_cooldown: float = 1000.0

@onready var timer: Timer = $Timer
@onready var anim_timer: Timer = $AnimationTimer
@onready var sprite: Sprite2D = $Sprite

var _can_roll = true
var facing_direction: Vector2 = Vector2.DOWN

var rotation_val: float = PI/8
var rotation_moment: int = 0

var idle := true
var moving := false
var rolling := false

func _physics_process(delta: float) -> void:

	handle_movement(delta)
	
	handle_roll()
	
	move_and_slide()

func handle_movement(delta: float):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO and !rolling:
		set_to_moving()
		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
		
	elif !rolling:
		set_to_idle()
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		sprite.rotation = 0
	
	if rolling:
		sprite.rotation += PI/18 * delta * 100


func handle_roll():
	if Input.is_action_just_pressed("roll"):
		AchievementManager.unlock_achivement("test")
		AchievementManager.unlock_achivement("test2")
		velocity = facing_direction * roll_force
		_can_roll = false
		timer.start()
		

func _on_timer_timeout() -> void:
	_can_roll = true
	set_to_moving()

func _on_animation_timer_timeout() -> void:
	if idle or rolling:
		return
	sprite.rotation = rotation_val*(1.0-2.0*rotation_moment)
	rotation_moment = (rotation_moment + 1) % 2


func set_to_idle() -> void:
	idle = true
	moving = false
	rolling = false
	
func set_to_moving() -> void:
	idle = false
	moving = true
	rolling = false
	
func set_to_rolling() -> void:
	idle = false
	moving = false
	rolling = true
