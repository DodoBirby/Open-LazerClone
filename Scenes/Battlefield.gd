extends TileMap

var blockmap: Dictionary = {}
var lazerqueue: Array = []
var timer = 0
var grid: Resource = preload("res://Scripts/Grid.tres")
var wall: PackedScene = preload("res://Scenes/wall.tscn")

func _ready():
	for child in get_children():
		if child is Player:
			var player: Player = child
			player.interact.connect(_on_Player_Interact)
			player.move.connect(_on_Player_Move)
		if child is Block:
			var cell = grid.map_to_grid(child.position)
			var block: Block = child
			block.removed.connect(_on_Block_removed)
			place_block(child, cell)
	add_block(wall, Vector2(2, 2), 0)
	
func _physics_process(_delta):
	timer += 1
	timer = timer % 10
	if timer == 0:
		calculate_energy_targets()
	for lazer in get_tree().get_nodes_in_group("lazers"):
		if lazer.charge <= 0:
			continue
		
		var target = calculate_lazer_target(lazer)
		if target == null:
			continue
		if target.team == lazer.team:
			continue
		target.take_damage()
	
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


func add_block(block: PackedScene, pos, team):
	var newblock: Block = block.instantiate()
	add_child(newblock)
	newblock.removed.connect(_on_Block_removed)
	newblock.team = team
	place_block(newblock, pos)

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
	
func can_move_to(pos) -> bool:
	if not grid.cell_in_bounds(pos):
		return false
	if blockmap.has(pos):
		return false
	return true

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

func remove_block(block: Block):
	blockmap.erase(block.cell)
	clear_from_neighbours(block)
	if block is Lazer:
		lazerqueue.erase(block)

func clear_from_neighbours(block: Block):
	for neighbour in block.neighbours:
		neighbour.neighbours.erase(block)

func pickup_block(block: Block, pos, player):
	if player.team != block.team:
		return
	blockmap.erase(pos)
	block.placed = false
	player.inventory = block
	clear_from_neighbours(block)
	block.neighbours.clear()
	if block is Lazer:
		lazerqueue.erase(block)

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

func purchase_block(shop: Shop, player: Player):
	if player.team != shop.team:
		return
	var block: Block = shop.product.instantiate()
	add_child(block)
	block.placed = false
	block.team = shop.team
	block.removed.connect(_on_Block_removed)
	block.position = grid.grid_to_map(player.cell + player.prevdir)
	player.inventory = block

func sell_block(block: Block, player: Player):
	player.inventory = null
	block.queue_free()

func calculate_energy_targets():
	for generator in get_tree().get_nodes_in_group("generators"):
		generator.target = null
	for lazer in lazerqueue:
		var generator = find_available_generator(lazer)
		if generator != null:
			generator.target = lazer

func _on_Player_Move(player: Player, dir: Vector2):
	if can_move_to(player.cell + dir):
		player.begin_move(dir)

func _on_Player_Interact(player: Player, pos: Vector2):
	if player.inventory != null:
		if blockmap.has(pos):
			if blockmap[pos] is Shop:
				sell_block(player.inventory, player)
			return
		if not grid.cell_in_bounds(pos):
			return
		place_block(player.inventory, pos)
		player.inventory = null

	elif blockmap.has(pos):
		if blockmap[pos] is Shop:
			purchase_block(blockmap[pos], player)
		else:
			pickup_block(blockmap[pos], pos, player)
		
func _on_Block_removed(block: Block):
	remove_block(block)
