
extends StaticBody3D

# Cena do efeito de fumaça.
const CUTTING_EFFECT: PackedScene = preload(
	"res://scenes/effects/SCE_CuttingEffect.tscn"
)

@onready var ingredient_detection: Area3D = $IngredientDetection

var ingredients_on_board: Array[HoldableObject] = []
var ingredients_processing: Array[HoldableObject] = []


func _ready() -> void:
	ingredient_detection.body_entered.connect(_on_body_entered)
	ingredient_detection.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body is HoldableObject:
		return

	var ingredient: HoldableObject = body

	if ingredient.ingredient_data == null:
		return

	var data: IngredientData = ingredient.ingredient_data

	if not data.can_be_cut:
		return

	if data.chopped_scene == null:
		push_warning(
			"Ingrediente sem cena cortada: " + data.display_name
		)
		return

	if ingredients_on_board.has(ingredient):
		return

	ingredients_on_board.append(ingredient)

	print("Iniciando corte: ", data.display_name)

	_process_cut(ingredient)


func _on_body_exited(body: Node3D) -> void:
	if not body is HoldableObject:
		return

	var ingredient: HoldableObject = body

	ingredients_on_board.erase(ingredient)


func _process_cut(ingredient: HoldableObject) -> void:
	if ingredients_processing.has(ingredient):
		return

	ingredients_processing.append(ingredient)

	var data: IngredientData = ingredient.ingredient_data
	var duration: float = maxf(data.cut_duration, 0.0)

	await get_tree().create_timer(duration).timeout

	# Verificar se a tábua ainda existe na cena.
	if not is_inside_tree():
		return

	print("DEBUG: Tempo de corte finalizado!")

	ingredients_processing.erase(ingredient)

	# Verificar se o ingrediente ainda existe.
	if not is_instance_valid(ingredient):
		print("DEBUG: Ingrediente não existe mais!")
		return

	print("DEBUG: Ingrediente existe.")

	# Verificar se continua registrado na tábua.
	if not ingredients_on_board.has(ingredient):
		print("DEBUG: Ingrediente saiu da lista da tábua!")
		return

	print("DEBUG: Ingrediente continua na lista.")

	# Verificar se continua na área de detecção.
	if not ingredient_detection.overlaps_body(ingredient):
		print("DEBUG: Ingrediente não está na área de detecção!")
		return

	print("DEBUG: Todas as verificações passaram!")

	# Criar o ingrediente cortado.
	var chopped_object := data.chopped_scene.instantiate()

	if not chopped_object is RigidBody3D:
		push_error(
			"A cena cortada precisa ter RigidBody3D como raiz."
		)
		chopped_object.free()
		return

	# Guardar a posição e rotação do ingrediente original.
	var original_transform := ingredient.global_transform

	# Adicionar o ingrediente cortado à cena principal.
	get_tree().current_scene.add_child(chopped_object)

	# Posicionar o ingrediente cortado.
	chopped_object.global_transform = original_transform

	# Remover o ingrediente original.
	ingredients_on_board.erase(ingredient)
	ingredient.queue_free()

	# ==========================================
	# EFEITO DE FUMAÇA DO CORTE
	# ==========================================

	# Criar uma instância do efeito.
	var effect := CUTTING_EFFECT.instantiate()

	# Adicionar a fumaça à cena principal.
	get_tree().current_scene.add_child(effect)

	# Posicionar a fumaça onde estava o ingrediente.
	effect.global_position = original_transform.origin

	# Iniciar a animação da fumaça.
	effect.play_effect()

	print("Corte concluído: ", data.display_name)
