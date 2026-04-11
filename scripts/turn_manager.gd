extends Node
class_name TurnManager 

@export var player: Character
@export var dragon: Dragon 

var current_char 

var game_over: bool = true

func next_turn():
	if game_over:
		return
	
