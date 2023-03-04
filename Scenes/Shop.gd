class_name Shop
extends InteractBlock

@export var product: PackedScene

signal create_block(block)

func interact(player: Player):
	if player.inventory == null:
		if player.team != team:
			return
		var block: Block = product.instantiate()
		block.cell = player.cell + player.prevdir
		emit_signal("create_block", block)
		block.placed = false
		block.team = team
		player.inventory = block
	else:
		player.inventory.queue_free()
		player.inventory = null
