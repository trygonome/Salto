extends State
## Plongeon (Frappe en l'air) : chute droite et rapide ; à l'atterrissage, une onde frappe tout
## autour, d'autant plus large et forte que la chute était haute. Court temps de reprise au sol,
## que le saut et l'esquive peuvent interrompre.
## Jauge de groove pleine : Salto arc-en-ciel. Bond et salto d'abord, puis plongeon géant dont
## l'onde touche loin, fort, étourdit ; invulnérable du début à la fin. La jauge est consommée.

var _rainbow: bool = false
var _rising: bool = false
var _landed: bool = false
var _start_height: float = 0.0
var _recovery_left: float = 0.0
var _judgement: RhythmMath.Judgement = RhythmMath.Judgement.MISS

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	var tuning: TuningData = hero.tuning
	_judgement = hero.take_judgement(&"attack")
	_rainbow = hero.groove.is_full()
	_landed = false
	hero.visual.trail.emitting = true
	hero.visual.trail.rainbow = _rainbow
	if _rainbow:
		hero.groove.empty()
		hero.invulnerable = true
		hero.velocity = Vector3.UP * tuning.rainbow_hop_speed
		hero.visual.play_salto(tuning.salto_duration)
		hero.visual.animator.show_air()
		_rising = true
	else:
		_start_fall()


func exit() -> void:
	hero.invulnerable = false
	hero.visual.set_pitch_deg(0.0)
	hero.visual.trail.emitting = false
	hero.visual.trail.rainbow = false
	hero.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if _rising:
		hero.set_horizontal_velocity(Vector3.ZERO)
		hero.velocity.y -= HeroMotion.gravity(hero.velocity.y, true, tuning) * delta
		hero.move(delta)
		if hero.velocity.y <= 0.0:
			_start_fall()
		return
	if not _landed:
		hero.velocity = Vector3.DOWN * tuning.dive_fall_speed
		hero.move(delta)
		if hero.is_on_floor():
			_land()
		return
	if hero.roll_cooldown_left <= 0.0 and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	if hero.consume_press(&"jump"):
		hero.jump(tuning.jump_speed)
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	hero.set_horizontal_velocity(Vector3.ZERO)
	hero.apply_gravity(delta)
	hero.move(delta)
	_recovery_left -= delta
	if _recovery_left <= 0.0:
		machine.transition_to(&"Ground")


func _start_fall() -> void:
	var tuning: TuningData = hero.tuning
	_rising = false
	_start_height = hero.global_position.y
	hero.velocity = Vector3.DOWN * tuning.dive_fall_speed
	hero.visual.stop_spin()
	hero.visual.animator.show_pose(tuning.dive_animation, tuning.dive_pose_time)
	hero.visual.set_pitch_deg(tuning.dive_pitch_deg)


func _land() -> void:
	var tuning: TuningData = hero.tuning
	_landed = true
	_recovery_left = tuning.dive_recovery
	hero.visual.set_pitch_deg(0.0)
	hero.visual.trail.emitting = false
	hero.visual.animator.show_ground(0.0)
	var fall: float = _start_height - hero.global_position.y
	var radius: float = CombatMath.dive_radius(fall, tuning)
	if _rainbow:
		var rainbow_colors: Array[Color] = hero.visual.trail.rainbow_colors
		hero.shockwave(maxf(radius, tuning.rainbow_radius), tuning.rainbow_multiplier, &"rainbow", _judgement, tuning.rainbow_stun, rainbow_colors)
	else:
		var colors: Array[Color] = [hero.visual.trail.color]
		hero.shockwave(radius, CombatMath.dive_multiplier(fall, tuning), &"dive", _judgement, 0.0, colors)
