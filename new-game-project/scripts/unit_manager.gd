# unit_manager.gd - Manages all units on the grid
extends Node

var units: Array = []  # Array of all units
var selected_unit = null
var current_reachable_cells: Array = []

@onready var game_state = get_node("/root/GameStateManager")

func _ready():
	print("UnitManager ready")

# Add a unit to the manager
func add_unit(unit_node):
	units.append(unit_node)
	print("Added unit: ", unit_node.unit_name)

# Get unit at specific grid position
func get_unit_at_position(grid_pos: Vector2i):
	for unit in units:
		if unit.is_at_position(grid_pos):
			return unit
	return null

# Select a unit (deselects previous if any)
func select_unit(unit) -> bool:
	if not game_state.is_input_allowed():
		print("Cannot select unit in current state: ", game_state.get_state_name())
		return false
	
	if selected_unit and selected_unit != unit:
		selected_unit.deselect()
		clear_movement_range()
	
	selected_unit = unit
	unit.select()
	
	# Calculate and display movement range
	if selected_unit:
		current_reachable_cells = GridManager.get_movement_range(
			selected_unit.grid_position, 
			selected_unit.movement_range
		)
		display_movement_range()
		game_state.start_unit_selection()
	
	print("Selected unit: ", unit.unit_name, " with ", current_reachable_cells.size(), " reachable cells")
	game_state.unit_selected.emit(unit)
	return true

# Deselect current unit
func deselect_current_unit():
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	
	clear_movement_range()
	game_state.cancel_unit_selection()
	print("Unit deselected")

# Display movement range on grid
func display_movement_range():
	if get_tree().get_root().has_node("Main/Grid"):
		var grid = get_tree().get_root().get_node("Main/Grid")
		grid.highlight_movement_range(current_reachable_cells)

func clear_movement_range():
	current_reachable_cells.clear()
	
	if get_tree().get_root().has_node("Main/Grid"):
		var grid = get_tree().get_root().get_node("Main/Grid")
		grid.clear_highlights()
		grid.clear_path()
# Check if position is in movement range
func is_position_in_movement_range(grid_pos: Vector2i) -> bool:
	for cell in current_reachable_cells:
		if cell == grid_pos:
			return true
	return false

# Get path to target position
func get_path_to_target(target_pos: Vector2i) -> Array:
	if selected_unit:
		return GridManager.get_grid_path(selected_unit.grid_position, target_pos)  # CHANGED
	return []
# Move selected unit to position (with validation)
func move_selected_unit_to(target_pos: Vector2i) -> bool:
	if not selected_unit:
		print("No unit selected")
		return false
	
	if not game_state.is_movement_allowed():
		print("Movement not allowed in current state: ", game_state.get_state_name())
		return false
	
	if not is_position_in_movement_range(target_pos):
		print("Target position not in movement range")
		return false
	
	# Check if another unit is at the target position
	var unit_at_target = get_unit_at_position(target_pos)
	if unit_at_target and unit_at_target != selected_unit:
		print("Another unit is at the target position")
		return false
	
	# Get path to target
	var path = get_path_to_target(target_pos)
	if path.size() == 0:
		print("No valid path to target")
		return false
	
	# Start movement and clear visuals
	game_state.start_unit_movement()
	clear_movement_range()
	
	# Move unit along path
	selected_unit.move_along_path(path)
	
	# Connect to movement completion
	selected_unit.movement_finished.connect(_on_unit_movement_finished, CONNECT_ONE_SHOT)
	
	print("Unit moving to ", target_pos, " via ", path.size(), " steps")
	return true

func _on_unit_movement_finished():
	print("Unit movement finished")
	game_state.finish_unit_movement()
	
	# For Fire Emblem style, after moving you can still act (attack, wait, etc.)
	# For MVP, we'll deselect the unit after moving
	deselect_current_unit()

# Get all units on a specific team
func get_units_by_team(team_id: int):
	var team_units = []
	for unit in units:
		if unit.team == team_id:
			team_units.append(unit)
	return team_units
