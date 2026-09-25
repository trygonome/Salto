extends GutTest
## Machine à états générique : démarrage, transitions, ordre des appels.


class RecordingState:
	extends State
	var calls: Array[String]

	func _init(state_name: StringName, log: Array[String]) -> void:
		name = state_name
		calls = log

	func enter(previous: StringName) -> void:
		calls.append("%s.enter(%s)" % [name, previous])

	func exit() -> void:
		calls.append("%s.exit" % name)

	func physics_update(_delta: float) -> void:
		calls.append("%s.update" % name)


var machine: StateMachine
var calls: Array[String] = []


func before_each() -> void:
	calls = []
	machine = StateMachine.new()
	var idle := RecordingState.new(&"Idle", calls)
	machine.add_child(idle)
	machine.add_child(RecordingState.new(&"Run", calls))
	machine.initial_state = idle
	add_child_autofree(machine)
	machine.start()


func test_demarre_dans_l_etat_initial() -> void:
	assert_eq(machine.current.name, &"Idle")
	assert_eq(calls, ["Idle.enter()"] as Array[String])


func test_met_a_jour_l_etat_actif() -> void:
	machine.physics_update(0.1)
	assert_eq(calls.back(), "Idle.update")


func test_transition_quitte_puis_entre() -> void:
	machine.transition_to(&"Run")
	assert_eq(machine.current.name, &"Run")
	assert_eq(calls.slice(1), ["Idle.exit", "Run.enter(Idle)"] as Array[String])


func test_transition_signalee() -> void:
	watch_signals(machine)
	machine.transition_to(&"Run")
	assert_signal_emitted_with_parameters(machine, "state_changed", [&"Idle", &"Run"])


func test_rentrer_dans_le_meme_etat_le_relance() -> void:
	machine.transition_to(&"Idle")
	assert_eq(calls.slice(1), ["Idle.exit", "Idle.enter(Idle)"] as Array[String])
