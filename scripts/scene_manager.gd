extends Node

signal content_invalid
signal content_finished_loading(content)


var loading_screen:LoadingScreen
var _transition: String
var _loading_screen_scene: PackedScene = preload("res://scenes/loading_screen.tscn")
var _content_path
var _load_progress_timer

func _ready() -> void:
	#content_invalid.connect(on_content_invalid)
	#content_failed_to_load.connect(on_content_failed_to_load)
	content_finished_loading.connect(on_content_finished_loading)

func load_new_scene(content_path: String, transition_type: String = "pixel_to_black")->void:
	_transition =  transition_type
	loading_screen =  _loading_screen_scene.instantiate()
	get_tree().root.add_child(loading_screen)
	loading_screen.start_transition(transition_type)
	_load_content(content_path)
	print("load content")
	
	
func _load_content(content_path: String):
	print("await transition_in_complete")
	if loading_screen != null:
		await loading_screen.transition_in_complete
	print("transition_in_complete")
	
	_content_path = content_path
	var loader =  ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		content_invalid.emit(content_path)
		return
		
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(monitor_load_status)
	get_tree().root.add_child(_load_progress_timer)
	_load_progress_timer.start()


func on_content_finished_loading(content) -> void:
	print("on_content_finished_loading")
	var outgoing_scene = get_tree().current_scene
	outgoing_scene.queue_free()
	
	get_tree().root.call_deferred("add_child",content)
	get_tree().set_deferred("current_scene",content)
	
	if loading_screen != null:
		loading_screen.finish_transition()
		
		await loading_screen.animation_player.animation_finished
		loading_screen = null

func monitor_load_status() -> void:
	print("monitor load status")
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_content_path, load_progress)
	
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("THREAD_LOAD_IN_PROGRESS")
				#loading_screen.update_bar(load_progress[0] * 100) #0.1
		ResourceLoader.THREAD_LOAD_LOADED:
			print("THREAD_LOAD_LOADED")
			#_load_progress_timer.stop()
			#_load_progress_timer.queue_free()
			content_finished_loading.emit(ResourceLoader.load_threaded_get(_content_path).instantiate())
