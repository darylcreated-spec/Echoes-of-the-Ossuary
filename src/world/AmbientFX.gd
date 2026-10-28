extends Node
class_name AmbientFX

# --- AMBIENT EFFECT SPAWNER UTILITY ---

static func create_chimney_smoke(parent: Node3D, pos: Vector3) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "ChimneySmoke"
	particles.amount = 18
	particles.lifetime = 3.2
	particles.explosiveness = 0.05
	particles.randomness = 0.25
	particles.position = pos
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0.2, 1.0, 0.1).normalized()
	p_mat.spread = 15.0
	p_mat.initial_velocity_min = 1.2
	p_mat.initial_velocity_max = 2.0
	p_mat.gravity = Vector3(0.15, 0.4, 0.08)
	p_mat.scale_min = 0.4
	p_mat.scale_max = 1.2
	p_mat.color = Color(0.85, 0.88, 0.92, 0.45)
	particles.process_material = p_mat
	
	var quad = SphereMesh.new()
	quad.radius = 0.25
	quad.height = 0.5
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.88, 0.92, 0.35)
	mat.roughness = 0.9
	quad.material = mat
	particles.draw_pass_1 = quad
	
	parent.add_child(particles)
	return particles

static func create_forge_sparks(parent: Node3D, pos: Vector3) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "ForgeSparks"
	particles.amount = 14
	particles.lifetime = 0.45
	particles.explosiveness = 0.85
	particles.randomness = 0.4
	particles.position = pos
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 75.0
	p_mat.initial_velocity_min = 3.5
	p_mat.initial_velocity_max = 6.0
	p_mat.gravity = Vector3(0, -9.8, 0)
	p_mat.scale_min = 0.06
	p_mat.scale_max = 0.12
	p_mat.color = Color(2.5, 1.4, 0.2, 1.0) # Radiant HDR orange
	particles.process_material = p_mat
	
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.7, 0.2)
	box.material = mat
	particles.draw_pass_1 = box
	
	parent.add_child(particles)
	return particles

static func create_forest_fireflies(parent: Node3D, pos: Vector3, radius: float = 8.0) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "Fireflies"
	particles.amount = 25
	particles.lifetime = 4.0
	particles.position = pos
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = radius
	p_mat.direction = Vector3(0, 0, 0)
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 0.3
	p_mat.initial_velocity_max = 0.8
	p_mat.gravity = Vector3(0, 0.08, 0)
	p_mat.scale_min = 0.1
	p_mat.scale_max = 0.22
	p_mat.color = Color(0.4, 2.2, 0.8, 0.9) # Glowing emerald/cyan
	particles.process_material = p_mat
	
	var quad = SphereMesh.new()
	quad.radius = 0.08
	quad.height = 0.16
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 1.0, 0.6)
	quad.material = mat
	particles.draw_pass_1 = quad
	
	parent.add_child(particles)
	return particles

static func create_sacred_aura(parent: Node3D, pos: Vector3) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "SacredAura"
	particles.amount = 16
	particles.lifetime = 2.8
	particles.position = pos
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	p_mat.emission_ring_radius = 1.6
	p_mat.emission_ring_inner_radius = 0.4
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 10.0
	p_mat.initial_velocity_min = 0.6
	p_mat.initial_velocity_max = 1.4
	p_mat.gravity = Vector3(0, 0.2, 0)
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.2
	p_mat.color = Color(1.0, 0.88, 0.4, 0.8) # Holy golden shimmer
	particles.process_material = p_mat
	
	var quad = SphereMesh.new()
	quad.radius = 0.07
	quad.height = 0.14
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	quad.material = mat
	particles.draw_pass_1 = quad
	
	parent.add_child(particles)
	return particles
