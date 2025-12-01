# unit.gd - Fixed version
extends Node2D

signal unit_selected(unit)
signal unit_deselected(unit)
signal unit_moved(from_pos, to_pos)
signal movement_finished()

# Unit properties
var grid_position: Vector2i = Vector2i(0, 0)
var movement_range: int = 4
var team: int = 0
var unit_name: String = "Soldier"
var is_moving: bool = false
var movement_speed: float = 300.0
var current_movement_tween: Tween = null

var sprite: Sprite2D
var selection_indicator: Sprite2D

func _ready():
	sprite = $Sprite2D
	selection_indicator = $SelectionIndicator
	
	update_position_visual()
	print("Unit '", unit_name, "' ready at ", grid_position)

func update_position_visual():
	var world_pos = GridManager.grid_to_world(grid_position)
	#sprite.position = Vector2.ZERO
	self.position = world_pos
	print("Unit moved to world position: ", world_pos)

func set_grid_position(new_position: Vector2i):
	var old_position = grid_position
	grid_position = new_position
	update_position_visual()
	unit_moved.emit(old_position, new_position)

func select():
	selection_indicator.visible = true
	unit_selected.emit(self)
	print("Unit selected: ", unit_name)

func deselect():
	selection_indicator.visible = false
	unit_deselected.emit(self)

func is_within_move_range(target_pos: Vector2i) -> bool:
	var distance = abs(target_pos.x - grid_position.x) + abs(target_pos.y - grid_position.y)
	return distance <= movement_range

func get_movement_cost_to(target_pos: Vector2i) -> int:
	return 1

func is_at_position(check_pos: Vector2i) -> bool:
	return grid_position == check_pos

func move_along_path(path_cells: Array):
	if is_moving:
		print("Unit is already moving!")
		return
	
	if path_cells.size() <= 1:
		print("Path too short to move")
		return
	
	is_moving = true
	
	current_movement_tween = create_tween()
	current_movement_tween.set_trans(Tween.TRANS_SINE)
	current_movement_tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in range(1, path_cells.size()):
		var target_world_pos = GridManager.grid_to_world(path_cells[i])
		var distance = position.distance_to(target_world_pos)
		var duration = distance / movement_speed
		
		current_movement_tween.tween_property(self, "position", target_world_pos, duration)
	
	current_movement_tween.tween_callback(func(): 
		set_grid_position(path_cells[path_cells.size() - 1])
		is_moving = false
		movement_finished.emit()
	)
	
	print("Unit moving along path with ", path_cells.size(), " steps")
