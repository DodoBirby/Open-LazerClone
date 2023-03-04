class_name Lazer
extends Block

# Unit vector for firing direction
var facing: Vector2 = Vector2.RIGHT
var charge = 0

func _ready():
	add_to_group("lazers")

func receive_power():
	charge = 180

func _physics_process(_delta):
	if charge > 0:
		charge -= 1

func set_placed(value):
	charge = 0
	set_physics_process(value)
	if value:
		sprite.z_index = 0
		sprite.scale.x = 1
		sprite.scale.y = 1
		
	else:
		sprite.z_index = 1
		sprite.scale.x = 0.5
		sprite.scale.y = 0.5
