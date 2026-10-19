
extends StaticBody3D

@onready var ingredient_detection: Area3D = $IngredientDetection

var ingredients_on_board: Array[RigidBody3D] = []


func _ready() -> void:
	ingredient_detection.body_entered.connect(_on_body_entered)
	ingredient_detection.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body is RigidBody3D:
		return

	if not body.is_in_group("pegavel"):
		return

	if not ingredients_on_board.has(body):
		ingredients_on_board.append(body)
		print("Objeto detectado na tabua: ", body.name)


func _on_body_exited(body: Node3D) -> void:
	if not body is RigidBody3D:
		return

	if ingredients_on_board.has(body):
		ingredients_on_board.erase(body)
		print("Objeto saiu da tabua: ", body.name)
