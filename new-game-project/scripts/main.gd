# main.gd - Root script for the game
extends Node2D

@onready var cursor_node = $Cursor  # The parent Node2D
@onready var cursor_controller = $Cursor/CursorController  # The cursor controller script
@onready var units_container = $Units
@onready var unit_manager = $GameManager/UnitManager
@onready var grid = $Grid
@onready var game_state = get_node("/root/GameStateManager")

var current_path: Array = []

func _ready():
	print("=== GAME STARTING ===")
	print("Checking systems...")
	
	# Quick test of GridManager
	print("Grid size: ", GridManager.grid_size)
	print("Cell size: ", GridManager.cell_size)
	
	setup_units()
	connect_signals()
	setup_initial_state()
	
	print("=== GAME READY ===")
	print("State: ", game_state.get_state_name())

func setup_units():
	print("Setting up units...")
	
	# Create player unit
	var player_unit = preload("res://scenes/unit.tscn").instantiate()
	player_unit.unit_name = "Player Knight"
	player_unit.team = 0
	player_unit.set_grid_position(Vector2i(2, 3))
	units_container.add_child(player_unit)
	unit_manager.add_unit(player_unit)
	
	# Create enemy unit
	var enemy_unit = preload("res://scenes/unit.tscn").instantiate()
	enemy_unit.unit_name = "Enemy Soldier"
	enemy_unit.team = 1
	enemy_unit.set_grid_position(Vector2i(5, 4))
	enemy_unit.get_node("Sprite2D").texture = preload("res://assets/unit_enemy.png")
	units_container.add_child(enemy_unit)
	unit_manager.add_unit(enemy_unit)
	
	print("Units placed: Player at (2,3), Enemy at (5,4)")

func setup_initial_state():
	# Position cursor near player unit
	cursor_controller.set_position(Vector2i(2, 3))
	game_state.change_state(game_state.GameState.PLAYER_TURN, true)

func connect_signals():
	print("Connecting signals...")
	
	# Connect cursor signals
	cursor_controller.cursor_selected.connect(_on_cursor_selected)
	cursor_controller.cursor_moved.connect(_on_cursor_moved)
	cursor_controller.cursor_cancelled.connect(_on_cursor_cancelled)
	
	# Connect game state signals
	game_state.state_changed.connect(_on_game_state_changed)
	game_state.player_turn_started.connect(_on_player_turn_started)
	game_state.enemy_turn_started.connect(_on_enemy_turn_started)
	game_state.unit_movement_finished.connect(_on_unit_movement_finished)
	
	print("All signals connected")

func _on_cursor_selected(grid_pos: Vector2i):
	print("=== Cursor Selected ===")
	print("Position: ", grid_pos)
	print("Current State: ", game_state.get_state_name())
	
	match game_state.current_state:
		game_state.GameState.PLAYER_TURN:
			# Try to select a unit
			var unit = unit_manager.get_unit_at_position(grid_pos)
			if unit and unit.team == 0:  # Only select player units
				print("Selecting unit: ", unit.unit_name)
				unit_manager.select_unit(unit)
			else:
				print("No selectable unit at position ", grid_pos)
		
		game_state.GameState.UNIT_SELECTED:
			# Try to move selected unit
			print("Attempting to move unit to ", grid_pos)
			var success = unit_manager.move_selected_unit_to(grid_pos)
			if not success:
				print("Move failed to position ", grid_pos)
		
		_:
			print("Selection not allowed in state: ", game_state.get_state_name())

func _on_cursor_moved(grid_pos: Vector2i):
	# Show path preview if in UNIT_SELECTED state
	if game_state.current_state == game_state.GameState.UNIT_SELECTED:
		if unit_manager.selected_unit and unit_manager.is_position_in_movement_range(grid_pos):
			# Get and display path
			current_path = unit_manager.get_path_to_target(grid_pos)
			if current_path.size() > 0:
				grid.draw_path(current_path)
		else:
			# Clear path if not reachable
			grid.clear_path()
			current_path.clear()

