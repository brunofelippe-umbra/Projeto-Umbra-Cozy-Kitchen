
class_name HoldableObject
extends RigidBody3D

@export_group("Holding")
@export var hold_position: Vector3 = Vector3.ZERO
@export var hold_rotation: Vector3 = Vector3.ZERO

@export_group("Ingredient")
@export var ingredient_data: IngredientData
