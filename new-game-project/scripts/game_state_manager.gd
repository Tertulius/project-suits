# game_state_manager.gd - Enhanced state machine (Singleton/Autoload)
extends Node

enum GameState {
	PLAYER_TURN,      # Player can move cursor, select units
	UNIT_SELECTED,    # Unit is selected, showing movement range
	UNIT_MOVING,      # Unit is currently moving
	ENEMY_TURN,       # Enemy AI turn (placeholder for future)
	ANIMATION_LOCK    # Short state to prevent input during animations
}

var current_state = GameState.PLAYER_TURN
var previous_state = GameState.PLAYER_TURN

signal state_changed(new_state, old_state)
signal player_turn_started()
signal enemy_turn_started()
signal unit_selected(unit)
signal unit_deselected()
signal unit_movement_started()
signal unit_movement_finished()
signal animation_lock_started()
signal animation_lock_finished()

# Change to a new state with validation
func change_state(new_state: GameState, force: bool = false):
	if new_state == current_state and not force:
		return
	
	# Validate state transitions
	if not is_valid_transition(current_state, new_state):
		print("Invalid state transition: ", GameState.keys()[current_state], " -> ", GameState.keys()[new_state])
		return
	
	# Store old state and update
	var old_state = current_state
	previous_state = old_state
	current_state = new_state
	
	print("Game state: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	state_changed.emit(new_state, old_state)
	
	# Emit specific state signals
	match new_state:
		GameState.PLAYER_TURN:
			player_turn_started.emit()
		GameState.ENEMY_TURN:
			enemy_turn_started.emit()
		GameState.UNIT_SELECTED:
			# This will be emitted by unit selection logic
			pass
		GameState.UNIT_MOVING:
			unit_movement_started.emit()
		GameState.ANIMATION_LOCK:
			animation_lock_started.emit()

# Check if a state transition is valid
func is_valid_transition(from_state: GameState, to_state: GameState) -> bool:
	var valid_transitions = {
		GameState.PLAYER_TURN: [GameState.UNIT_SELECTED, GameState.ENEMY_TURN, GameState.ANIMATION_LOCK],
		GameState.UNIT_SELECTED: [GameState.PLAYER_TURN, GameState.UNIT_MOVING, GameState.ANIMATION_LOCK],
		GameState.UNIT_MOVING: [GameState.PLAYER_TURN, GameState.ENEMY_TURN, GameState.ANIMATION_LOCK],
		GameState.ENEMY_TURN: [GameState.PLAYER_TURN, GameState.ANIMATION_LOCK],
		GameState.ANIMATION_LOCK: [GameState.PLAYER_TURN, GameState.UNIT_SELECTED, GameState.ENEMY_TURN]
	}
	
	return to_state in valid_transitions.get(from_state, [])

# Check if input should be processed
func is_input_allowed() -> bool:
	return current_state == GameState.PLAYER_TURN or current_state == GameState.UNIT_SELECTED

# Check if movement is allowed
func is_movement_allowed() -> bool:
	return current_state == GameState.UNIT_SELECTED

# Check if cursor movement is allowed
func is_cursor_allowed() -> bool:
	return current_state == GameState.PLAYER_TURN or current_state == GameState.UNIT_SELECTED

# Start unit selection process
func start_unit_selection():
	change_state(GameState.UNIT_SELECTED)

# Cancel unit selection
func cancel_unit_selection():
	change_state(GameState.PLAYER_TURN)
	unit_deselected.emit()

# Start unit movement
func start_unit_movement():
	change_state(GameState.UNIT_MOVING)

# Finish unit movement
func finish_unit_movement():
	unit_movement_finished.emit()
	# Don't automatically return to PLAYER_TURN - let the caller decide

# Start enemy turn
func start_enemy_turn():
	change_state(GameState.ENEMY_TURN)

# Finish enemy turn
func finish_enemy_turn():
	change_state(GameState.PLAYER_TURN)

# Start animation lock (for any short animations)
func start_animation_lock():
	change_state(GameState.ANIMATION_LOCK)

# Finish animation lock
func finish_animation_lock():
	change_state(previous_state)
	animation_lock_finished.emit()

# Get current state name for debugging
func get_state_name() -> String:
	return GameState.keys()[current_state]
