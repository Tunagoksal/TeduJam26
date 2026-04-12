extends CharacterBody2D
class_name Character

@export_group("Movement")
@export var max_speed: float = 400.0
@export var acceleration: float = 15000.0
@export var friction: float = 5000.0
@onready var star_remaining_ui: StarRemainingUI = $"../StarRemainingUI"

@export_group("Roll")
@export var roll_force: float = 500.0
@export var roll_cooldown: float = 1000.0
@export var roll_speed: float = 100

@onready var timer: Timer = $Timer
@onready var anim_timer: Timer = $AnimationTimer
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var smushed: Sprite2D = $Smushed

# 🎧 FOOTSTEP AUDIO
@onready var footstep_player: AudioStreamPlayer = $AudioStreamPlayer

var footstep_sounds := [
	preload("uid://c0mvfg2dbc377"),
	preload("uid://gnkpqibupiyg"),
	preload("uid://by0vhiefqviqs")
]

var step_timer: float = 0.0
var step_interval: float = 0.35

# -------------------------

var star_count := 0 

signal inventory_changed(items: Array[CollectibleItem])
var inventory: Array[CollectibleItem] = []

var _can_roll = true
var facing_direction: Vector2 = Vector2.DOWN
var roll_spin_dir: float = 1.0

var rotation_val: float = PI / 16
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
	handle_footsteps(delta)   # 👈 FOOTSTEPS ADDED
	move_and_slide()


# =========================================================
# MOVEMENT
# =========================================================

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
		AchievementManager.unlock_achivement("Rise and Shine")

		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)

	elif !rolling:
		set_to_idle()
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		sprite.rotation = 0

	if rolling:
		sprite.rotation += PI / 18 * delta * roll_speed * roll_spin_dir


# =========================================================
# FOOTSTEP SYSTEM
# =========================================================

func handle_footsteps(delta: float) -> void:
	if !moving or rolling:
		step_timer = 0.0
		return

	# adjust interval based on speed
	var speed_ratio = velocity.length() / max_speed
	step_timer -= delta

	if step_timer <= 0.0:
		play_footstep()

		# faster movement = faster footsteps
		step_interval = lerp(0.45, 0.2, speed_ratio)
		step_timer = step_interval


func play_footstep():
	var player = footstep_player

	player.stream = footstep_sounds.pick_random()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()


# =========================================================
# ROLL
# =========================================================

func handle_roll():
	if Input.is_action_just_pressed("roll") and _can_roll:
		set_to_rolling()

		velocity = facing_direction * roll_force + velocity
		AchievementManager.unlock_achivement("I <3 Rolling")

		if facing_direction.x < 0:
			roll_spin_dir = -1.0
		elif facing_direction.x > 0:
			roll_spin_dir = 1.0

		_can_roll = false
		timer.start()


func _on_timer_timeout() -> void:
	_can_roll = true
	set_to_moving()


# =========================================================
# ANIMATION TIMER
# =========================================================

func _on_animation_timer_timeout() -> void:
	if idle or rolling:
		return

	sprite.rotation = rotation_val * (1.0 - 2.0 * rotation_moment)
	sprite.frame = rotation_moment
	rotation_moment = (rotation_moment + 1) % 2


# =========================================================
# STATES
# =========================================================

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


# =========================================================
# INVENTORY
# =========================================================

func collect_item(item: CollectibleItem) -> void:
	inventory.append(item)
	star_count += 1
	star_remaining_ui.update_star_count(star_count)
	print_debug("item collected")
	inventory_changed.emit(inventory)


func has_item(item: CollectibleItem) -> bool:
	return inventory.has(item)


func consume_item(item: CollectibleItem) -> void:
	if inventory.has(item):
		inventory.erase(item)
		print_debug("item used")
		inventory_changed.emit(inventory)


# =========================================================
# PAPER EFFECTS
# =========================================================

func trap_under_paper() -> void:
	AchievementManager.unlock_achivement("Wrecked")
	is_smashed = true
	is_frozen = true
	visible = false

	sprite.visible = false
	smushed.visible = true
	smushed.scale = Vector2(1, 0.2)


func reveal_from_paper() -> void:
	visible = true

	if is_smashed:
		restore_from_smash()
	else:
		is_frozen = false


func play_smashed_effect():
	sprite.visible = false
	smushed.visible = true


func restore_from_smash():
	var tween = create_tween()

	tween.tween_property(smushed, "scale", Vector2(1.5, 1.5), 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_IN)


	tween.tween_callback(func():
		is_smashed = false
		is_frozen = false
		smushed.visible = false
		sprite.visible = true
	)
	
func star_count_check():
	var parent = get_parent()
	
	if parent is Level:
		var level: Level = parent
		return star_count == level.star_count
	
	return false
