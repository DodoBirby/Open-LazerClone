class_name Player
extends Node2D

@export var MOVESPEED: int = 8
@export var team = 0
var moving: bool = false
var cell: Vector2 = Vector2.ZERO
var movedir: Vector2 = Vector2.ZERO
var prevdir: Vector2 = Vector2.ZERO
var grid: Resource = preload("res://Scripts/Grid.tres")
var inventory: Block = null

signal interact(player, position)
signal move(player, dir)

func _ready():
	cell = grid.map_to_grid(position)
	position = grid.grid_to_map(cell)

func _physics_process(_delta):
	if inventory != null:
		inventory.position = grid.grid_to_map(cell + prevdir)
	get_pickup_input()
	if not moving:
		get_move_input()
	if moving:
		var targetpos = grid.grid_to_map(cell)
		position += movedir
		if position == targetpos:
			end_move()
 
func get_pickup_input():
	var dir = Vector2.ZERO
	if Input.is_action_just_pressed("turn_up1"):
		dir = Vector2.UP
	elif Input.is_action_just_pressed("turn_down1"):
		dir = Vector2.DOWN
	elif Input.is_action_just_pressed("turn_left1"):
		dir = Vector2.LEFT
	elif Input.is_action_just_pressed("turn_right1"):
		dir = Vector2.RIGHT
	else:
		return
	prevdir = dir
	emit_signal("interact", self, cell + dir)

func get_move_input():
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_down1"):
		dir = Vector2.DOWN
	elif Input.is_action_pressed("move_up1"):
		dir = Vector2.UP
	elif Input.is_action_pressed("move_right1"):
		dir = Vector2.RIGHT
	elif Input.is_action_pressed("move_left1"):
		dir = Vector2.LEFT
	else:
		return
	prevdir = dir
	emit_signal("move", self, dir)

func begin_move(dir: Vector2):
	moving = true
	cell += dir
	movedir = dir * MOVESPEED

func end_move():
	movedir = Vector2.ZERO
	moving = false