func _on_cursor_cancelled():
	print("=== Cancel Pressed ===")
	print("Current State: ", game_state.get_state_name())
	
	if game_state.current_state == game_state.GameState.UNIT_SELECTED:
		print("Cancelling unit selection")
		unit_manager.deselect_current_unit()
		grid.clear_path()
	elif game_state.current_state == game_state.GameState.PLAYER_TURN:
		print("In player turn - cancel could open menu in future")

func _on_game_state_changed(new_state, old_state):
	print("=== State Change ===")
	print("From: ", game_state.GameState.keys()[old_state])
	print("To: ", game_state.GameState.keys()[new_state])
	
	# Handle visual changes based on state
	match new_state:
		game_state.GameState.PLAYER_TURN:
			# Ensure cursor is visible and active
			cursor_controller.get_parent().visible = true
			grid.clear_path()
		
		game_state.GameState.UNIT_MOVING:
			# Hide cursor during movement
			cursor_controller.get_parent().visible = false
			grid.clear_path()
		
		game_state.GameState.UNIT_SELECTED:
			# Cursor remains visible
			cursor_controller.get_parent().visible = true
		
		game_state.GameState.ENEMY_TURN:
			# Hide cursor during enemy turn
			cursor_controller.get_parent().visible = false
			grid.clear_path()

func _on_player_turn_started():
	print("=== Player Turn Started ===")
	print("Ready for player input")

func _on_unit_movement_finished():
	print("=== Unit Movement Finished ===")

var enemy_units_moving: int = 0

func _on_enemy_turn_started():
	print("=== Enemy Turn Started ===")
	# Move all enemy units
	var enemy_units = unit_manager.get_units_by_team(1)  # Team 1 is enemy
	
	if enemy_units.size() == 0:
		print("No enemy units found, ending enemy turn")
		game_state.finish_enemy_turn()
		return
	
	# Reset counter
	enemy_units_moving = 0
	var units_that_will_move = 0
	
	# Move each enemy unit towards the closest player unit
	for enemy_unit in enemy_units:
		var closest_player = unit_manager.find_closest_player_unit(enemy_unit)
		
		if closest_player:
			var target_pos = unit_manager.get_best_move_towards_target(
				enemy_unit, 
				closest_player.grid_position
			)
			
			# Only move if we found a better position
			if target_pos != enemy_unit.grid_position:
				# Connect to movement finished to track when all enemies are done
				enemy_unit.movement_finished.connect(_on_enemy_unit_moved, CONNECT_ONE_SHOT)
				unit_manager.move_unit_to(enemy_unit, target_pos)
				units_that_will_move += 1
			else:
				# Unit can't move closer, skip it
				pass
		else:
			# No player units found, skip
			pass
	
	# If no units moved, end turn immediately
	if units_that_will_move == 0:
		print("No enemy units can move, ending enemy turn")
		await get_tree().create_timer(0.3).timeout
		game_state.finish_enemy_turn()
	else:
		enemy_units_moving = units_that_will_move

func _on_enemy_unit_moved():
	enemy_units_moving -= 1
	print("Enemy unit finished moving. Remaining: ", enemy_units_moving)
	if enemy_units_moving <= 0:
		_on_all_enemies_moved()

func _on_all_enemies_moved():
	print("=== All Enemy Units Moved ===")
	# Wait a brief moment then end enemy turn
	await get_tree().create_timer(0.5).timeout
	game_state.finish_enemy_turn()

# Debug function to print current game state
func print_game_state():
	print("\n=== Current Game State ===")
	print("State: ", game_state.get_state_name())
	print("Cursor Position: ", cursor_controller.get_position())
	print("Selected Unit: ", unit_manager.selected_unit.unit_name if unit_manager.selected_unit else "None")
	print("Units on Grid: ", unit_manager.units.size())
	print("========================\n")
