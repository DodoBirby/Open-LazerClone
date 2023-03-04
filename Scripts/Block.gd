class_name Block
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var cell: Vector2
@export var team: int
@export var health: int
var placed: bool: set = set_placed
var neighbours: Array = []

# Directions that block accepts connections from
var connect_dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

signal removed(block)

func _ready():
	self.placed = true

# Temporary, Puts a tint on blocks so team can be seen
func _process(_delta):
	sprite.self_modulate = Color(1, 1 * team, 1, 1)

func set_placed(value):
	set_physics_process(value)
	if value:
		sprite.z_index = 0
		sprite.scale.x = 0.5
		sprite.scale.y = 0.5
		
	else:
		sprite.z_index = 1
		sprite.scale.x = 0.25
		sprite.scale.y = 0.25

func receive_power():
	pass

func explode():
	emit_signal("removed", self)
	queue_free()

func take_damage():
	health -= 1
	if health <= 0:
		explode()
