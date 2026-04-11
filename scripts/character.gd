extends CharacterBody2D
class_name Character

@export_group("Movement")
@export var max_speed: float = 400.0
@export var acceleration: float = 15000.0
@export var friction: float = 5000.0

@export_group("Roll")
@export var roll_force: float = 500.0
@export var roll_cooldown: float = 1000.0


@onready var timer: Timer = $Timer
@onready var anim_timer: Timer = $AnimationTimer
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var smushed: Sprite2D = $Smushed

signal inventory_changed(items: Array[CollectibleItem])
var inventory: Array[CollectibleItem] = []

var _can_roll = true
var facing_direction: Vector2 = Vector2.DOWN
var roll_spin_dir: float = 1.0

var rotation_val: float = PI/16
var rotation_moment: int = 0

var idle := true
var moving := false
var rolling := false

var is_frozen: bool = false
var is_smashed: bool = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	
	if is_frozen or is_smashed:
		return

	handle_movement(delta)
	
	handle_roll()
	
	move_and_slide()
	
func trap_under_paper() -> void:
	is_smashed = true
	is_frozen = true
	visible = false # Hide entirely because paper is on top!
	
	# Prep the smushed state for when they are revealed
	sprite.visible = false
	smushed.visible = true
	smushed.scale = Vector2(1, 0.2) # Start them completely flat

func reveal_from_paper() -> void:
	visible = true # The paper is gone, make them visible again
	
	if is_smashed:
		restore_from_smash()
	else:
		is_frozen = false # If they weren't smashed, just unfreeze them normally

func handle_movement(delta: float):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO and !rolling:
		
		if input_dir.x < 0:
			sprite.flip_h = true
			smushed.flip_h = true
		elif input_dir.x > 0:
			sprite.flip_h = false
			smushed.flip_h = false
		
		set_to_moving()
		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
		
	elif !rolling:
		set_to_idle()
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		sprite.rotation = 0
	
	if rolling:
		sprite.rotation += PI/18 * delta * 100 * roll_spin_dir


func handle_roll():
	if Input.is_action_just_pressed("roll") and _can_roll:
		set_to_rolling()
		velocity = facing_direction * roll_force + velocity
		AchievementManager.unlock_achivement("test")
		AchievementManager.unlock_achivement("test2")
		
		if facing_direction.x < 0:
			roll_spin_dir = -1.0   
		elif facing_direction.x > 0:
			roll_spin_dir = 1.0    

		_can_roll = false
		timer.start()
		

func _on_timer_timeout() -> void:
	_can_roll = true
	set_to_moving()

func _on_animation_timer_timeout() -> void:
	if idle or rolling:
		return
	sprite.rotation = rotation_val*(1.0-2.0*rotation_moment)
	sprite.frame = rotation_moment
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
	
func collect_item(item: CollectibleItem) -> void:
	inventory.append(item)
	print_debug("item collected")
	inventory_changed.emit(inventory)

func has_item(item: CollectibleItem) -> bool:
	return inventory.has(item)

func consume_item(item: CollectibleItem) -> void:
	if inventory.has(item):
		inventory.erase(item)
		print_debug("item used")
		inventory_changed.emit(inventory)
		
func play_smashed_effect():
	sprite.visible = false
	smushed.visible = true
	pass
	
func restore_from_smash():
	# Create a tween to pop the character back to normal
	var tween = create_tween()
	
	# Animate the smushed sprite scaling back up
	tween.tween_property(smushed, "scale", Vector2(1, 1), 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Once the animation finishes, restore the normal sprite and unfreeze
	tween.tween_callback(func():
		is_smashed = false
		is_frozen = false
		smushed.visible = false
		sprite.visible = true
	)
	
	
