class_name Generator
extends Block

# Time to create 1 power unit
var gentime = 150

var power = 0
var powered: bool = true
var target: Block = null

func _ready():
	add_to_group("generators")

func _physics_process(delta):
	if not powered:
		return
	if power < gentime:
		power += 1
		
	if power < gentime:
		return
	if target == null:
		return
	power = 0
	target.receive_power()
	
