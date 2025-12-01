# state_display.gd - Simple UI to show current state
extends Label

@onready var game_state = get_node("/root/GameStateManager")

func _ready():
	game_state.state_changed.connect(_on_state_changed)
	update_display()

func _on_state_changed(new_state, old_state):
	update_display()

func update_display():
	text = "State: " + game_state.get_state_name()
	
	# Color coding based on state
	match game_state.current_state:
		game_state.GameState.PLAYER_TURN:
			modulate = Color(0, 1, 0)  # Green
		game_state.GameState.UNIT_SELECTED:
			modulate = Color(1, 1, 0)  # Yellow
		game_state.GameState.UNIT_MOVING:
			modulate = Color(1, 0.5, 0)  # Orange
		game_state.GameState.ENEMY_TURN:
			modulate = Color(1, 0, 0)  # Red
		_:
			modulate = Color(1, 1, 1)  # White
