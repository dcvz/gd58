extends Node

## Manages owned research machines and active jobs

signal machine_purchased(machine_type: MachineData.MachineType)
signal machines_changed()
signal job_started(job: MachineJob)
signal job_completed(job: MachineJob)

var owned_machines: Array[MachineData.MachineType] = []
var active_jobs: Array[MachineJob] = []

# For MULTI_PROPERTY machines: store which stats each can detect
# machine_type -> Array of stat keys (SoulAttribute enum values)
var multi_property_stats: Dictionary = {}

# Physical machine instances in the world
var machine_units: Dictionary = {}  # machine_type -> Node3D instance
var machine_scene: PackedScene = preload("res://scenes/machine_unit.tscn")
var objects_node: Node

# Machine placement positions (left and right side of back room)
var placement_positions: Array[Vector3] = [
	Vector3(7.5, 0, -5),   # Left wall
	Vector3(9, 0, -5),
	Vector3(10.5, 0, -5),
	Vector3(7.5, 0, 5),    # Right wall
	Vector3(9, 0, 5),
	Vector3(10.5, 0, 5),
]
var next_placement_index: int = 0

func _ready() -> void:
	await get_tree().process_frame
	objects_node = get_node("/root/Root/World/WorldGeometry/Objects")

func _process(delta: float) -> void:
	# Only process jobs when simulation is running
	var game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	if game_loop_manager and game_loop_manager.is_simulation_paused:
		return

	# Update elapsed time for all active jobs
	for job in active_jobs:
		if not job.completed:
			job.update_elapsed(delta)

	_check_completed_jobs()

## Check if a machine is owned
func has_machine(type: MachineData.MachineType) -> bool:
	return owned_machines.has(type)

## Grant a machine for free (for starter machine or rewards)
func grant_machine(type: MachineData.MachineType) -> bool:
	if has_machine(type):
		print("Machine already owned!")
		return false

	owned_machines.append(type)

	# For MULTI_PROPERTY, randomly select 6 stats this machine can detect
	if type == MachineData.MachineType.MULTI_PROPERTY:
		var all_stats = SoulData.SoulAttribute.values()
		all_stats.shuffle()
		var selected_stats = all_stats.slice(0, 6)
		multi_property_stats[type] = selected_stats
		var stat_names = []
		for stat in selected_stats:
			stat_names.append(SoulData.SoulAttribute.keys()[stat])
		print("Multi-Property Scanner can detect: %s" % ", ".join(stat_names))

	# Spawn physical machine in the world
	_spawn_machine(type)

	machine_purchased.emit(type)
	machines_changed.emit()
	print("Granted %s" % MachineData.get_machine_name(type))
	return true

## Purchase a machine
func purchase_machine(type: MachineData.MachineType) -> bool:
	if has_machine(type):
		print("Machine already owned!")
		return false

	var cost = MachineData.get_machine_cost(type)
	var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")

	if not currency_manager.can_afford(cost):
		print("Cannot afford machine! Need %d KP" % cost)
		return false

	if currency_manager.spend_kp(cost):
		owned_machines.append(type)

		# For MULTI_PROPERTY, randomly select 6 stats this machine can detect
		if type == MachineData.MachineType.MULTI_PROPERTY:
			var all_stats = SoulData.SoulAttribute.values()
			all_stats.shuffle()
			var selected_stats = all_stats.slice(0, 6)  # Take first 6 after shuffle
			multi_property_stats[type] = selected_stats
			var stat_names = []
			for stat in selected_stats:
				stat_names.append(SoulData.SoulAttribute.keys()[stat])
			print("Multi-Property Scanner can detect: %s" % ", ".join(stat_names))

		# Spawn physical machine in the world
		_spawn_machine(type)

		machine_purchased.emit(type)
		machines_changed.emit()
		print("Purchased %s for %d KP" % [MachineData.get_machine_name(type), cost])
		return true

	return false

## Get all owned machines
func get_owned_machines() -> Array[MachineData.MachineType]:
	return owned_machines.duplicate()

