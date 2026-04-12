extends Area2D
class_name Flag

@export var path:String
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var sprite: Sprite2D = $Bayrak

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.inventory_changed.connect(_on_inventory_changed)

	update_flag_visual()

func _process(_delta):
	update_flag_visual()
	
func _on_inventory_changed(_inv):
	print("asdasdasdasdasdasd")
	update_flag_visual()
	
func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		if body.star_count_check():
			audio_stream_player.play()
			SceneManager.load_new_scene(path)
			
func get_player():
	var player = get_tree().get_first_node_in_group("player")
	
	return player

func update_flag_visual():
	var player = get_player()
	
	if player == null:
		sprite.modulate = Color(0, 0, 0) # still locked at start
		return
	
	if player.star_count_check():
		sprite.modulate = Color(1, 1, 1)
	else:
		sprite.modulate = Color(0, 0, 0)
	
