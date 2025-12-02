# simple_grid.gd - Easy grid visualization with ColorRect
extends Node2D

# These will hold our highlight rectangles
var movement_highlights: Array = []
var path_highlights: Array = []

func _ready():
	print("Simple Grid ready!")
	draw_simple_grid()
	clear_highlights()

# Draw basic checkerboard grid
func draw_simple_grid():
	var grid_size = GridManager.grid_size
	var cell_size = GridManager.cell_size
	
	# Create alternating colored squares
	for x in grid_size.x:
		for y in grid_size.y:
			var square = ColorRect.new()
			square.size = cell_size
			square.position = _cell_top_left(Vector2i(x, y))
			
			# Alternate colors: light gray and dark gray
			if (x + y) % 2 == 0:
				square.color = Color(0.8, 0.8, 0.8)  # Light gray
			else:
				square.color = Color(0.6, 0.6, 0.6)  # Dark gray
			
			add_child(square)
	
	print("Drawn grid: ", grid_size, " cells")

func _cell_top_left(cell: Vector2i) -> Vector2:
	# ColorRect positions are top-left; convert from center coords
	return GridManager.grid_to_world(cell) - GridManager.cell_size * 0.5

# Show where unit can move (green highlights)
func highlight_movement_range(cells: Array):  # CHANGED
	clear_highlights()  # Clear old highlights
	
	for cell in cells:
		var highlight = ColorRect.new()
		highlight.size = GridManager.cell_size
		highlight.position = _cell_top_left(cell)
		highlight.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
		add_child(highlight)
		movement_highlights.append(highlight)
	
	print("Added ", cells.size(), " movement highlights")

# Show path to target (blue highlights)
func draw_path(path_cells: Array):  # CHANGED
	clear_path()  # Clear old path
	
	# Start from 1 to skip the unit's current position
	for i in range(1, path_cells.size()):
		var cell = path_cells[i]
		var path_cell = ColorRect.new()
		path_cell.size = GridManager.cell_size
		path_cell.position = _cell_top_left(cell)
		path_cell.color = Color(0, 0, 1, 0.5)  # Semi-transparent blue
		add_child(path_cell)
		path_highlights.append(path_cell)
	
	print("Drew path with ", path_cells.size() - 1, " steps")

# Clear all green movement highlights
func clear_highlights():
	for highlight in movement_highlights:
		highlight.queue_free()  # Remove from scene
	movement_highlights.clear()
	print("Cleared movement highlights")

# Clear all blue path highlights
func clear_path():
	for path in path_highlights:
		path.queue_free()
	path_highlights.clear()
	print("Cleared path highlights")
