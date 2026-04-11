extends CharacterBody2D

@export_group("Movement")
@export var max_speed: float = 400.0
@export var acceleration: float = 1500.0
@export var friction: float = 1500.0

@export_group("Roll")
@export var roll_force: float = 1000.0
@export var roll_cooldown: float = 1000.0

var _can_roll = true
var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:

	handle_movement(delta)
	
	handle_roll()
	
	move_and_slide()

func handle_movement(delta: float):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func handle_roll():
	if Input.is_action_just_pressed("roll"):
		velocity = facing_direction * roll_force
		_can_roll = false
		await get_tree().create_timer(roll_cooldown).timeout.connect(func(): _can_roll = true)
		
	
