
extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002
const PUSH_FORCE = 2.0
const THROW_FORCE = 3.0

# Quanto da velocidade do jogador o objeto herda
const DROP_VELOCITY_MULTIPLIER = 1.0

var objeto_seguro: RigidBody3D = null

@onready var head = $Head
@onready var raycast = $Head/Camera3D/RayCast3D
@onready var hold_point = $Head/Camera3D/Marker3D
@onready var mensagem_pegar = $CanvasLayer/Label


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mensagem_pegar.visible = false


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)

		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-89),
			deg_to_rad(89)
		)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# ARREMESSAR OBJETO
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if objeto_seguro != null:
				var direcao = -$Head/Camera3D.global_transform.basis.z

				soltar_objeto(
					direcao * THROW_FORCE
				)


func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1

	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# EMPURRAR OBJETOS
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is RigidBody3D:
			if collider == objeto_seguro:
				continue

			var push_direction = -collision.get_normal()
			push_direction.y = 0

			if push_direction.length_squared() > 0:
				collider.apply_central_impulse(
					push_direction.normalized() * PUSH_FORCE
				)

	# MOSTRAR MENSAGEM
	if objeto_seguro == null:
		if raycast.is_colliding():
			var objeto = raycast.get_collider()

			if objeto is RigidBody3D and objeto.is_in_group("pegavel"):
				mensagem_pegar.visible = true
			else:
				mensagem_pegar.visible = false
		else:
			mensagem_pegar.visible = false
	else:
		mensagem_pegar.visible = false

	# PEGAR / SOLTAR COM E
	if Input.is_action_just_pressed("interagir"):
		if objeto_seguro != null:
			soltar_objeto()
		else:
			if raycast.is_colliding():
				var objeto = raycast.get_collider()

				if objeto is RigidBody3D and objeto.is_in_group("pegavel"):
					pegar_objeto(objeto)


func pegar_objeto(objeto: RigidBody3D):
	objeto_seguro = objeto

	objeto.freeze = true
	objeto.linear_velocity = Vector3.ZERO
	objeto.angular_velocity = Vector3.ZERO

	objeto.reparent(hold_point, true)

	# POSIÇÃO E ROTAÇÃO PERSONALIZADAS
	if objeto is HoldableObject:
		objeto.position = objeto.hold_position
		objeto.rotation_degrees = objeto.hold_rotation
	else:
		# Compatibilidade com objetos antigos
		objeto.position = Vector3.ZERO
		objeto.rotation = Vector3.ZERO


func soltar_objeto(impulso: Vector3 = Vector3.ZERO):
	if objeto_seguro == null:
		return

	var objeto = objeto_seguro
	objeto_seguro = null

	# Preservar a posição mundial do objeto
	objeto.reparent(get_tree().current_scene, true)

	# Capturar a velocidade real do jogador
	var velocidade_jogador = get_real_velocity()

	# Reativar a física
	objeto.freeze = false
	objeto.sleeping = false

	# Aplicar a velocidade herdada
	objeto.linear_velocity = (
		velocidade_jogador * DROP_VELOCITY_MULTIPLIER
	)

	objeto.angular_velocity = Vector3.ZERO

	# Aplicar impulso somente quando arremessado
	if impulso.length_squared() > 0:
		objeto.apply_central_impulse(impulso)