## Get all available machines to purchase
func get_available_machines() -> Array[MachineData.MachineType]:
	var available: Array[MachineData.MachineType] = []
	for type in MachineData.MachineType.values():
		if not has_machine(type):
			available.append(type)
	return available

## Get which stats a MULTI_PROPERTY machine can detect
## Returns array of stat keys, or empty array if not applicable
func get_multi_property_stats(machine_type: MachineData.MachineType) -> Array:
	if machine_type == MachineData.MachineType.MULTI_PROPERTY:
		return multi_property_stats.get(machine_type, [])
	return []

## Start a machine job on a soul
func start_job(soul_id: String, soul: SoulData, machine_type: MachineData.MachineType) -> bool:
	if not has_machine(machine_type):
		print("Machine not owned!")
		return false

	# Check if soul already has a job running
	if is_soul_being_analyzed(soul_id):
		print("Soul is already being analyzed!")
		return false

	var duration = MachineData.get_machine_duration(machine_type)
	var job = MachineJob.new(soul_id, machine_type, Time.get_ticks_msec() / 1000.0, duration)
	active_jobs.append(job)
	job_started.emit(job)
	print("Started %s on soul %s (duration: %ds)" % [MachineData.get_machine_name(machine_type), soul_id, duration])
	return true

## Check if a soul is being analyzed
func is_soul_being_analyzed(soul_id: String) -> bool:
	for job in active_jobs:
		if job.soul_id == soul_id and not job.completed:
			return true
	return false

## Check if a specific machine is currently in use
func is_machine_in_use(machine_type: MachineData.MachineType) -> bool:
	for job in active_jobs:
		if job.machine_type == machine_type and not job.completed:
			return true
	return false

## Get active job for a soul (if any)
func get_soul_job(soul_id: String) -> MachineJob:
	for job in active_jobs:
		if job.soul_id == soul_id and not job.completed:
			return job
	return null

## Get all active jobs
func get_active_jobs() -> Array[MachineJob]:
	return active_jobs.filter(func(job): return not job.completed)

## Check for completed jobs and process them
func _check_completed_jobs() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0

	for job in active_jobs:
		if not job.completed and job.is_complete(current_time):
			job.completed = true
			_process_completed_job(job)
			job_completed.emit(job)

