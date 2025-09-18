extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary[String, State]

func _ready() -> void:
	for child in get_children():
		if child is State:
			var state = child
			var state_name: String = state.name.to_lower()
			states[state_name] = state
			state.transitioned.connect(on_child_transitioned)

	if not initial_state:
		assert(false, "No intial state for state machine " + str(self) + " set. Was " + str(initial_state))

	initial_state._enter()
	current_state = initial_state

func  _process(delta: float) -> void:
	if current_state:
		current_state._update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state._physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state._on_input(event)

func on_child_transitioned(old_state, new_state_name):
	if old_state != current_state:
		return

	var new_state = states[new_state_name.to_lower()]

	if not new_state:
		return

	if current_state:
		current_state._exit()

	new_state._enter()
	current_state = new_state
	print_debug("Transitioned from state " + str(old_state.name) + " to state " + new_state_name)
