extends TileMap

var blockmap: Dictionary = {}
var lazerqueue: Array = []
var timer = 0
var grid: Resource = preload("res://Scripts/Grid.tres")
var wall: PackedScene = preload("res://Scenes/wall.tscn")

func _ready():
	
	for child in get_children():
		#Connect all player signals
		if child is Player:
			var player: Player = child
			player.interact.connect(_on_Player_Interact)
			player.move.connect(_on_Player_Move)
		#Connect block signals and place it on the map
		if child is Block:
			var cell = grid.map_to_grid(child.position)
			var block: Block = child
			block.removed.connect(_on_Block_removed)
			place_block(child, cell)
		if child is Shop:
			child.create_block.connect(_on_Block_created)
	add_block(wall, Vector2(2, 2), 0)


#Runs 60 times per second
func _physics_process(_delta):
	timer += 1
	timer = timer % 10
	#Calculate new energy targets every 10 frames
	if timer == 0:
		calculate_energy_targets()
	# Loop through all lazers and deal damage to block in front of them
	for lazer in get_tree().get_nodes_in_group("lazers"):
		if lazer.charge <= 0:
			continue
		
		var target = calculate_lazer_target(lazer)
		# Check that target exists
		if target == null:
			continue
		# Check that target is on a different team
		if target.team == lazer.team:
			continue
		target.take_damage()
	
# Loops through all blocks in front of lazer until edge of map is reached or target is found.
# Returns null if no target found
func calculate_lazer_target(lazer: Lazer):
	var target = null
	var beam = lazer.cell
	while target == null:
		beam = beam + lazer.facing
		if blockmap.has(beam):
			target = blockmap[beam]
		elif not grid.cell_in_bounds(beam):
			break
	return target

# Create a new block at position of the team given
func add_block(block: PackedScene, pos, team):
	var newblock: Block = block.instantiate()
	add_child(newblock)
	newblock.removed.connect(_on_Block_removed)
	newblock.team = team
	place_block(newblock, pos)

# Place exisiting block at position
func place_block(block: Block, pos: Vector2):
	blockmap[pos] = block
	block.cell = pos
	block.position = grid.grid_to_map(block.cell)
	block.placed = true
	block.neighbours = find_connectable_neighbours(block)
	for neighbour in block.neighbours:
		neighbour.neighbours.append(block)
	if block is Lazer:
		lazerqueue.push_back(block)

# Returns whether player can move into position
func can_move_to(pos: Vector2) -> bool:
	if not grid.cell_in_bounds(pos):
		return false
	if blockmap.has(pos):
		return false
	return true

# Returns all adjacent blocks that can be connected to
func find_connectable_neighbours(block: Block):
	var neighbours = []
	for dir in block.connect_dirs:
		var pos = block.cell + dir
		if not blockmap.has(pos):
			continue
		var neighbour: Block = blockmap[pos]
		if neighbour.team != block.team:
			continue
		if not neighbour.connect_dirs.has(dir * -1):
			continue
		neighbours.append(neighbour)
	return neighbours

# Removes existing block from game
func remove_block(block: Block):
	blockmap.erase(block.cell)
	clear_from_neighbours(block)
	block.neighbours.clear()
	if block is Lazer:
		lazerqueue.erase(block)

# Deletes block from neighbours list in all its neighbours
func clear_from_neighbours(block: Block):
	for neighbour in block.neighbours:
		neighbour.neighbours.erase(block)

# Removes block from field and places in inventory of player
func pickup_block(block: Block, player: Player):
	if player.team != block.team:
		return
	block.placed = false
	player.inventory = block
	remove_block(block)

# Breadth first search to find closest generator with no target
# Returns null if no targets found
func find_available_generator(requestor):
	var blockstack = []
	var visited = {}
	blockstack.append(requestor)
	while blockstack.size() > 0:
		var block = blockstack.pop_back()
		for neighbour in block.neighbours:
			if visited.has(neighbour):
				continue
			blockstack.append(neighbour)
			visited[neighbour] = true
			if not neighbour is Generator:
				continue
			if neighbour.target != null:
				continue
			return neighbour
	return null

# Sets target value of generators to connected lazers
func calculate_energy_targets():
	# Set all generator targets to null
	for generator in get_tree().get_nodes_in_group("generators"):
		generator.target = null
	# Loop through lazers in order of placement
	for lazer in lazerqueue:
		var generator = find_available_generator(lazer)
		if generator != null:
			generator.target = lazer

func _on_Player_Move(player: Player, dir: Vector2):
	if can_move_to(player.cell + dir):
		player.begin_move(dir)

func _on_Player_Interact(player: Player, pos: Vector2):
	# Block in hand
	if player.inventory != null:
		if blockmap.has(pos):
			if blockmap[pos] is InteractBlock:
				blockmap[pos].interact(player)
			return
		# Can't place out of bounds
		if not grid.cell_in_bounds(pos):
			return
		# Place block and remove from inventory
		place_block(player.inventory, pos)
		player.inventory = null
	# If no block in hand but block in target tile
	elif blockmap.has(pos):
		if blockmap[pos] is InteractBlock:
			blockmap[pos].interact(player)
		else:
			pickup_block(blockmap[pos], player)
		
func _on_Block_removed(block: Block):
	remove_block(block)

func _on_Block_created(block: Block):
	add_child(block)
	block.removed.connect(_on_Block_removed)
	block.position = grid.grid_to_map(block.cell)
