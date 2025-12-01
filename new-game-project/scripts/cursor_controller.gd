# cursor_controller.gd - Handles cursor movement and input
extends Node

signal cursor_moved(new_position)
signal cursor_selected(position)
signal cursor_cancelled

var grid_position: Vector2i = Vector2i(4, 4)
var move_delay: float = 0.15
var move_timer: float = 0.0
var is_active: bool = true

@onready var game_state = get_node("/root/GameStateManager")
@onready var cursor_sprite: Sprite2D = get_parent().get_node("Sprite2D")

func _ready():
	update_cursor_position()
	# Listen to state changes
	game_state.state_changed.connect(_on_state_changed)

func _process(delta):
	if not is_active:
		return
	
	if move_timer > 0:
		move_timer -= delta
		return
	
	handle_input()

func _on_state_changed(new_state, old_state):
	# Update cursor activity based on state
	is_active = game_state.is_cursor_allowed()
	
	# Visual feedback for cursor
	if is_active:
		cursor_sprite.modulate = Color(1, 1, 1, 1)  # Full visibility
	else:
		cursor_sprite.modulate = Color(1, 1, 1, 0.3)  # Dimmed
	
	print("Cursor active: ", is_active, " in state: ", game_state.GameState.keys()[new_state])

func handle_input():
	var moved = false
	var new_pos = grid_position
	
	# Handle movement based on state
	if game_state.current_state == game_state.GameState.PLAYER_TURN or \
	   game_state.current_state == game_state.GameState.UNIT_SELECTED:
		
		if Input.is_action_pressed("move_right"): new_pos.x += 1; moved = true
		elif Input.is_action_pressed("move_left"): new_pos.x -= 1; moved = true
		elif Input.is_action_pressed("move_down"): new_pos.y += 1; moved = true
		elif Input.is_action_pressed("move_up"): new_pos.y -= 1; moved = true
	
	if moved and GridManager.is_within_grid(new_pos):
		grid_position = new_pos
		update_cursor_position()
		cursor_moved.emit(grid_position)
		move_timer = move_delay
	
	# Handle selection based on state
	if Input.is_action_just_pressed("select"):
		cursor_selected.emit(grid_position)
	
	# Handle cancel based on state
	if Input.is_action_just_pressed("cancel"):
		if game_state.current_state == game_state.GameState.UNIT_SELECTED:
			cursor_cancelled.emit()
		elif game_state.current_state == game_state.GameState.PLAYER_TURN:
			# Could be used for menu or other actions
			pass

func update_cursor_position():
	cursor_sprite.position = GridManager.grid_to_world(grid_position)

func get_position() -> Vector2i:
	return grid_position

func set_position(pos: Vector2i):
	if GridManager.is_within_grid(pos):
		grid_position = pos
		update_cursor_position()
