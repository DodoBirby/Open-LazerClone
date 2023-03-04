class_name Grid
extends Resource

@export var cell_size = 64

@export var gridwidth = 15
@export var gridheight = 11

var _half_cell_size = cell_size / 2

func grid_to_map(gridpos: Vector2) -> Vector2:
	var outpos = Vector2()
	outpos.x = gridpos.x * cell_size + _half_cell_size
	outpos.y = gridpos.y * cell_size + _half_cell_size
	return outpos
	
func map_to_grid(mappos: Vector2) -> Vector2:
	var outpos = Vector2()
	outpos.x = floor(mappos.x / cell_size)
	outpos.y = floor(mappos.y / cell_size)
	return outpos
	
func cell_in_bounds(gridpos: Vector2) -> bool:
	var x_in_bounds = gridpos.x >= 0 and gridpos.x < gridwidth
	var y_in_bounds = gridpos.y >= 0 and gridpos.y < gridheight
	return x_in_bounds and y_in_bounds

func as_index(gridpos: Vector2) -> int:
	return (gridpos.y * gridwidth + gridpos.x)



