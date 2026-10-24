
class_name IngredientData
extends Resource

@export_group("Identification")
@export var ingredient_id: StringName
@export var display_name: String = ""

@export_group("Cutting")
@export var can_be_cut: bool = false
@export var cut_duration: float = 1.5
@export var chopped_scene: PackedScene
