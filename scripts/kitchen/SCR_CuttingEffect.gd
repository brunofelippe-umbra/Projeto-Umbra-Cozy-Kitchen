
extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D


func _ready() -> void:
	particles.emitting = false


func play_effect() -> void:
	particles.restart()
	particles.emitting = true

	var duration: float = particles.lifetime + 0.5

	await get_tree().create_timer(duration).timeout

	queue_free()