## Process a completed job and apply discoveries
func _process_completed_job(job: MachineJob) -> void:
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var soul = inventory_manager.get_soul_by_id(job.soul_id)

	if not soul:
		print("Soul not found for completed job!")
		return

	# Apply machine-specific discovery logic
	match job.machine_type:
		MachineData.MachineType.BASIC_ANALYZER:
			_discover_random_property(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.RANDOM_PROPERTY:
			_discover_random_property(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.SPECIFIC_RANGE_WIDE:
			_discover_random_stat_wide_range(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.RANDOM_RANGE_NARROW:
			_discover_random_stat_narrow_range(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.MULTI_PROPERTY:
			_discover_multiple_properties(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.ELIMINATE_OPTIONS:
			_eliminate_era_or_death_options(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.REVEAL_INFO:
			_reveal_era_or_death(job.soul_id, soul, discovery_manager)

## Machine 1: Discover 1 random undiscovered property (name only, not value)
func _discover_random_property(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not disc_log.knows_stat(stat_key) and not disc_log.has_stat_hints(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		var stat_key = undiscovered_stats.pick_random()
		# Add hint showing only that this stat exists (value unknown)
		discovery_manager.add_stat_hint(soul_id, stat_key, "Present")

## Machine 2: Discover random property with wide range (15-40 points)
func _discover_random_stat_wide_range(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not disc_log.knows_stat(stat_key) and disc_log.has_stat_hints(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		var stat_key = undiscovered_stats.pick_random()
		var actual_value = soul.stats[stat_key]

		# Random range width between 15-40
		var range_width = randi_range(15, 40)

		# Random position within range (0.0 = at min, 1.0 = at max, 0.5 = centered)
		var position_in_range = randf()

		# Calculate offset from actual value
		var offset_below = range_width * position_in_range
		var offset_above = range_width * (1.0 - position_in_range)

		var min_range = max(0, actual_value - offset_below)
		var max_range = min(100, actual_value + offset_above)
		var hint = "%d-%d" % [int(min_range), int(max_range)]
		discovery_manager.add_stat_hint(soul_id, stat_key, hint)

## Machine 3: Discover random property within 20 points (narrow range)
func _discover_random_stat_narrow_range(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not disc_log.knows_stat(stat_key) and disc_log.has_stat_hints(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		var stat_key = undiscovered_stats.pick_random()
		var actual_value = soul.stats[stat_key]

		# Fixed range width of 20 points
		var range_width = 20

		# Random position within range (0.0 = at min, 1.0 = at max, 0.5 = centered)
		var position_in_range = randf()

		# Calculate offset from actual value
		var offset_below = range_width * position_in_range
		var offset_above = range_width * (1.0 - position_in_range)

		var min_range = max(0, actual_value - offset_below)
		var max_range = min(100, actual_value + offset_above)
		var hint = "%d-%d" % [int(min_range), int(max_range)]
		discovery_manager.add_stat_hint(soul_id, stat_key, hint)

## Machine 4: Discover 6 specific properties (presence only, no values)
## Only detects the 6 stats this machine was configured to detect
func _discover_multiple_properties(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)

	# Get the specific stats this machine can detect
	var detectable_stats = multi_property_stats.get(MachineData.MachineType.MULTI_PROPERTY, [])
	if detectable_stats.size() == 0:
		print("[Machine] Warning: Multi-Property Scanner has no assigned stats!")
		return

	# Check each of the 6 assigned stats
	for stat_key in detectable_stats:
		# Only discover if:
		# 1. The soul actually has this stat
		# 2. We don't already know about it
		if soul.stats.has(stat_key):
			if not disc_log.knows_stat(stat_key) and not disc_log.has_stat_hints(stat_key):
				# Add hint showing only that this stat exists (value unknown)
				discovery_manager.add_stat_hint(soul_id, stat_key, "Present")

## Machine 5: Remove 2 possibilities from Era or Cause of Death
func _eliminate_era_or_death_options(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)

	# Determine what we can still eliminate from
	var can_eliminate_era = not disc_log.known_era
	var can_eliminate_death = not disc_log.known_death

	# If both are already known, nothing to do
	if not can_eliminate_era and not can_eliminate_death:
		print("[Machine] Era and Death already known - nothing to eliminate!")
		return

	# Pick randomly which one to eliminate from (if both available)
	var eliminate_era = false
	if can_eliminate_era and can_eliminate_death:
		eliminate_era = randf() < 0.5
	elif can_eliminate_era:
		eliminate_era = true
	# else: eliminate_era stays false, we'll eliminate death

	if eliminate_era:
		# Eliminate 2 era options
		var all_eras = SoulData.Era.values()
		all_eras.erase(soul.era)  # Don't eliminate the correct one

		# Filter out already eliminated eras
		var already_eliminated = []
		for hint in disc_log.era_hints:
			if hint.begins_with("Not "):
				var era_name = hint.substr(4)
				for era in SoulData.Era.values():
					if SoulData.Era.keys()[era] == era_name:
						already_eliminated.append(era)
						break

		for era in already_eliminated:
			all_eras.erase(era)

		# Eliminate 2 new options
		all_eras.shuffle()
		for i in range(min(2, all_eras.size())):
			var hint = "Not %s" % SoulData.Era.keys()[all_eras[i]]
			discovery_manager.add_era_hint(soul_id, hint)

		# Check if we've eliminated all but one option
		_check_if_era_discovered(soul_id, soul, discovery_manager)
	else:
		# Eliminate 2 death options
		var all_deaths = SoulData.CauseOfDeath.values()
		all_deaths.erase(soul.causeOfDeath)  # Don't eliminate the correct one

		# Filter out already eliminated deaths
		var already_eliminated = []
		for hint in disc_log.death_hints:
			if hint.begins_with("Not "):
				var death_name = hint.substr(4)
				for death in SoulData.CauseOfDeath.values():
					if SoulData.CauseOfDeath.keys()[death] == death_name:
						already_eliminated.append(death)
						break

		for death in already_eliminated:
			all_deaths.erase(death)

		# Eliminate 2 new options
		all_deaths.shuffle()
		for i in range(min(2, all_deaths.size())):
			var hint = "Not %s" % SoulData.CauseOfDeath.keys()[all_deaths[i]]
			discovery_manager.add_death_hint(soul_id, hint)

		# Check if we've eliminated all but one option
		_check_if_death_discovered(soul_id, soul, discovery_manager)

## Machine 6: Discover Era or Cause of Death
func _reveal_era_or_death(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)

	if randf() < 0.5 and not disc_log.known_era:
		discovery_manager.discover_era(soul_id)
	elif not disc_log.known_death:
		discovery_manager.discover_death(soul_id)
	elif not disc_log.known_era:
		discovery_manager.discover_era(soul_id)
	else:
		discovery_manager.discover_death(soul_id)


## Check if we've eliminated enough era options to know the answer
func _check_if_era_discovered(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	if disc_log.known_era:
		return

	# Count how many eras we've eliminated
	var eliminated = []
	for hint in disc_log.era_hints:
		if hint.begins_with("Not "):
			var era_name = hint.substr(4)  # Remove "Not "
			for era in SoulData.Era.values():
				if SoulData.Era.keys()[era] == era_name:
					eliminated.append(era)
					break

	# If we've eliminated all but one, we know the answer
	var total_eras = SoulData.Era.size()
	if eliminated.size() >= total_eras - 1:
		discovery_manager.discover_era(soul_id)
		print("[Machine] Era discovered by elimination!")

## Check if we've eliminated enough death options to know the answer
func _check_if_death_discovered(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	if disc_log.known_death:
		return

	# Count how many deaths we've eliminated
	var eliminated = []
	for hint in disc_log.death_hints:
		if hint.begins_with("Not "):
			var death_name = hint.substr(4)  # Remove "Not "
			for death in SoulData.CauseOfDeath.values():
				if SoulData.CauseOfDeath.keys()[death] == death_name:
					eliminated.append(death)
					break

	# If we've eliminated all but one, we know the answer
	var total_deaths = SoulData.CauseOfDeath.size()
	if eliminated.size() >= total_deaths - 1:
		discovery_manager.discover_death(soul_id)
		print("[Machine] Cause of Death discovered by elimination!")

## Spawn a physical machine in the world
func _spawn_machine(machine_type: MachineData.MachineType) -> void:
	if next_placement_index >= placement_positions.size():
		print("[MachineManager] No more placement positions available!")
		return

	var machine_instance = machine_scene.instantiate()
	machine_instance.position = placement_positions[next_placement_index]

	# Rotate to face the correct direction based on which wall
	# Left wall (Z: -5) should face south (into room), right wall (Z: 5) should face north
	if placement_positions[next_placement_index].z < 0:
		machine_instance.rotation_degrees = Vector3(0, 180, 0)  # Face south (into room)
	else:
		machine_instance.rotation_degrees = Vector3(0, 0, 0)    # Face north (into room)

	machine_instance.set_machine_type(machine_type)

	objects_node.add_child(machine_instance)
	machine_units[machine_type] = machine_instance

	next_placement_index += 1
	print("[MachineManager] Spawned %s at position %s" % [MachineData.get_machine_name(machine_type), placement_positions[next_placement_index - 1]])

	# Connect job signals to update visual state
	if not job_started.is_connected(_on_job_started):
		job_started.connect(_on_job_started)
	if not job_completed.is_connected(_on_job_completed):
		job_completed.connect(_on_job_completed)

## Update machine visual when job starts
func _on_job_started(job: MachineJob) -> void:
	if machine_units.has(job.machine_type):
		# Get the soul's color
		var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
		var soul = inventory_manager.get_soul(job.soul_id)
		var soul_color = soul.visual_color if soul else Color.WHITE

		machine_units[job.machine_type].set_in_use(true, soul_color)

## Update machine visual when job completes
func _on_job_completed(job: MachineJob) -> void:
	if machine_units.has(job.machine_type):
		machine_units[job.machine_type].set_in_use(false)
