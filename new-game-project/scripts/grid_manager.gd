# grid_manager.gd - Global grid management (Singleton/Autoload)
extends Node

# Grid configuration
var grid_size = Vector2i(8, 8)  # Default 8x8 test grid
var cell_size = Vector2(64, 64)  # 64 pixels per cell
const CARDINAL_DIRECTIONS := [
	Vector2i(0, -1),  # Up
	Vector2i(0, 1),   # Down
	Vector2i(-1, 0),  # Left
	Vector2i(1, 0)    # Right
]  # Shared directions array to avoid re-allocating every search
var astar_grid: AStarGrid2D

# Initialize the AStarGrid2D
func _ready():
	initialize_astar_grid()
	print("GridManager initialized: ", grid_size, " grid with cell size: ", cell_size)

# Create and configure AStarGrid2D
func initialize_astar_grid():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, grid_size.x, grid_size.y)
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size * 0.5  # Center points in cells
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  # Chess-style movement
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()
	
	# Make all cells walkable by default
	for x in grid_size.x:
		for y in grid_size.y:
			astar_grid.set_point_solid(Vector2i(x, y), false)

# Convert grid coordinates to screen position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * cell_size + cell_size * 0.5

# Convert screen position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / cell_size)

# Check if a grid position is within bounds
func is_within_grid(grid_pos: Vector2i) -> bool:
	return (grid_pos.x >= 0 and grid_pos.x < grid_size.x and 
			grid_pos.y >= 0 and grid_pos.y < grid_size.y)

# Get movement cost between two adjacent cells (default: 1)
func get_movement_cost(from: Vector2i, to: Vector2i) -> int:
	return 1  # We'll add terrain costs later

# Calculate all reachable positions within movement range
func get_movement_range(start_pos: Vector2i, movement_range: int) -> Array:
	var reachable_cells = []
	var visited = {}
	var queue = [{"pos": start_pos, "cost": 0}]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_pos = current["pos"]
		var current_cost = current["cost"]
		
		# Skip if we've already visited this position with equal or lower cost
		if visited.has(current_pos) and visited[current_pos] <= current_cost:
			continue
		
		visited[current_pos] = current_cost
		
		# Add to reachable if not the starting position
		if current_pos != start_pos:
			reachable_cells.append(current_pos)
		
		# Check all four directions (up, down, left, right)
		for direction in CARDINAL_DIRECTIONS:
			var next_pos = current_pos + direction
			
			# Check if position is within grid bounds and walkable
			if is_within_grid(next_pos) and not astar_grid.is_point_solid(next_pos):
				var next_cost = current_cost + get_movement_cost(current_pos, next_pos)
				
				# If within movement range, add to queue
				if next_cost <= movement_range:
					queue.append({"pos": next_pos, "cost": next_cost})
	
	return reachable_cells

# Get path from start to target using AStar
func get_grid_path(start_pos: Vector2i, target_pos: Vector2i) -> Array:  # CHANGED NAME
	# Check if positions are valid
	if not is_within_grid(start_pos) or not is_within_grid(target_pos):
		return []
	
	# Check if target is reachable (not solid)
	if astar_grid.is_point_solid(target_pos):
		return []
	
	# Get path from AStarGrid2D
	var world_path = astar_grid.get_point_path(start_pos, target_pos)
	var grid_path = []
	
	# Convert world positions back to grid positions
	for world_pos in world_path:
		grid_path.append(world_to_grid(world_pos))
	
	return grid_path

# Check if a position is reachable from start within movement range
func is_position_reachable(start_pos: Vector2i, target_pos: Vector2i, movement_range: int) -> bool:
	var reachable_cells = get_movement_range(start_pos, movement_range)
	for cell in reachable_cells:
		if cell == target_pos:
			return true
	return false
