extends Area2D
class_name Flag

@export var path:NodePath

func _on_body_entered(body: Node2D) -> void:
	print_debug("level complete")
	SceneManager.load_new_scene(path)
